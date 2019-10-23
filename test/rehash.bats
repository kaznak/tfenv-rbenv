#!/usr/bin/env bats

load test_helper

create_executable() {
  local bin="${TFENV_ROOT}/versions/${1}/bin"
  mkdir -p "$bin"
  touch "${bin}/$2"
  chmod +x "${bin}/$2"
}

@test "empty rehash" {
  assert [ ! -d "${TFENV_ROOT}/shims" ]
  run tfenv-rehash
  assert_success ""
  assert [ -d "${TFENV_ROOT}/shims" ]
  rmdir "${TFENV_ROOT}/shims"
}

@test "non-writable shims directory" {
  mkdir -p "${TFENV_ROOT}/shims"
  chmod -w "${TFENV_ROOT}/shims"
  run tfenv-rehash
  assert_failure "tfenv: cannot rehash: ${TFENV_ROOT}/shims isn't writable"
}

@test "rehash in progress" {
  mkdir -p "${TFENV_ROOT}/shims"
  touch "${TFENV_ROOT}/shims/.tfenv-shim"
  run tfenv-rehash
  assert_failure "tfenv: cannot rehash: ${TFENV_ROOT}/shims/.tfenv-shim exists"
}

@test "creates shims" {
  create_executable "1.8" "terraform"
  create_executable "1.8" "rake"
  create_executable "2.0" "terraform"
  create_executable "2.0" "rspec"

  assert [ ! -e "${TFENV_ROOT}/shims/terraform" ]
  assert [ ! -e "${TFENV_ROOT}/shims/rake" ]
  assert [ ! -e "${TFENV_ROOT}/shims/rspec" ]

  run tfenv-rehash
  assert_success ""

  run ls "${TFENV_ROOT}/shims"
  assert_success
  assert_output <<OUT
rake
rspec
terraform
OUT
}

@test "removes outdated shims" {
  mkdir -p "${TFENV_ROOT}/shims"
  touch "${TFENV_ROOT}/shims/oldshim1"
  chmod +x "${TFENV_ROOT}/shims/oldshim1"

  create_executable "2.0" "rake"
  create_executable "2.0" "terraform"

  run tfenv-rehash
  assert_success ""

  assert [ ! -e "${TFENV_ROOT}/shims/oldshim1" ]
}

@test "do exact matches when removing stale shims" {
  create_executable "2.0" "unicorn_rails"
  create_executable "2.0" "rspec-core"

  tfenv-rehash

  cp "$TFENV_ROOT"/shims/{rspec-core,rspec}
  cp "$TFENV_ROOT"/shims/{rspec-core,rails}
  cp "$TFENV_ROOT"/shims/{rspec-core,uni}
  chmod +x "$TFENV_ROOT"/shims/{rspec,rails,uni}

  run tfenv-rehash
  assert_success ""

  assert [ ! -e "${TFENV_ROOT}/shims/rails" ]
  assert [ ! -e "${TFENV_ROOT}/shims/rake" ]
  assert [ ! -e "${TFENV_ROOT}/shims/uni" ]
}

@test "binary install locations containing spaces" {
  create_executable "dirname1 p247" "terraform"
  create_executable "dirname2 preview1" "rspec"

  assert [ ! -e "${TFENV_ROOT}/shims/terraform" ]
  assert [ ! -e "${TFENV_ROOT}/shims/rspec" ]

  run tfenv-rehash
  assert_success ""

  run ls "${TFENV_ROOT}/shims"
  assert_success
  assert_output <<OUT
rspec
terraform
OUT
}

@test "carries original IFS within hooks" {
  create_hook rehash hello.bash <<SH
hellos=(\$(printf "hello\\tugly world\\nagain"))
echo HELLO="\$(printf ":%s" "\${hellos[@]}")"
exit
SH

  IFS=$' \t\n' run tfenv-rehash
  assert_success
  assert_output "HELLO=:hello:ugly:world:again"
}

@test "sh-rehash in bash" {
  create_executable "2.0" "terraform"
  TFENV_SHELL=bash run tfenv-sh-rehash
  assert_success "hash -r 2>/dev/null || true"
  assert [ -x "${TFENV_ROOT}/shims/terraform" ]
}

@test "sh-rehash in fish" {
  create_executable "2.0" "terraform"
  TFENV_SHELL=fish run tfenv-sh-rehash
  assert_success ""
  assert [ -x "${TFENV_ROOT}/shims/terraform" ]
}

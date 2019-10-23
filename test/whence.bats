#!/usr/bin/env bats

load test_helper

create_executable() {
  local bin="${TFENV_ROOT}/versions/${1}/bin"
  mkdir -p "$bin"
  touch "${bin}/$2"
  chmod +x "${bin}/$2"
}

@test "finds versions where present" {
  create_executable "1.8" "terraform"
  create_executable "2.0" "terraform"

  run tfenv-whence terraform
  assert_success
  assert_output <<OUT
1.8
2.0
OUT
}

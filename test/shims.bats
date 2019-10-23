#!/usr/bin/env bats

load test_helper

@test "no shims" {
  run tfenv-shims
  assert_success
  assert [ -z "$output" ]
}

@test "shims" {
  mkdir -p "${TFENV_ROOT}/shims"
  touch "${TFENV_ROOT}/shims/terraform"
  run tfenv-shims
  assert_success
  assert_line "${TFENV_ROOT}/shims/terraform"
}

@test "shims --short" {
  mkdir -p "${TFENV_ROOT}/shims"
  touch "${TFENV_ROOT}/shims/terraform"
  run tfenv-shims --short
  assert_success
  assert_line "terraform"
}

#!/usr/bin/env bash

make_dependency_path() {
  local destination="$1" command_name command_path
  shift
  mkdir -p "$destination"
  for command_name in "$@"; do
    command_path="$(command -v "$command_name")" || return 1
    ln -s "$command_path" "$destination/$command_name"
  done
}

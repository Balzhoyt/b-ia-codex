#!/usr/bin/env bash

make_dependency_path() {
  local destination="$1" command_name command_path
  mkdir -p "$destination"
  for command_name in bash env dirname realpath git codex gentle-ai engram jq mktemp find sed sort awk uniq comm tr date sleep seq mkdir cp cmp cat head tail rm sha256sum cut grep wc tac rmdir chmod basename sync tee ln mkfifo perl stat id mv; do
    command_path="$(command -v "$command_name")" || return 1
    ln -s "$command_path" "$destination/$command_name"
  done
}

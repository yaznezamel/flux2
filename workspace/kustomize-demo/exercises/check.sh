#!/usr/bin/env bash
# Check an exercise: build it and compare with its expected.yaml.
#
#   ./check.sh 01              check exercise 01
#   ./check.sh all             check every exercise
#   ./check.sh --solution 03   show what the reference solution renders to
set -euo pipefail
cd "$(dirname "$0")"

usage() {
  echo "usage: $0 [--solution] <01|02|03|04|05|all>" >&2
  exit 2
}

build() {
  local dir=$1
  local flags=()
  [[ -d "$dir/charts" ]] && flags+=(--enable-helm)
  kustomize build "${flags[@]}" "$dir"
}

check() {
  local ex=$1 out
  if out=$(build "$ex" 2>&1) && diff -u "$ex/expected.yaml" - <<<"$out" >/dev/null; then
    echo "PASS  $ex"
    return 0
  fi
  echo "FAIL  $ex"
  if ! build "$ex" >/dev/null 2>&1; then
    echo "      kustomize build failed:"
    sed 's/^/      /' <<<"$out"
  else
    echo "      diff (- expected, + yours):"
    diff -u "$ex/expected.yaml" - <<<"$out" | tail -n +3 | sed 's/^/      /' || true
  fi
  return 1
}

solution() {
  local ex=$1 tmp
  tmp=$(mktemp -d)
  trap 'rm -rf "$tmp"' RETURN
  cp -r "$ex/." "$tmp/"
  cp -r "solutions/$ex/." "$tmp/"
  echo "# solutions/$ex/kustomization.yaml" >&2
  cat "solutions/$ex/kustomization.yaml" >&2
  echo "# ---- renders to ----" >&2
  build "$tmp"
}

resolve() {
  local match=( "$1"-*/ )
  [[ -d "${match[0]}" ]] || { echo "no exercise $1" >&2; exit 2; }
  basename "${match[0]}"
}

[[ $# -ge 1 ]] || usage
if [[ $1 == --solution ]]; then
  [[ $# -eq 2 ]] || usage
  solution "$(resolve "$2")"
  exit 0
fi

if [[ $1 == all ]]; then
  failed=0
  for ex in [0-9][0-9]-*/; do
    check "${ex%/}" || failed=1
  done
  exit $failed
fi

check "$(resolve "$1")"

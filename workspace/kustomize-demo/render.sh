#!/usr/bin/env bash
# Render the base and each overlay into ./rendered and show what each
# overlay changes compared to the base.
set -euo pipefail
cd "$(dirname "$0")"

rm -rf rendered && mkdir rendered
for dir in base overlays/dev overlays/prod; do
  out="rendered/$(basename "$dir").yaml"
  kustomize build "$dir" > "$out"
  echo "rendered $dir -> $out"
done

for env in dev prod; do
  echo
  echo "===== base vs $env ====="
  diff -u rendered/base.yaml "rendered/$env.yaml" || true
done

# Simulate Flux postBuild substitution if the flux CLI is available.
if command -v flux >/dev/null 2>&1; then
  cluster_name=prod-eu-1 flux envsubst < rendered/prod.yaml > rendered/prod-flux.yaml
  echo
  echo "===== prod after Flux substitution (cluster_name=prod-eu-1) ====="
  diff -u rendered/prod.yaml rendered/prod-flux.yaml || true
fi

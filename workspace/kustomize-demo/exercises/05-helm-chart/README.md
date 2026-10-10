# 05 - Helm charts inside Kustomize

This is where "values" (Helm) and "patches" (Kustomize) meet. Kustomize
can call `helm template` for you and then treat the rendered YAML like any
other resource:

```yaml
helmCharts:
  - name: hello            # chart name (a folder under helmGlobals.chartHome)
    releaseName: web       # becomes .Release.Name in the templates
    valuesInline:          # same as a values.yaml / --set
      replicaCount: 2
helmGlobals:
  chartHome: charts        # where local charts live (default: ./charts)
```

Charts from a repository work too (`repo: https://...` and `version:`).
Building needs the flag `--enable-helm` and the `helm` binary on PATH.

## Goal

Make `kustomize build --enable-helm .` match `expected.yaml`:

1. Render `charts/hello` with release name `web`.
2. **Values:** set `replicaCount: 2`, `image.tag: "1.27"` and
   `message: hello from kustomize`.
3. **Patch:** the chart has no option for resource limits. Add
   `resources.limits.memory: 128Mi` to the `hello` container with a
   strategic-merge patch, as if it were your own YAML.

Read `charts/hello/templates/deployment.yaml` and `values.yaml` first.

Check: `./check.sh 05`

## Takeaway

Use values for whatever the chart author exposed; use patches for
everything they did not. In Flux, a `HelmRelease` has the same split:
`spec.values` for values and `spec.postRenderers` with kustomize patches
for the rest.

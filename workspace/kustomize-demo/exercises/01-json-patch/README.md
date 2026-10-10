# 01 - JSON patches

Strategic-merge patches (what the demo's prod overlay uses) *merge* YAML.
They are good at adding and changing fields, but awkward at removing
things or touching one item of a list. JSON patches (RFC 6902) are a list
of precise operations on paths instead:

```yaml
patches:
  - target:
      kind: Deployment
      name: api
    patch: |-
      - op: replace            # add | remove | replace | copy | move | test
        path: /spec/replicas   # slash-separated path; list items by index
        value: 2
```

## Goal

Make `kustomize build .` match `expected.yaml`. Using **one** JSON patch:

1. Set `replicas` to 2.
2. Add a second arg `--log-format=json` to the `api` container
   (hint: `/-` at the end of a list path means "append").
3. Remove the `debug-shell` container (it is index 1 in the list).
4. Remove the `debug.example.com/enabled` annotation. A `/` inside a key
   is written as `~1` in a JSON patch path.

Check your answer from the `exercises/` folder: `./check.sh 01`

## Takeaway

List items are addressed by index, so JSON patches are fragile if the
list order changes upstream. Prefer strategic merge when it can do the
job; reach for JSON patches for removals and exact edits.

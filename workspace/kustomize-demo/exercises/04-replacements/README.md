# 04 - replacements

Kustomize rewrites references it *knows about* (a Deployment's
`configMapRef`, a Service's selector, ...). It does not know that an env
var holding `api` is secretly a Service name, so `namePrefix: staging-`
renames the Service to `staging-api` but leaves the env var pointing at
the old, wrong name.

`replacements` copy a value from one field of one object into fields of
other objects:

```yaml
replacements:
  - source:
      kind: Service
      name: api                  # the name BEFORE the prefix
      fieldPath: metadata.name   # the value to copy
    targets:
      - select:
          kind: Deployment
          name: frontend
        fieldPaths:
          - spec.template.spec.containers.[name=frontend].env.[name=API_HOST].value
```

`[name=frontend]` selects the list item whose `name` is `frontend`, so
you do not depend on list order (compare with exercise 01).

## Goal

Make `kustomize build .` match `expected.yaml`: `API_HOST` must equal
`staging-api`. Build first without the replacement to see the bug.

Check: `./check.sh 04`

## Then try

Change `namePrefix` to `prod-` and rebuild: `API_HOST` follows along.

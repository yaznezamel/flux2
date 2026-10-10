# 03 - Components

Overlays stack in a line: `prod` builds on `base`. That breaks down when
features are independent: "monitoring" in staging and prod, "debug" only
in staging, maybe "ingress" in prod only. Copying patches between
overlays is how drift starts.

A **Component** (`kind: Component`) is a reusable bundle of patches,
generators and resources. An overlay switches it on with:

```yaml
components:
  - path/to/component
```

```
03-components/
├── base/                     the app
├── components/
│   ├── monitoring/           adds Prometheus scrape annotations
│   └── debug/                adds a debug ConfigMap and wires it in
└── kustomization.yaml        the staging overlay  <- you edit this
```

## Goal

Make `kustomize build .` match `expected.yaml`: staging should have
**both** monitoring and debug enabled. Read the two component files first
and predict the output before you build it.

Check: `./check.sh 03`

## Then try

- Remove `debug` from the list: the ConfigMap and the `envFrom` vanish.
- Notice the components use `namespace: staging` from the overlay even
  though they never mention it: they run inside the overlay's build.

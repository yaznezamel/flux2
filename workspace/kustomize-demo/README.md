# kustomize-demo

A tiny repo for learning how Kustomize renders YAML, and how Flux uses it.

## Key idea

Kustomize has **no templates and no values file**. You write plain, valid
Kubernetes YAML (the *base*), then describe *changes* to it in an *overlay*.
`kustomize build <dir>` reads `<dir>/kustomization.yaml`, loads the
resources, applies the transformations, and prints the final YAML to stdout.
Nothing is sent to a cluster.

```
kustomize-demo/
├── base/                       # shared, environment-neutral manifests
│   ├── kustomization.yaml      # lists resources + labels + configMapGenerator
│   ├── deployment.yaml
│   └── service.yaml
├── overlays/
│   ├── dev/kustomization.yaml  # namespace, name prefix, config override
│   └── prod/
│       ├── kustomization.yaml  # + image tag, replicas, a patch
│       └── deployment-resources.yaml   # strategic-merge patch
├── flux/kustomization-prod.yaml        # how Flux would deploy overlays/prod
└── render.sh                   # render everything and diff it
```

## Tools installed

| Tool        | Used for                                                   |
|-------------|------------------------------------------------------------|
| `kustomize` | `kustomize build <dir>` renders a kustomization            |
| `kubectl`   | `kubectl kustomize <dir>` is the same renderer, built in   |
| `yq`        | pick fields out of rendered YAML                           |
| `flux`      | `flux envsubst` reproduces Flux's `${var}` substitution    |

## Try it

```sh
cd workspace/kustomize-demo

kustomize build base             # the base on its own
kustomize build overlays/dev     # base + dev changes
kustomize build overlays/prod    # base + prod changes
kubectl kustomize overlays/prod  # same output, using kubectl

./render.sh                      # writes rendered/*.yaml and shows diffs
```

Ask a question of the output with `yq`:

```sh
kustomize build overlays/prod | yq 'select(.kind == "Deployment") | .spec.replicas'
kustomize build overlays/prod | yq 'select(.kind == "ConfigMap") | .data'
```

## What each line turns into

Starting from `base/deployment.yaml` (`name: web`, `replicas: 1`,
`image: nginx:1.25`), the prod overlay produces:

| In `overlays/prod/kustomization.yaml` | Effect on the rendered output                       |
|---------------------------------------|-----------------------------------------------------|
| `resources: [../../base]`             | start from everything the base renders              |
| `namespace: prod`                     | `metadata.namespace: prod` on every object          |
| `namePrefix: prod-`                   | `web` → `prod-web`, and references are rewritten    |
| `images: nginx → 1.27`                | `image: nginx:1.27`                                 |
| `replicas: web → 3`                   | `spec.replicas: 3`                                  |
| `configMapGenerator ... behavior: merge` | `GREETING` replaced, `LOG_LEVEL` kept from base  |
| `patches: deployment-resources.yaml`  | adds `resources:` to the `web` container            |

Things worth noticing in the output:

- The ConfigMap is named `prod-web-config-<hash>`. The hash is computed from
  its data. The Deployment's `configMapRef` is rewritten to that exact name,
  so changing a value rolls the pods.
- `namePrefix` renamed the Service and Deployment, but the `app: web`
  selector labels did not change — prefixes apply to names, not labels.
- Patches and `replicas` refer to the object by its **base** name (`web`),
  not the prefixed one.
- The output is sorted (ConfigMap, Service, Deployment) regardless of the
  order you listed resources.

## Experiments

1. Change `LOG_LEVEL` in `base/kustomization.yaml` and re-run
   `kustomize build overlays/dev`. The dev value still wins; prod picks up
   the new base value and its ConfigMap hash changes.
2. Delete `behavior: merge` from the dev overlay. Kustomize errors because
   a ConfigMap named `web-config` already exists — overlays must say how to
   combine.
3. Add `replicas: 5` to the prod patch file and remove the `replicas:`
   field. Same result, different mechanism.
4. Add `namePrefix: x-` to the base too and see that prefixes stack
   (`prod-x-web`).

## How Flux fits in

Flux's `Kustomization` object (`flux/kustomization-prod.yaml`) points at a
directory in a Git repository. On each reconcile, kustomize-controller:

1. runs the same renderer as `kustomize build ./overlays/prod`;
2. replaces `${var}` placeholders with values from `spec.postBuild`
   (this is the closest thing to "values" in the Flux + Kustomize world);
3. applies the result to the cluster with server-side apply.

The prod overlay contains `CLUSTER=${cluster_name:=unknown}`. Plain
`kustomize build` leaves it as-is. To see what Flux would produce:

```sh
kustomize build overlays/prod | cluster_name=prod-eu-1 flux envsubst
```

`${cluster_name:=unknown}` means "use `cluster_name`, or `unknown` if it is
not set".

Note: Flux's `Kustomization` (`kustomize.toolkit.fluxcd.io`) and Kustomize's
`kustomization.yaml` (`kustomize.config.k8s.io`) share a name but are
different things. The first is a cluster object telling Flux *where* to
build; the second is the file telling Kustomize *what* to build.

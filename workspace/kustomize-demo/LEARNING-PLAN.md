# Learning plan: Kustomize → Kubernetes → Flux

A phased plan for learning how Kustomize renders manifests and how Flux
uses it to deploy from Git. Written to be handed to an AI assistant
(e.g. Claude Code on my machine) that will act as my tutor.

## Instructions for the assistant

- You are a tutor, not a doer. I want to learn by typing things myself.
- For each phase: explain the idea briefly, give me the next small step,
  wait for me to run it, then explain what I see in the output.
- Do not edit exercise files for me or show solutions unless I ask.
  When I'm stuck, give a hint first, then a bigger hint, then the answer.
- Before moving to the next phase, ask me 2-3 short questions to check
  I understood the "done when" items. Revisit anything I get wrong.
- Keep a short progress log in `PROGRESS.md` next to this file (phase,
  what I did, what confused me) so we can pick up where we left off.
- Never use real credentials in these exercises. Use throwaway values.

## Where things are

- Repo: `github.com/yaznezamel/flux2`, branch `claude/festive-einstein-nlj3l1`
- Everything lives in `workspace/kustomize-demo/`:
  - `README.md`: the base/overlay demo explained
  - `base/`, `overlays/dev`, `overlays/prod`: the demo app
  - `flux/kustomization-prod.yaml`: a Flux Kustomization example
  - `render.sh`: renders base and overlays and diffs them
  - `exercises/`: level 2 exercises with `check.sh` and `solutions/`

```sh
git clone -b claude/festive-einstein-nlj3l1 https://github.com/yaznezamel/flux2.git
cd flux2/workspace/kustomize-demo
```

---

## Phase 0: Local setup

Install and verify: `kustomize`, `kubectl`, `yq`, `helm`, `flux`, plus
`docker` (or Docker Desktop / Podman) and `kind` for the cluster phases.

```sh
kustomize version && kubectl version --client && yq --version
helm version && flux version --client && kind version && docker info
```

**Done when:** every command prints a version and `docker info` shows a
running daemon.

## Phase 1: Kustomize basics ✅ (done, quick recap)

Bases, overlays, `namespace`, `namePrefix`, `labels`, `images`,
`replicas`, `configMapGenerator` with hash suffixes, strategic-merge
patches, and Flux-style `${var}` substitution with `flux envsubst`.

```sh
./render.sh
```

**Done when:** I can explain, without looking, why the ConfigMap name has
a hash suffix and why patches refer to `web` instead of `prod-web`.

## Phase 2: Advanced Kustomize (exercises 01-05)

Work through `exercises/` in order. Each has a README with the goal.

| # | Topic | Key idea |
|---|---|---|
| 01 | JSON patches | Exact edits and removals by path; list items by index |
| 02 | secretGenerator | Secrets from literals/files; `disableNameSuffixHash` |
| 03 | Components | Reusable feature bundles switched on per overlay |
| 04 | replacements | Copy a field from one object into another |
| 05 | helmCharts | Helm values for what the chart exposes, patches for the rest |

```sh
cd exercises
./check.sh 01        # PASS or a diff
./check.sh all
```

**Done when:** `./check.sh all` passes on my own answers, and I can say
when to use a strategic-merge patch vs a JSON patch vs a component vs a
replacement.

## Phase 3: Apply to a real cluster (kind)

Goal: see rendered YAML become running objects.

1. `kind create cluster --name learn`
2. `kubectl apply -k overlays/dev` (`-k` = run kustomize, then apply).
3. Inspect: `kubectl -n dev get deploy,svc,cm`,
   `kubectl -n dev describe deploy dev-web`.
4. Change `GREETING` in the dev overlay, then `kubectl diff -k overlays/dev`
   before applying. Apply and watch `kubectl -n dev get pods -w`: the new
   ConfigMap hash triggers a rolling update. Notice the old ConfigMap is
   left behind (plain kubectl does not prune).
5. Apply prod too, compare the two namespaces.
6. Clean up: `kubectl delete -k overlays/dev`.

**Done when:** I can explain why changing a ConfigMap value restarted the
pods, and why the old ConfigMap is still there.

## Phase 4: GitOps with Flux

Goal: Git becomes the source of truth; the cluster follows it.

1. Make a small personal GitHub repo (e.g. `kustomize-demo`) containing
   just the `base/`, `overlays/` and `flux/` folders, so Flux does not
   clone the whole flux2 repo.
2. `flux check --pre`, then either:
   - quick path: `flux install`, then create a `GitRepository` for my repo
     with `flux create source git`, or
   - real-world path: `flux bootstrap github` (needs a GitHub token; Flux
     then manages itself from Git too).
3. Create a Flux `Kustomization` for `./overlays/dev` (with
   `flux create kustomization ... --export` first, to read the YAML it
   generates, then apply it).
4. Watch it: `flux get sources git`, `flux get kustomizations`,
   `flux events`, `flux logs`.
5. GitOps loop: change replicas in Git, push, run
   `flux reconcile kustomization <name> --with-source`, see the cluster
   follow. Then change something with `kubectl edit` and watch Flux
   revert it at the next reconcile (drift correction).
6. Pruning: delete `service.yaml` from the base in Git, push, see Flux
   delete the Service (`prune: true`).
7. Local preview tools: `flux build kustomization` and
   `flux diff kustomization` (render/diff what Flux would apply).
8. `postBuild.substitute`: set `cluster_name` on the dev Kustomization and
   check the `CLUSTER` value in the ConfigMap.
9. `flux suspend` / `flux resume` a Kustomization and see what changes.

**Done when:** I can draw the flow Git → source-controller →
kustomize-controller → cluster, and explain what `interval`, `prune`
and `postBuild` do.

## Phase 5: Helm the Flux way

Goal: the HelmRelease equivalent of exercise 05.

1. A `HelmRepository` (or `OCIRepository`) source for a public chart,
   e.g. podinfo (`oci://ghcr.io/stefanprodan/charts/podinfo`).
2. A `HelmRelease` with `spec.values` (Helm values).
3. `spec.valuesFrom` a ConfigMap, to see value layering.
4. `spec.postRenderers` with a kustomize patch for something the chart
   does not expose.
5. Upgrade the chart version in Git, watch `flux get helmreleases`.

**Done when:** I can explain when to use `values`, `valuesFrom` and
`postRenderers`, and how a HelmRelease differs from `helmCharts` in a
kustomization.yaml.

## Phase 6 (optional): Real-world structure

- Secrets with SOPS + age: encrypt a Secret in Git, give Flux the key,
  let it decrypt during the build.
- Repo layout used by Flux docs: `clusters/<name>/`, `infrastructure/`,
  `apps/base`, `apps/<env>`; `dependsOn` between Kustomizations so
  infrastructure is ready before apps.
- Capstone: design a repo for two clusters (dev, prod) with one app,
  one shared component, one Helm chart and one encrypted secret, and
  explain every file to the tutor.

---

## Cleanup

```sh
kind delete cluster --name learn
```

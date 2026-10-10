# Level 2 exercises

Five small, self-contained exercises. Each folder has a `README.md` with
the goal, the files to work on, a `kustomization.yaml` with a `TODO`, and
an `expected.yaml` showing the output you are aiming for.

| #  | Folder                | You learn                                              |
|----|-----------------------|--------------------------------------------------------|
| 01 | `01-json-patch`       | Exact edits and removals with JSON patches             |
| 02 | `02-secret-generator` | Generating Secrets, turning off the hash suffix        |
| 03 | `03-components`       | Reusable feature bundles you switch on per overlay     |
| 04 | `04-replacements`     | Copying a value from one object into another           |
| 05 | `05-helm-chart`       | Rendering a Helm chart with values, then patching it   |

## How to work

```sh
cd workspace/kustomize-demo/exercises

cat 01-json-patch/README.md     # read the goal
$EDITOR 01-json-patch/kustomization.yaml
kustomize build 01-json-patch   # look at your output
./check.sh 01                   # PASS, or a diff of what is still wrong
```

`./check.sh all` checks every exercise.

Stuck? `./check.sh --solution 01` prints the reference
`kustomization.yaml` and its output. The solutions also live in
`solutions/`. Try for a while before looking.

Start over on an exercise: `git checkout -- 01-json-patch`

## Tools

Exercises 01-04 need only `kustomize`. Exercise 05 also needs `helm` on
your PATH; `check.sh` passes `--enable-helm` for it automatically.

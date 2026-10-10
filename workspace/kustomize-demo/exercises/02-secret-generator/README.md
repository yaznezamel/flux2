# 02 - secretGenerator

`secretGenerator` works like `configMapGenerator`, but produces a Secret
and base64-encodes the values for you.

```yaml
secretGenerator:
  - name: my-secret
    literals:            # key=value pairs written inline
      - key=value
    files:               # key = file name, value = file content
      - some-file.txt
      - custom-key=some-file.txt
    type: Opaque         # or kubernetes.io/tls, etc.
```

## Goal

Make `kustomize build .` match `expected.yaml`:

1. A Secret `db-credentials` with:
   - `username` = `api` (as a literal)
   - `password` = the content of `password.txt` (use the `key=file` form)
2. A Secret `api-tls` of type `Opaque` with a key `tls.crt` from the file
   `tls.crt`, and **without** a hash suffix on its name.
   (hint: generators accept `options: { disableNameSuffixHash: true }`)

Notice that the Deployment's `secretKeyRef` names get the hash suffix
rewritten automatically, but `api-tls` keeps its plain name.

Check: `./check.sh 02`

## Takeaway

base64 is encoding, not encryption. Never commit real secrets in plain
files like this. With Flux, encrypt them with SOPS (Flux decrypts during
the build) or pull them from a secret store with External Secrets.

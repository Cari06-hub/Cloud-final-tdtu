# Security Baseline and Credential Rotation

> Owner: Trung Nguyên - `52400141`
> Baseline date: `2026-11-10`
> Scope: branch `Nguyen` and final integration

## 1. Current finding

Remote branch `Quang` contains a committed `.env` in commit `6885541`. Secret
values from that file are intentionally not copied into this document. Because
the repository content has been available remotely, every credential from that
file must be treated as compromised even if the file is later deleted.

The `Nguyen` branch does not currently track `.env`. Integration must use an
allowlist of source directories or a sanitized TV1 commit; it must not merge the
credential-bearing commit into the final branch history.

## 2. Required credential rotation

Generate new, unique values in each real environment for:

- [ ] `MARIADB_ROOT_PASSWORD`.
- [ ] `MARIADB_PASSWORD`.
- [ ] `KEYCLOAK_ADMIN_PASSWORD`.
- [ ] User passwords for `sv01` and `sv02` if those values were shared publicly.
- [ ] `MINIO_ROOT_PASSWORD`.
- [ ] MinIO access keys created during testing.
- [ ] `GF_SECURITY_ADMIN_PASSWORD`.
- [ ] Any AWS credential or EC2 private key if it was ever copied into the repo.

Rotation is not complete merely by deleting `.env`. The services must be
updated to use the new values, restarted safely and retested.

## 3. Storage rules

- Store local secrets only in `.env`, which is ignored by Git.
- Store EC2 secrets in a separate `.env` created directly on the instance.
- Never put real values in `.env.example`, Compose YAML, Markdown, screenshots
  or shell history committed to Git.
- Do not upload `.pem`, `.key`, `.p12`, `.pfx`, `.aws/` or `secrets/`.
- Redact Authorization headers, bearer tokens, MinIO keys and passwords from
  evidence images and logs.

## 4. Integration rule for TV1 content

Before importing TV1 files:

1. Fetch the source branch.
2. Select only the approved application directories and non-secret files.
3. Exclude `.env` explicitly.
4. Inspect staged content with `git diff --cached`.
5. Run the secret checks in this document.
6. Commit only after the staged diff is clean.

Preferred long-term resolution: TV1 creates a new sanitized commit/PR that
removes `.env`, adds `.env.example` and confirms credential rotation. Rewriting
published branch history must only be done after the whole group coordinates.

## 5. Pre-commit security checks

Confirm `.env` is ignored:

```bash
git check-ignore -v .env
git ls-files --error-unmatch .env
```

The second command is expected to fail because `.env` must not be tracked.

Inspect the exact staged patch:

```bash
git diff --cached --check
git diff --cached
```

Search tracked and proposed files for common private-key/AWS patterns:

```bash
git grep -n -I -E 'AKIA[0-9A-Z]{16}|BEGIN (RSA |OPENSSH )?PRIVATE KEY'
```

Search for accidental real values assigned to sensitive variables. Review all
matches manually; placeholder values in `.env.example` are allowed:

```bash
git grep -n -I -E '(PASSWORD|SECRET|ACCESS_KEY|PRIVATE_KEY|TOKEN)='
```

## 6. Completion gate

- [x] `.gitignore` blocks local `.env` and common secret/key formats.
- [x] `.env.example` contains placeholders only.
- [x] The current `Nguyen` branch does not track `.env`.
- [x] The credential-bearing TV1 commit is not merged into `Nguyen`.
- [ ] All credentials previously exposed on the remote have been rotated.
- [ ] TV1 has delivered a sanitized commit or confirmed the allowlisted import.
- [ ] Local, EC2 and demo environments have distinct real passwords.

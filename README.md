Secrets KMS
-----------

Uses [Google KMS](https://cloud.google.com/kms/) to encrypt values in
YAML/JSON/Text files to be able to store them in Git.

### Requirements:

- docker

You can use plain ruby version. But recommended way is to run it via docker.

### Setup:

Make sure you have enough permissions within your Google project in order to
to work with KMS.
Acquire new user credentials to use for Application Default Credentials
```
gcloud auth application-default login
```

Make sure that you have `~/bin` in your `PATH`.
Download shortcut to run docker container
```bash
curl -L https://raw.githubusercontent.com/Bidmath/kms-secrets/v0.1.0/bin/kms-secrets \
  -o ~/bin/kms-secrets
chmod +x  ~/bin/kms-secrets
```
Make sure that you understand the content of `~/bin/kms-secrets`

### Usage:

To encrypt for the first time:
```bash
kms-secrets encrypt \
  --project=my-project \
  --key_ring=my-keyring \
  --key_name=my-key \
  path/to/src/config-unencrypted.yaml
  path/to/dest/config-encrypted.yaml
```

To edit encrypted file (in VIM):
```bash
kms-secrets edit path/to/config-encrypted.yaml
```

To view (in `less`):
```bash
kms-secrets view path/to/config-encrypted.yaml
```

To decrypt:
```bash
kms-secrets decrypt \
  path/to/src/config-encrypted.yaml
  path/to/dest/config-unencrypted.yaml
```

Decrypting is skipped if checksum of target (unencrypted) file matches one
stored in metadata of encrypted.
It also validates checksums after decrypting (if one took place)

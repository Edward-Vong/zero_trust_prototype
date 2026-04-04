# step-ca placeholder

This folder is intended to hold the Smallstep CA configuration and generated certificates.

## What to add

- `config/ca.json` - step-ca configuration file
- `certs/` - issued certificates for the frontend, internal-api, and backend
- `password` or secure secret management for CA initialization

## Next step

Use the official `smallstep/step-ca` image and initialize the CA with:

```bash
step ca init --name "Zero Trust CA" --provisioner admin --dns step-ca --address ":9000"
```

Then place the generated files under `step-ca/` so other containers can mount them for mTLS.

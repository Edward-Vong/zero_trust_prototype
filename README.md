# Zero Trust Prototype

This repository contains the starting scaffold for a zero trust proof-of-concept using Docker Compose.

It is organized around three zones:
- `step-ca` — Certificate Authority / security zone
- `pomerium` — Access zone and policy enforcement gateway
- `wireguard` — Encrypted network overlay service
- `services/` — Application zone containing `frontend`, `internal-api`, and `backend`

## What is included

- Python Flask sample services for `frontend`, `internal-api`, and `backend`
- `docker-compose.yml` with the initial architecture layout
- Placeholder directories for `step-ca`, `pomerium`, and `wireguard`

## Getting started

### 1. Start the application services first

This brings up the service stack without the security and gateway layers.

```powershell
cd "d:\Coding Project\zero_trust_prototype"
docker compose up --build backend internal-api frontend
```

Then open:
- `http://localhost:5000` for the frontend service
- `http://localhost:5001/health` for the internal API
- `http://localhost:5002/health` for the backend

### 2. Add the zero trust components

The next step is to configure `step-ca`, `pomerium`, and `wireguard`:
- `step-ca` must generate a CA and issue mTLS certificates
- `pomerium` must be configured to route traffic through the frontend and enforce policy
- `wireguard` should be used to isolate encrypted traffic between services

### 3. Future work

- Hook the frontend and internal API into mTLS via `step-ca`
- Configure `pomerium` policies and routes using real certificate files
- Add a compromised/untrusted client to demonstrate blocked access

## Notes

Windows users may need Docker Desktop with WSL2 backend enabled to run Linux containers and WireGuard.

## Next step

Open `services/frontend/app.py`, `services/internal-api/app.py`, and `services/backend/app.py` to extend endpoints and implement the security flow.

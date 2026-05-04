# Zero-Trust Micro-segmentation Prototype
## by Group 1 (Vicki Liang, Owen Semersky, Edward Vong)

I would like to gently request y'all to work in your own branch for each container juuust in case of something :)

### Basic structure of project
Each folder should be its own container! In theory there should be no merge conflicts.

```
zero-trust-lab/
├── app/
│   ├── frontend/
│   ├── api/
│   └── backend/
├── infrastructure/
│   ├── pomerium/
│   ├── step-ca/
│   └── wireguard/
```

## Run locally

#### Edit your host file:

Windows:
```
C:\Windows\System32\drivers\etc\hosts
```

Linux:
```
sudo nano /etc/hosts
```

macOS:
```
sudo nano /etc/hosts
```

#### Add hosts:
```
127.0.0.1 app.zt.local
127.0.0.1 api.zt.local
```

#### Flush DNS cache:

Windows (new connections should take effect immediately but if it doesn't):
```
ipconfig /flushdns
```

Linux (Ubuntu 18.04 and later):
```
sudo resolvectl flush-caches
```

Linux (older systems using `ncsd`):
```
sudo systemctl restart nscd
```

macOS:
```
sudo dscacheutil -flushcache
sudo killall -HUP mDNSResponder
```

#### From the project root:

```bash
docker compose up -d --build
```

This starts the core stack (`step-ca`, `backend`, `api`, `frontend`, `pomerium`, `attacker`) on Windows, Linux, and macOS.

WireGuard is optional and Linux-oriented. Start it only when needed:

```bash
docker compose --profile wireguard up -d --build
```

#### Then open the UI at:

- `https://app.zt.local`

#### If you want to access services directly:

- API: `http://app.zt.local:4000`
- Backend: `http://app.zt.local:5000`
- Step-CA UI: `http://app.zt.local:9000`

Use `docker compose logs -f` to watch service output while testing.

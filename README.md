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

From the project root:

```bash
docker-compose up --build
```

Then open the UI at:

- `http://localhost`

If you want to access services directly:

- API: `http://localhost:4000`
- Backend: `http://localhost:5000`
- Step-CA UI: `http://localhost:9000`

Use `docker-compose logs -f` to watch service output while testing.

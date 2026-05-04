## Test Procedures Overview

Pre-check:

```
docker compose ps
```

Expected:

- frontend, api, backend, step-ca, pomerium, attacker are Up

Run attacker-scope tests from:

```
docker compose exec attacker sh
```

### Network Segmentation

#### Test 1 - API unreachable from edge network
```
curl -sk --max-time 3 https://172.31.11.11:4000 || echo BLOCKED
```
> Should print BLOCKED

#### Test 2 - Backend unreachable from edge network
```
nc -zv 172.31.12.11 5000
```
> Should fail (no route or timeout)

#### Test 3 - Frontend reachable only via Pomerium
```
curl -k https://172.21.0.20 -H "Host: app.zt.local"
```
> Should redirect to login — direct access blocked without identity token

### Pomerium Proof (Identity Enforcement)

#### Test 1 - Protected route
Open in browser: `https://app.zt.local`
> Should redirect to login — authentication is required

#### Test 2 - Bypassing attempt
```
curl -k --max-time 3 https://zt-frontend || echo BLOCKED
```
> Should fail — frontend not on edge_net; pomerium_frontend_net is internal only

### mTLS Proof (Service Identity)

Run these from host (using frontend as the caller to api.local):

#### Test 1 - API rejects connection without client certificate
```
docker compose exec frontend sh -c "curl -sk https://api.local:4000/health"
```
> Should fail with SSL handshake error — server requires a client cert

#### Test 2 - API rejects wrong/untrusted client certificate
```
docker compose exec frontend sh -c "
     openssl req -x509 -newkey rsa:2048 -keyout /tmp/fake.key -out /tmp/fake.crt -days 1 -nodes -subj '/CN=fake' >/dev/null 2>&1 &&
     curl -s --cert /tmp/fake.crt --key /tmp/fake.key --cacert /etc/nginx/certs/ca_chain.crt https://api.local:4000/health || echo REJECTED
"
```
> Should fail — cert not signed by trusted CA

#### Test 3 - API accepts valid frontend client certificate
```
docker compose exec frontend sh -c "
  curl -s --cert /etc/nginx/certs/frontend/frontend.crt \
       --key /etc/nginx/certs/frontend/frontend.key \
       --cacert /etc/nginx/certs/ca_chain.crt \
       https://api.local:4000/health
"
```
> Should return `{"status": "API service is healthy"}` — mTLS succeeds

#### Test 4 - Backend rejects connection without client certificate
```
docker compose exec frontend sh -c "
  curl -s --cert /etc/nginx/certs/frontend/frontend.crt \
       --key /etc/nginx/certs/frontend/frontend.key \
       --cacert /etc/nginx/certs/ca_chain.crt \
       https://api.local:4000/api/mtls/backend/no-cert
"
```
> Should return JSON with rejected: true

#### Test 5 - Backend accepts valid API client certificate
```
docker compose exec frontend sh -c "
  curl -s --cert /etc/nginx/certs/frontend/frontend.crt \
       --key /etc/nginx/certs/frontend/frontend.key \
       --cacert /etc/nginx/certs/ca_chain.crt \
       https://api.local:4000/api/mtls/backend/health
"
```
> Should return JSON with mtls: ok and backend_body.status: Backend service is healthy

#### Test 6 - End-to-end app path through nginx
```
curl -s http://localhost/api/data
```
> Should return JSON from backend via frontend -> api -> backend chain

### step-ca Proof (Certificate Authority)

```
docker compose exec step-ca step certificate inspect /home/step/issued/api/api.crt
docker compose exec step-ca step certificate inspect /home/step/issued/backend/backend.crt
docker compose exec step-ca step certificate inspect /home/step/issued/frontend/frontend.crt
```
> Each cert should show issuer matching the Zero Trust Prototype intermediate CA  
> Same certs are used live in mTLS handshakes above

### WireGuard Proof

#### Test 1 - Show active peers
```
docker exec -it wireguard wg show
```
> Should list peers: peer_frontend, peer_api, peer_backend  
> Each should show a latest handshake and non-zero transfer counters

#### Test 2 - Peer-to-peer traffic over tunnel
```
# From inside a WG peer container
curl https://10.13.13.3:<PORT>
```
> Proves encrypted peer-to-peer communication through the WireGuard tunnel

#### Test 3 - Confirm allowed IP route usage
```
# From inside the Frontend container
ping 172.31.11.11
```
> Proves the defined route Frontend --> API allows traffic  
> Should display reply packets from the API

#### Test 4 - Confirm blocking of guarded IP routes
```
# From inside the Frontend container
ping 172.31.12.11
```
> Proves undefined routes do not work (Frontend --> Backend is not allowed)  
> Should see packets being sent, but no replies received  

#### Test 5 - Confirm unguarded routes are still accessible
```
# From inside the Frontend container
ping 8.8.8.8
```
> Outbound traffic should still be allowed, not blocked in WG  
> Should see returning replies from public IP 8.8.8.8

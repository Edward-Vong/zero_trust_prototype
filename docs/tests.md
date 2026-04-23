## Test Procedues Overview

From attacker container:

`
docker exec -it zt-attacker sh
`

### Network Segmentation

#### Test 1 - API access
`
curl https://zt-api:4000
`
> should fail
> proves API is not reachable from untrusted network

#### Test 2 - Backend access
`
nc -zv zt-backend 5000
`
> should fail 
> prove no lateral segmentation to backend

### Pomerium Proof (Identitfy Enforcement)

#### Test 1 - Protected route

Open in browser: `https://app.zt.local`
> should redirect to login
> proves authetication is required

#### Test 2 - Bypassing Attempt
`
curl https://zt-frontend
`
> should fail
> proves direct access is blocked

### mTLS Proof (Service Identity)

#### Test 1 - Without certificate
`
curl https://api:4000
`
>should fail

#### Test 2 - Wrong certificate
`
curl --cert fake.crt --key fake.key https://api:4000
`
> should fail

#### Test 3 - Valid certificate
`
curl --curl api.crt --key api.key --cacert root_ca.crt https://api:4000
`
> should be successful
> proves only trusted identities can access services

### step-ca Proof (Certificate Authority)

`
step certificate inspect api.crt
step certificate inspect backend.crt
`
should show issuer is Zero Trust Pro CA and be same cert used in mTLS

### WireGuard Proof

#### Test 1 - Without Wireguard
> connection should fail

#### Test 2 - With Wireguard
`
wg show
`
> peer exists, latest handshake exists, and that tranfer counters are non-zero

> can also show traffic going over the tunnel into another peer's WireGuard IP
`
curl https://<WG_IP>:<PORT>
`
> prove secure peer-to-peer communciation via WireGuard
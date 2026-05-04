#!/bin/sh
set -eu

STEP_HOME="/home/step"
SECRETS_DIR="$STEP_HOME/secrets"
CERTS_DIR="$STEP_HOME/certs"
ISSUED_DIR="$STEP_HOME/issued"
POMERIUM_TLS_DIR="$ISSUED_DIR/pomerium"

PASSWORD_FILE="$SECRETS_DIR/password"
NORM_PASSWORD_FILE="$SECRETS_DIR/password.lf"

CA_CONFIG="$STEP_HOME/config/ca.json"
INTERMEDIATE_CERT="$CERTS_DIR/intermediate_ca.crt"
ROOT_CERT="$CERTS_DIR/root_ca.crt"
INTERMEDIATE_KEY="$SECRETS_DIR/intermediate_ca_key"

generate_password() {
    # Generate a portable alphanumeric password and keep it on one line.
    tr -dc 'A-Za-z0-9' < /dev/urandom | head -c 40
    echo
}

mkdir -p "$SECRETS_DIR" "$CERTS_DIR" "$ISSUED_DIR/frontend" "$ISSUED_DIR/api" "$ISSUED_DIR/backend" "$POMERIUM_TLS_DIR"

# Clean up legacy template directory from older local setups.
if [ -d "$STEP_HOME/templates" ]; then
    rm -rf "$STEP_HOME/templates"
fi

HAS_EXISTING_PKI=1
for required in "$CA_CONFIG" "$INTERMEDIATE_CERT" "$ROOT_CERT" "$INTERMEDIATE_KEY"
do
    if [ ! -s "$required" ]; then
        HAS_EXISTING_PKI=0
        break
    fi
done

if [ -s "$PASSWORD_FILE" ] && grep -q "BEGIN .*PRIVATE KEY" "$PASSWORD_FILE"; then
    echo "Invalid password file detected at $PASSWORD_FILE (contains private key PEM). Regenerating." >&2
    rm -f "$PASSWORD_FILE"
fi

if [ ! -s "$PASSWORD_FILE" ]; then
    generate_password > "$PASSWORD_FILE"
    chmod 600 "$PASSWORD_FILE" 2>/dev/null || true
    echo "Generated new CA password at $PASSWORD_FILE"

    if [ "$HAS_EXISTING_PKI" -eq 1 ]; then
        echo "Existing CA material found without a usable password file; reinitializing CA material." >&2
        rm -f "$STEP_HOME/config/ca.json" "$STEP_HOME/config/defaults.json"
        rm -f "$CERTS_DIR/root_ca.crt" "$CERTS_DIR/intermediate_ca.crt" "$CERTS_DIR/ca_chain.crt"
        rm -f "$SECRETS_DIR/root_ca_key" "$SECRETS_DIR/intermediate_ca_key"
        rm -rf "$STEP_HOME/db"
        mkdir -p "$STEP_HOME/db"
        HAS_EXISTING_PKI=0
    fi
fi

if [ "$HAS_EXISTING_PKI" -eq 0 ]; then
    echo "Initializing new step-ca PKI material..."
    step ca init \
        --name "${DOCKER_STEPCA_INIT_NAME:-Zero Trust Prototype CA}" \
        --dns "${DOCKER_STEPCA_INIT_DNS_NAMES:-localhost,step-ca,app.zt.local,api.zt.local}" \
        --address "${DOCKER_STEPCA_INIT_ADDRESS:-:9000}" \
        --provisioner "${DOCKER_STEPCA_INIT_PROVISIONER_NAME:-admin}" \
        --password-file "$PASSWORD_FILE" \
        --provisioner-password-file "$PASSWORD_FILE" \
        --deployment-type "${DOCKER_STEPCA_INIT_DEPLOYMENT_TYPE:-standalone}"
fi

for required in "$CA_CONFIG" "$INTERMEDIATE_CERT" "$ROOT_CERT" "$INTERMEDIATE_KEY" "$PASSWORD_FILE"
do
    if [ ! -f "$required" ] || [ ! -s "$required" ]; then
        echo "Missing step-ca bootstrap file: $required" >&2
        exit 1
    fi
done

tr -d '\r\n' < "$PASSWORD_FILE" > "$NORM_PASSWORD_FILE"

issue_cert() {
    name="$1"
    sans="$2"
    out_dir="$ISSUED_DIR/$name"
    crt="$out_dir/$name.crt"
    key="$out_dir/$name.key"

    rm -f "$crt" "$key"
    step certificate create "$name" "$crt" "$key" \
        --san "$name" \
        --san "$sans" \
        --ca "$INTERMEDIATE_CERT" \
        --ca-key "$INTERMEDIATE_KEY" \
        --ca-password-file "$NORM_PASSWORD_FILE" \
        --no-password \
        --insecure \
        --not-after 2160h
}

issue_cert frontend frontend.local
issue_cert api api.local
issue_cert backend backend.local

rm -f "$POMERIUM_TLS_DIR/tls.crt" "$POMERIUM_TLS_DIR/tls.key"
step certificate create app.zt.local "$POMERIUM_TLS_DIR/tls.crt" "$POMERIUM_TLS_DIR/tls.key" \
    --san app.zt.local \
    --san api.zt.local \
    --san localhost \
    --ca "$INTERMEDIATE_CERT" \
    --ca-key "$INTERMEDIATE_KEY" \
    --ca-password-file "$NORM_PASSWORD_FILE" \
    --no-password \
    --insecure \
    --not-after 2160h

if [ -d "$CERTS_DIR/ca_chain.crt" ]; then
    rm -rf "$CERTS_DIR/ca_chain.crt"
fi
rm -f "$CERTS_DIR/ca_chain.crt"
cat "$INTERMEDIATE_CERT" "$ROOT_CERT" > "$CERTS_DIR/ca_chain.crt"

exec step-ca "$CA_CONFIG" --password-file "$NORM_PASSWORD_FILE"

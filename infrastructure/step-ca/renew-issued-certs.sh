#!/bin/sh

STEP_HOME="/home/step"
ISSUED_DIR="$STEP_HOME/issued"
POMERIUM_TLS_DIR="$ISSUED_DIR/pomerium"
CA_CERT="$STEP_HOME/certs/intermediate_ca.crt"
CA_KEY="$STEP_HOME/secrets/intermediate_ca_key"
NORM_PASS_FILE="$STEP_HOME/secrets/password.lf"
NOT_AFTER="${1:-2160h}"

if [ -s "$STEP_HOME/secrets/password" ]; then
    CA_PASS_FILE="$STEP_HOME/secrets/password"
elif [ -s "$STEP_HOME/secrets/dev@209-group1" ]; then
    CA_PASS_FILE="$STEP_HOME/secrets/dev@209-group1"
else
    echo "Missing CA password source file in $STEP_HOME/secrets" >&2
    exit 1
fi

# Normalize the mounted password file to one line without trailing CR/LF.
tr -d '\r\n' < "$CA_PASS_FILE" > "$NORM_PASS_FILE"

issue_cert() {
    name="$1"
    sans="$2"
    out_dir="$ISSUED_DIR/$name"
    crt="$out_dir/$name.crt"
    key="$out_dir/$name.key"

    mkdir -p "$out_dir"

    # Always overwrite old artifacts so mounted services pick up fresh certs.
    rm -f "$crt" "$key"

    step certificate create "$name" "$crt" "$key" \
        --san "$name" \
        --san "$sans" \
        --ca "$CA_CERT" \
        --ca-key "$CA_KEY" \
        --ca-password-file "$NORM_PASS_FILE" \
        --no-password \
        --insecure \
        --not-after "$NOT_AFTER"

    test -s "$crt"
    test -s "$key"
}

# Clean up accidental outputs in /home/step from prior manual commands.
rm -f \
    "$STEP_HOME/frontend.crt" "$STEP_HOME/frontend.key" \
    "$STEP_HOME/api.crt" "$STEP_HOME/api.key" \
    "$STEP_HOME/backend.crt" "$STEP_HOME/backend.key"

issue_cert frontend frontend.local
issue_cert api api.local
issue_cert backend backend.local

# Keep Pomerium's edge TLS cert in issued/pomerium with other issued identities.
mkdir -p "$POMERIUM_TLS_DIR"
rm -f "$POMERIUM_TLS_DIR/tls.crt" "$POMERIUM_TLS_DIR/tls.key"
step certificate create app.zt.local \
    "$POMERIUM_TLS_DIR/tls.crt" "$POMERIUM_TLS_DIR/tls.key" \
    --san app.zt.local \
    --san api.zt.local \
    --san localhost \
    --ca "$CA_CERT" \
    --ca-key "$CA_KEY" \
    --ca-password-file "$NORM_PASS_FILE" \
    --no-password \
    --insecure \
    --not-after "$NOT_AFTER"

# Rebuild the CA chain bundle (intermediate + root) for TLS verification.
cat "$STEP_HOME/certs/intermediate_ca.crt" "$STEP_HOME/certs/root_ca.crt" \
    > "$STEP_HOME/certs/ca_chain.crt"

echo "Reissued certs in:"
echo "  $ISSUED_DIR/frontend/frontend.crt"
echo "  $ISSUED_DIR/api/api.crt"
echo "  $ISSUED_DIR/backend/backend.crt"
echo "  $POMERIUM_TLS_DIR/tls.crt"
echo "Chain bundle: $STEP_HOME/certs/ca_chain.crt"

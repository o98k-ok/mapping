#!/usr/bin/env bash
set -euo pipefail

IDENTITY_NAME="${MAPPING_SIGN_IDENTITY:-Mapping Self-Signed}"
KEYCHAIN_BASENAME="${MAPPING_SIGN_KEYCHAIN:-mapping-signing.keychain-db}"
KEYCHAIN_PASSWORD="${MAPPING_SIGN_KEYCHAIN_PASSWORD:-mapping-dev-internal}"
KEYCHAIN_PATH="$HOME/Library/Keychains/$KEYCHAIN_BASENAME"

ensure_in_search_list() {
    local kc="$1"
    local list
    list=$(security list-keychains -d user | tr -d '"' | xargs)
    case " $list " in
        *" $kc "*) return 0 ;;
    esac
    # shellcheck disable=SC2086
    security list-keychains -d user -s $list "$kc" >/dev/null
}

has_identity() {
    security find-identity -p codesigning "$1" 2>/dev/null |
        grep -F "\"$IDENTITY_NAME\"" >/dev/null
}

if [ -f "$KEYCHAIN_PATH" ] && has_identity "$KEYCHAIN_PATH"; then
    ensure_in_search_list "$KEYCHAIN_PATH"
    if security unlock-keychain -p "$KEYCHAIN_PASSWORD" "$KEYCHAIN_PATH" >/dev/null 2>&1; then
        security set-keychain-settings "$KEYCHAIN_PATH" >/dev/null
        echo "$IDENTITY_NAME"
        exit 0
    fi
fi

echo "Creating codesigning identity '$IDENTITY_NAME'..." >&2

rm -f "$KEYCHAIN_PATH"
security create-keychain -p "$KEYCHAIN_PASSWORD" "$KEYCHAIN_PATH" >/dev/null
security unlock-keychain -p "$KEYCHAIN_PASSWORD" "$KEYCHAIN_PATH" >/dev/null
security set-keychain-settings "$KEYCHAIN_PATH" >/dev/null

workdir="$(mktemp -d)"
trap 'rm -rf "$workdir"' EXIT

conf="$workdir/cert.cnf"
key="$workdir/key.pem"
cert="$workdir/cert.pem"
p12="$workdir/bundle.p12"

cat >"$conf" <<EOF
[ req ]
distinguished_name = dn
prompt = no
x509_extensions = v3
[ dn ]
CN = $IDENTITY_NAME
[ v3 ]
basicConstraints = critical, CA:false
keyUsage = critical, digitalSignature
extendedKeyUsage = critical, codeSigning
subjectKeyIdentifier = hash
EOF

openssl req -x509 -newkey rsa:2048 -nodes \
    -keyout "$key" -out "$cert" \
    -days 3650 -config "$conf" >/dev/null 2>&1

p12_pass="import-pass"
openssl pkcs12 -export -legacy \
    -inkey "$key" -in "$cert" \
    -name "$IDENTITY_NAME" \
    -out "$p12" -passout "pass:$p12_pass"

# -A allows any application to access without GUI password prompt
security import "$p12" \
    -k "$KEYCHAIN_PATH" \
    -P "$p12_pass" \
    -A >/dev/null

security set-key-partition-list \
    -S apple-tool:,apple:,codesign: \
    -s \
    -k "$KEYCHAIN_PASSWORD" \
    "$KEYCHAIN_PATH" >/dev/null 2>&1 || true

ensure_in_search_list "$KEYCHAIN_PATH"

if ! has_identity "$KEYCHAIN_PATH"; then
    echo "Failed to register identity '$IDENTITY_NAME' in $KEYCHAIN_PATH" >&2
    exit 1
fi

echo "$IDENTITY_NAME"

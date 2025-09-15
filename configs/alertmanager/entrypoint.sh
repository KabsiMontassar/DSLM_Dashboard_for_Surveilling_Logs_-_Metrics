#!/bin/sh
# Substitute environment variables in alertmanager config
# Fallback method when envsubst is not available

# Function to replace environment variables in file
replace_vars() {
    input_file="$1"
    output_file="$2"

    # Use sed to replace environment variables
    sed \
        -e "s|\${ALERTMANAGER_SMTP_SMARTHOST}|${ALERTMANAGER_SMTP_SMARTHOST:-localhost:587}|g" \
        -e "s|\${ALERTMANAGER_SMTP_FROM}|${ALERTMANAGER_SMTP_FROM:-alertmanager@example.org}|g" \
        -e "s|\${ALERTMANAGER_SMTP_USERNAME}|${ALERTMANAGER_SMTP_USERNAME:-}|g" \
        -e "s|\${ALERTMANAGER_SMTP_PASSWORD}|${ALERTMANAGER_SMTP_PASSWORD:-}|g" \
        -e "s|\${ALERTMANAGER_WEBHOOK_URL}|${ALERTMANAGER_WEBHOOK_URL:-http://127.0.0.1:5001/}|g" \
        "$input_file" > "$output_file"
}

# Try envsubst first, fallback to sed if not available
if command -v envsubst >/dev/null 2>&1; then
    echo "Using envsubst for variable substitution"
    envsubst < /etc/alertmanager/alertmanager.yml > /etc/alertmanager/alertmanager-substituted.yml
else
    echo "envsubst not found, using sed fallback"
    replace_vars /etc/alertmanager/alertmanager.yml /etc/alertmanager/alertmanager-substituted.yml
fi

# Check if the substitution worked, otherwise use simple config
if [[ ! -f /etc/alertmanager/alertmanager-substituted.yml ]] || ! grep -q "route:" /etc/alertmanager/alertmanager-substituted.yml 2>/dev/null; then
    echo "Configuration substitution failed, using simple config"
    cp /etc/alertmanager/alertmanager-simple.yml /etc/alertmanager/alertmanager-substituted.yml
fi

# Start Alertmanager with the processed config
exec /bin/alertmanager --config.file=/etc/alertmanager/alertmanager-substituted.yml --storage.path=/alertmanager
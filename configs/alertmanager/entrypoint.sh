#!/bin/bash
# Substitute environment variables in alertmanager config
envsubst < /etc/alertmanager/alertmanager.yml > /etc/alertmanager/alertmanager-substituted.yml
exec /bin/alertmanager --config.file=/etc/alertmanager/alertmanager-substituted.yml --storage.path=/alertmanager
FROM hashicorp/terraform:latest

# Azure CLI is required by the azurerm Terraform provider/backend
# for CLI-based authentication (it invokes `az` to obtain tokens).
RUN apk add --no-cache python3 py3-pip && \
    pip3 install --break-system-packages azure-cli

# The host's ~/.azure is mounted read-only, but Azure CLI writes
# log files and token cache updates there. Copy it to a writable
# location at startup and redirect via AZURE_CONFIG_DIR.
RUN printf '#!/bin/sh\n\
if [ -d /root/.azure ]; then\n\
  cp -a /root/.azure /tmp/.azure\n\
  export AZURE_CONFIG_DIR=/tmp/.azure\n\
fi\n\
exec "$@"\n' > /entrypoint.sh && chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]

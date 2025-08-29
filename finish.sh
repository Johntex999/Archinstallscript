#!/bin/bash
set -euo pipefail

echo ">>> Starting archinstall script..."  # Debug message

pacman -Sy archinstall -y
archinstall --config user_configuration.json --creds user_credentials.json

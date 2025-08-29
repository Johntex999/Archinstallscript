#!/bin/bash
set -euo pipefail

echo ">>> Starting archinstall script..."  # Debug message

archinstall --config user_configuration.json --creds user_credentials.json

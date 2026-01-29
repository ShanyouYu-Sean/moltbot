#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  scripts/run-from-source-with-proxy.sh [options]

Options:
  --http-proxy <url>     Set http_proxy (and HTTP_PROXY)
  --https-proxy <url>    Set https_proxy (and HTTPS_PROXY)
  --proxy <url>          Set both http_proxy and https_proxy
  --skip-install         Skip pnpm install + pnpm ui:build
  --skip-build           Skip pnpm build
  --skip-onboard         Skip pnpm moltbot onboard --install-daemon
  --dev-only             Skip install/build/onboard; only run gateway:watch
  -h, --help             Show this help

Notes:
  - If not provided, this script will reuse existing HTTP_PROXY/HTTPS_PROXY/env values.
  - It follows README.md "From source (development)" steps, then runs pnpm gateway:watch.
EOF
}

http_proxy_override=""
https_proxy_override=""
skip_install=0
skip_build=0
skip_onboard=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --http-proxy)
      http_proxy_override="${2:-}"
      shift 2
      ;;
    --https-proxy)
      https_proxy_override="${2:-}"
      shift 2
      ;;
    --proxy)
      http_proxy_override="${2:-}"
      https_proxy_override="${2:-}"
      shift 2
      ;;
    --skip-install)
      skip_install=1
      shift
      ;;
    --skip-build)
      skip_build=1
      shift
      ;;
    --skip-onboard)
      skip_onboard=1
      shift
      ;;
    --dev-only)
      skip_install=1
      skip_build=1
      skip_onboard=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      usage
      exit 1
      ;;
  esac
done

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

http_proxy_value="${http_proxy_override:-${HTTP_PROXY:-${http_proxy:-}}}"
https_proxy_value="${https_proxy_override:-${HTTPS_PROXY:-${https_proxy:-}}}"

if [[ -n "$http_proxy_value" ]]; then
  export http_proxy="$http_proxy_value"
  export HTTP_PROXY="$http_proxy_value"
fi

if [[ -n "$https_proxy_value" ]]; then
  export https_proxy="$https_proxy_value"
  export HTTPS_PROXY="$https_proxy_value"
fi

if [[ "$skip_install" -eq 0 ]]; then
  pnpm install
  pnpm ui:build
fi

if [[ "$skip_build" -eq 0 ]]; then
  pnpm build
fi

if [[ "$skip_onboard" -eq 0 ]]; then
  pnpm moltbot onboard --install-daemon
fi

exec pnpm gateway:watch

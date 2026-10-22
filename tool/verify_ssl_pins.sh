#!/usr/bin/env bash
# Verifies that every pin declared in lib/common/network/ssl_pinning.dart matches
# the SPKI SHA-256 of its bundled PEM, and that no certificate has expired.
# With --live, also connects to the given hosts and checks that the served chain
# contains at least one pinned certificate (needs network; not run in CI).
#
#   tool/verify_ssl_pins.sh
#   tool/verify_ssl_pins.sh --live api.racketmatesapp.com api-qa.racketmatesapp.com
set -euo pipefail
cd "$(dirname "$0")/.."

SRC=lib/common/network/ssl_pinning.dart
spki() { openssl x509 -noout -pubkey | openssl pkey -pubin -outform der | openssl dgst -sha256 -binary | openssl enc -base64; }

fail=0
pins=()
while IFS='|' read -r hash asset; do
  [ -z "$hash" ] && continue
  actual="$(spki < "$asset")"
  if [ "$actual" = "$hash" ]; then
    echo "OK    $asset  $hash"
  else
    echo "FAIL  $asset  declared=$hash actual=$actual"; fail=1
  fi
  if ! openssl x509 -in "$asset" -noout -checkend 31536000 >/dev/null; then
    echo "WARN  $asset expires within a year"; fail=1
  fi
  pins+=("$hash")
done < <(python3 - "$SRC" <<'PY'
import re, sys
t = open(sys.argv[1]).read()
for m in re.finditer(r"spkiSha256: '([^']+)',\s*assetPath: '([^']+)'", t):
    print(f"{m.group(1)}|{m.group(2)}")
PY
)

if [ "${1:-}" = "--live" ]; then
  shift
  for host in "$@"; do
    chain="$(echo | openssl s_client -connect "$host:443" -servername "$host" -showcerts 2>/dev/null)"
    tmp="$(mktemp -d)"
    printf '%s\n' "$chain" | python3 -c "
import re, sys
t = sys.stdin.read()
for i, m in enumerate(re.findall(r'-----BEGIN CERTIFICATE-----.*?-----END CERTIFICATE-----', t, re.S)):
    open('$tmp/c%d.pem' % i, 'w').write(m + '\n')
"
    found=0
    for c in "$tmp"/c*.pem; do
      h="$(spki < "$c")"
      for p in "${pins[@]}"; do [ "$h" = "$p" ] && found=1; done
    done
    if [ "$found" = 1 ]; then echo "LIVE OK    $host"; else echo "LIVE FAIL  $host: no pinned CA in served chain"; fail=1; fi
    rm -rf "$tmp"
  done
fi
exit $fail

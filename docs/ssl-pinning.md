# TLS pinning strategy

Adapted from the team's SSL pinning change summary (Mindoula, Android + iOS), applied to the Racketmates API. Hash and host values below were verified against the live servers on **2026-10-22**.

## Rules
1. **Pin the issuing CA public keys (SPKI SHA-256), never the leaf.** A connection is accepted when the validated chain ends at any pinned certificate. A normal renewal or reissue, even with a new leaf key, then needs no app release while the same CA issues it.
2. Each pinned environment has exactly three pins: primary intermediate, backup intermediate (different key type/CA path), root.
3. One shared pin set per CA family; the same values are used on Android and iOS (both go through the same Dart code).
4. Never ship the leaf certificate or a leaf hash.
5. Add the new CA pin and ship an app release **before** the server moves to that CA. Keep old pins until no supported app version depends on them.

## Racketmates hosts (live chains)
| Environment | Host | Chain |
|---|---|---|
| production | `api.racketmatesapp.com` | leaf > Sectigo DV R36 > Root R46 (cross-signed by USERTrust) |
| hotfix | `api-hotfix.racketmatesapp.com` | same |
| qa | `api-qa.racketmatesapp.com` | same |
| regression | `api-regression.racketmatesapp.com` | same |
| staging | `api-feature1.racketmatesapp.com` (native Feature1) | same |
| dev / local | not pinned (host unverified / plain http) | – |

Production leaf currently expires **2026-12-12**; a pin on the leaf would break at renewal.

## Pins (SPKI SHA-256, base64)
| Role | Certificate | SPKI SHA-256 | Valid to |
|---|---|---|---|
| 1. Primary intermediate | Sectigo Public Server Authentication CA DV R36 (RSA) | `a9khLOZJxlnJyrxstg/P+seiDCm+Yf3OsrXyFocBaI0=` | 2036 |
| 2. Backup intermediate | Sectigo Public Server Authentication CA DV E36 (ECC) | `ZSagvDzjltLkewXEBuDxIzpW/dpVw1Juvvmd0hhkzdY=` | 2036 |
| 3. Root | Sectigo Public Server Authentication Root R46 (RSA, self-signed) | `Douxi77vs4G+Ib/BogbTFymEYq0QSFXwSgVCaZcI09Q=` | 2046 |

The E36 backup is not served by any host; it comes from Sectigo's published certificate (`crt.sectigo.com`). The PEMs live in `assets/certs/` and the pin constants in `lib/common/network/ssl_pinning.dart`.

## How it is enforced in Flutter
Dart's `HttpClient` performs its own TLS and ignores Android `network_security_config.xml` pin-sets and iOS `NSPinnedDomains`. Dio's `validateCertificate` only sees the leaf and `badCertificateCallback` never fires for a validly signed certificate. So the API `Dio` uses a `SecurityContext(withTrustedRoots: false)` that trusts only the three pinned CA certificates: the handshake fails unless the chain ends at a pin. Only the Racketmates API client uses it; other hosts (status page, Sendbird, CDN) keep the system trust store.

Verified on the Dart VM (macOS): trusting only R36 succeeds, only R46 succeeds, only E36 fails against `api-qa`. **Not yet verified on Android and iOS devices**; the device negative test below is mandatory before release.

## Checks
```bash
tool/verify_ssl_pins.sh                                   # declared SPKI == bundled PEM, none expires within a year
tool/verify_ssl_pins.sh --live api.racketmatesapp.com api-qa.racketmatesapp.com   # served chain contains a pin
flutter test test/common/ssl_pinning_test.dart            # offline: intermediate-only, root-only, and wrong-CA rejection
```
`tool/verify_ssl_pins.sh` also runs in the Fastlane `quality` lane.

## Test plan before release
| # | Test | Expected |
|---|---|---|
| 1 | Production build: login | Succeeds, no SSL error |
| 2 | QA, hotfix, regression, staging builds: login | Succeeds |
| 3 | Negative: change one host's pins to a bogus pin set and rebuild | Requests to that host fail (Android `HandshakeException`; iOS `HandshakeException`/`NSURLErrorDomain -1200`); revert |
| 4 | Root-only check on the minimum OS (Android 13 / API 33, iOS 17): build with only the R46 pin for production | Succeeds, proving the root pin works on-device |
| 5 | Proxy with a MITM CA installed (Charles/mitmproxy) on a release build | Requests fail |

## Rotation
1. Read the live chain: `openssl s_client -connect <host>:443 -servername <host> -showcerts </dev/null`
2. Hash a CA certificate: `openssl x509 -in ca.pem -noout -pubkey | openssl pkey -pubin -outform der | openssl dgst -sha256 -binary | openssl enc -base64`
3. Add the new CA PEM to `assets/certs/` and its pin to `SectigoPins` (or a new pin set); run `tool/verify_ssl_pins.sh --live <hosts>`.
4. Ship an app release, then switch the server to the new CA.
5. Remove old pins only when no supported app version depends on them.

## Follow-ups for the infrastructure owners
- CAA records for `racketmatesapp.com` limiting issuance to Sectigo.
- Certificate Transparency monitoring for `*.racketmatesapp.com` / `api*.racketmatesapp.com`.
- Calendar reminders before the earliest pinned CA expiry (R36/E36: March 2036).
- Native apps (not changed by this work): both currently pin the **production leaf** (Android `fingerprint_one` SPKI; iOS bundled `racketmates.der`), which expires 2026-12-12. Renewal will break them unless they are updated or the certificate is reissued with the same key.

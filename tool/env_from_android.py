#!/usr/bin/env python3
"""Writes env/<env>.json from the native Android app's environment.xml.

  tool/env_from_android.py qa /path/to/racketmates-android

Needs the native repo checked out (read only). The output is git-ignored; the
values are never printed. Run it on your own machine only.
"""
import json
import re
import sys
from pathlib import Path

env, android = sys.argv[1], Path(sys.argv[2])
xml = (android / "app/src" / env / "res/values/environment.xml").read_text()


def value(name):
    m = re.search(r'<string name="%s"[^>]*>(.*?)</string>' % name, xml, re.S)
    return m.group(1).strip() if m else ""


out = {
    "API_BASE_URL": value("ace_api_base_url"),
    "API_VERSION": value("ace_api_version"),
    "OAUTH_CLIENT_ID": value("ace_client_id"),
    "OAUTH_CLIENT_SECRET": value("ace_client_secret"),
    "SENDBIRD_APP_ID": value("sendbird_app_id"),
    "STATUS_PAGE_ID": value("page_id"),
    "STATUS_PAGE_API_KEY": value("auth_key"),
    "STATUS_PAGE_COMPONENT": value("statuspage_api_component_name"),
}
target = Path(__file__).resolve().parent.parent / "env" / f"{env}.json"
target.write_text(json.dumps(out, indent=2) + "\n")
for k, v in out.items():
    print(f"{k:24} {'set' if v else 'MISSING'}")
print(f"wrote {target}")

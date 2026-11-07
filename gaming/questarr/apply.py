import json
import os
import re
import sys
import urllib.error
import urllib.request

BASE = os.environ.get("QUESTARR_URL", "http://localhost:5000").rstrip("/")
API_KEY = os.environ.get("QUESTARR_API_KEY", "")
CONFIG_PATH = os.environ.get("CONFIG_PATH", "/config/config.json")

CREATE_FIELDS = ("name", "type", "url", "username", "password", "enabled", "downloadPath", "label", "urlPath")
UPDATE_FIELDS = CREATE_FIELDS + ("priority", "category")


def interpolate(value):
    if isinstance(value, str):
        return re.sub(
            r"\$\{?([A-Za-z_][A-Za-z0-9_]*)\}?",
            lambda m: os.environ.get(m.group(1), ""),
            value,
        )
    if isinstance(value, list):
        return [interpolate(v) for v in value]
    if isinstance(value, dict):
        return {k: interpolate(v) for k, v in value.items()}
    return value


def request(method, path, body=None):
    data = json.dumps(body).encode() if body is not None else None
    req = urllib.request.Request(BASE + path, data=data, method=method)
    req.add_header("X-Api-Key", API_KEY)
    if data is not None:
        req.add_header("Content-Type", "application/json")
    try:
        with urllib.request.urlopen(req) as resp:
            raw = resp.read()
            return json.loads(raw) if raw else None
    except urllib.error.HTTPError as err:
        detail = err.read().decode(errors="replace")
        raise RuntimeError(f"{method} {path} failed: HTTP {err.code} {detail}") from err


def apply_prowlarr(cfg):
    body = {k: cfg[k] for k in ("url", "apiKey", "allowInsecureLan", "priority", "categories") if k in cfg}
    result = request("POST", "/api/indexers/prowlarr/sync", body)
    print("prowlarr sync:", result.get("message", result))


def apply_downloaders(desired_list):
    existing = {d["name"]: d for d in request("GET", "/api/downloaders")}
    for desired in desired_list:
        name = desired["name"]
        if name in existing:
            body = {k: desired[k] for k in UPDATE_FIELDS if k in desired}
            request("PATCH", f"/api/downloaders/{existing[name]['id']}", body)
            print("downloader updated:", name)
        else:
            create = {k: desired[k] for k in CREATE_FIELDS if k in desired}
            created = request("POST", "/api/downloaders", create)
            extra = {k: desired[k] for k in UPDATE_FIELDS if k in desired and k not in CREATE_FIELDS}
            if extra:
                request("PATCH", f"/api/downloaders/{created['id']}", extra)
            print("downloader created:", name)


def apply_imports(cfg):
    body = {k: cfg[k] for k in ("renamePattern",) if k in cfg}
    if body:
        request("PATCH", "/api/imports/config", body)
        print("import config updated")


def main():
    if not API_KEY:
        sys.exit("QUESTARR_API_KEY is not set")
    with open(CONFIG_PATH) as fh:
        config = interpolate(json.load(fh))
    if "prowlarr" in config:
        apply_prowlarr(config["prowlarr"])
    if config.get("downloaders"):
        apply_downloaders(config["downloaders"])
    if "imports" in config:
        apply_imports(config["imports"])


if __name__ == "__main__":
    try:
        main()
    except RuntimeError as err:
        sys.exit(str(err))

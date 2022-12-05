import json
import subprocess
import sys
from functools import cache
from pathlib import Path

import requests

CWD = Path(__file__).parent.parent.parent

SHA_FILE = CWD / "shas.json"


@cache
def last_update() -> str:
    """
    Returns a timestamp of the last update time, formatted for the
    If-Modified-Since header
    """
    # https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/If-Modified-Since
    git_args = [
        "git",
        "--no-pager",
        "log",
        "-1",
        "--quiet",
        "--date=format-local:%a, %d %b %Y %H:%M:%S %Z",
        "--format=%cd",
        str(SHA_FILE.absolute()),
    ]

    return subprocess.run(
        git_args,
        cwd=CWD,
        capture_output=True,
        check=True,
        env={
            "TZ": "GMT",
        },
    ).stdout.decode("utf-8")


def update_required(url: str) -> bool:
    resp = requests.head(
        url,
        allow_redirects=True,
        headers={
            "If-Modified-Since": last_update(),
        },
    )

    status = resp.status_code

    if status == 304:
        return False
    elif status == 200:
        return True
    else:
        msg = f"Unexpected status code {status}"
        print(f"=== {msg} ===", file=sys.stderr)
        print(resp.text, file=sys.stderr)
        raise RuntimeError(msg)


def push_updates() -> None:
    subprocess.run(
        ["git", "commit", "--message=updated checksums", str(SHA_FILE)], check=True
    )

    # subprocess.run(["git", "push"])


def prefetch_url(url: str) -> str:
    return subprocess.run(
        ["nix-prefetch-url", url],
        capture_output=True,
        check=True,
    ).stdout.decode("utf-8")


def main():
    with open(SHA_FILE) as f:
        sha_data = json.load(f)

    updated = []

    for font, data in sha_data.items():
        url = data["url"]
        if not update_required(url):
            continue

        sha_data[font]["sha256"] = prefetch_url(url)
        updated.append(font)

    if not updated:
        print("No modifications made", file=sys.stderr)
        return

    with open(SHA_FILE, 'w') as f:
        json.dump(sha_data, f, indent=2)

    names_updated = ", ".join(updated)
    print(f"Updated {names_updated}", file=sys.stderr)


if __name__ == "__main__":
    main()

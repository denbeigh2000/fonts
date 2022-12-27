#!/usr/bin/env python3

import json
import shutil
import subprocess
import sys
from functools import cache
from pathlib import Path

import requests


def get_git() -> str:
    return shutil.which("git")


GIT_BIN = get_git()


def get_repo_dir() -> Path:
    # NOTE: We explicitly _avoid_ using __file__ here, because that doesn't
    # reflect our git repo when this is being run from the Nix store.
    raw = subprocess.run(
        [GIT_BIN, "rev-parse", "--show-toplevel"],
        capture_output=True,
        check=True,
    ).stdout.decode("utf-8").strip()

    return Path(raw)


REPO_DIR = get_repo_dir()

SHA_FILE = REPO_DIR / "shas.json"

GIT_CMD = [GIT_BIN, "-C", str(REPO_DIR), "--no-pager" ]

def pre_check():
    try:
        subprocess.call(GIT_CMD + ["checkout", "master"], check=True)
        subprocess.call(GIT_CMD + ["fetch", "origin", "master"], check=True)
        subprocess.call(GIT_CMD + ["reset", "origin/master"], check=True)

    except subprocess.CalledProcessError:
        print("Error initialising repository state", file=sys.stderr)
        raise


@cache
def last_update() -> str:
    """
    Returns a timestamp of the last update time, formatted for the
    If-Modified-Since header
    """
    # https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/If-Modified-Since
    git_args = GIT_CMD + [
        "log",
        "-1",
        "--quiet",
        "--date=format-local:%a, %d %b %Y %H:%M:%S %Z",
        "--format=%cd",
        str(SHA_FILE.absolute()),
    ]

    return subprocess.run(
        git_args,
        cwd=REPO_DIR,
        capture_output=True,
        check=True,
        env={
            "TZ": "GMT",
        },
    ).stdout.decode("utf-8").strip()


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
        GIT_CMD + ["commit", "--message=updated checksums", str(SHA_FILE)], check=True
    )

    subprocess.run(GIT_CMD + ["push", "origin", "master"])


def prefetch_url(url: str) -> str:
    return subprocess.run(
        ["nix", "store", "prefetch-file", url],
        capture_output=True,
        check=True,
    ).stdout.decode("utf-8").strip()


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

    with open(SHA_FILE, "w") as f:
        json.dump(sha_data, f, indent=2)

    names_updated = ", ".join(updated)
    print(f"Updated {names_updated}", file=sys.stderr)


if __name__ == "__main__":
    main()

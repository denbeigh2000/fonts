#!/usr/bin/env python3

import json
import os
import shutil
import subprocess
import sys
from functools import cache
from pathlib import Path
from typing import Dict, Optional, Sequence

import requests


def which(cmd: str) -> str:
    cmd_bin = shutil.which(cmd)
    assert cmd_bin is not None, f"no {cmd} command"
    return cmd_bin


GIT_BIN = which("git")
SSH_BIN = which("ssh")


@cache
def get_env() -> Dict[str, str]:
    # Don't validate our key, and don't try to update ones we know about.
    cmd = f"{SSH_BIN} -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"
    ssh_key = os.environ.get("FONT_SSH_KEY")
    if ssh_key:
        assert Path(ssh_key).is_absolute()
        cmd += f" -i {ssh_key}"

    env = os.environ.copy()
    env.update({"GIT_SSH_COMMAND": cmd})

    return env


def prep_given_dir() -> Optional[Path]:
    given_dir_str = os.environ.get("FONT_CHECKOUT_DIR")
    if not given_dir_str:
        return None

    given_dir = Path(given_dir_str)
    if (given_dir / ".git").exists():
        return given_dir

    # Clone our directory if it doesn't exist
    subprocess.run(
        [GIT_BIN, "clone", "git@github.com:denbeigh2000/fonts.git", given_dir],
        check=True,
        env=get_env(),
    )
    return given_dir


def get_repo_dir() -> Path:
    given_dir = prep_given_dir()
    if given_dir:
        return given_dir

    # NOTE: We explicitly _avoid_ using __file__ here, because that doesn't
    # reflect our git repo when this is being run from the Nix store.
    raw = (
        subprocess.run(
            [GIT_BIN, "rev-parse", "--show-toplevel"],
            capture_output=True,
            check=True,
        )
        .stdout.decode("utf-8")
        .strip()
    )

    return Path(raw)


REPO_DIR = get_repo_dir()

SHA_FILE = REPO_DIR / "shas.json"

GIT_CMD = [GIT_BIN, "-C", str(REPO_DIR), "--no-pager"]


def pre_check():
    try:
        subprocess.run(GIT_CMD + ["checkout", "master"], check=True)
        subprocess.run(GIT_CMD + ["fetch", "origin", "master"], check=True)
        subprocess.run(GIT_CMD + ["reset", "origin/master"], check=True)

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

    return (
        subprocess.run(
            git_args,
            cwd=REPO_DIR,
            capture_output=True,
            check=True,
            env={
                "TZ": "GMT",
            },
        )
        .stdout.decode("utf-8")
        .strip()
    )


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
        GIT_CMD
        + [
            "-c",
            "user.name=Denbeigh Bot",
            "-c",
            "user.email=bot@denbeigh.cloud",
            "commit",
            "--message=updated checksums",
            str(SHA_FILE),
        ],
        check=True,
    )

    subprocess.run(GIT_CMD + ["push", "origin", "master"], env=get_env(), check=True)


def prefetch_url(url: str) -> str:
    data = (
        subprocess.run(
            ["nix", "store", "prefetch-file", "--json", url],
            capture_output=True,
            check=True,
        )
        .stdout.decode("utf-8")
        .strip()
    )

    return json.loads(data)["hash"]


def main():
    pre_check()

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

    push_updates()


if __name__ == "__main__":
    main()

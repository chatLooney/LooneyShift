#!/usr/bin/env python3
"""Fetch the unchanged upstream iPhone library and verify its pinned hash."""
from pathlib import Path
import hashlib
import urllib.request

ROOT = Path(__file__).resolve().parent.parent
TARGET = ROOT / "StikDebug/idevice/libidevice_ffi.a"
URL = "https://raw.githubusercontent.com/StikDebug/StikDebug/17b1e1d90d602a228de663a10efa987a9f9e547b/StikDebug/idevice/libidevice_ffi.a"
SHA256 = "4db23fe1d342927b9480bb9a8577f219994365621dc28aa0018e23ea1990ecc8"

def digest(path):
    with path.open("rb") as stream:
        return hashlib.file_digest(stream, "sha256").hexdigest()

HEADER = ROOT / "StikDebug/idevice/idevice.h"
HEADER_URL = URL.rsplit("/", 1)[0] + "/idevice.h"
HEADER_SHA256 = "696286794e8cf1c18a91d4dab5046cef4d9bae352f5e7a1ad33fbc0ba30d7ab4"
if not HEADER.exists() or digest(HEADER) != HEADER_SHA256:
    header_pending = HEADER.with_suffix(".download")
    try:
        urllib.request.urlretrieve(HEADER_URL, header_pending)
        if digest(header_pending) != HEADER_SHA256:
            raise RuntimeError("idevice header hash mismatch")
        header_pending.replace(HEADER)
    finally:
        header_pending.unlink(missing_ok=True)

if TARGET.exists() and digest(TARGET) == SHA256:
    print("idevice library verified")
else:
    pending = TARGET.with_suffix(".download")
    try:
        urllib.request.urlretrieve(URL, pending)
        if digest(pending) != SHA256:
            raise RuntimeError("idevice library hash mismatch")
        pending.replace(TARGET)
        print("idevice library downloaded and verified")
    finally:
        pending.unlink(missing_ok=True)

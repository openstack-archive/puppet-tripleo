#!/usr/bin/env python3
import hashlib
import base64
import sys

from nacl.bindings.crypto_scalarmult import \
     crypto_scalarmult_ed25519_base_noclamp

# https://github.com/MariaDB/server/blob/10.4/plugin/auth_ed25519/ref10/sign.c
# mariadb's use of ed25519:
#  . password is the secret seed
#  . ed25519's public key (computed from password) is what is stored in mariadb
#  . the hash in mariadb is the base64 encoding of the pk minus the last '='


def _scalar_clamp(s32):
    ba = bytearray(s32)
    ba0 = bytes(bytearray([ba[0] & 248]))
    ba31 = bytes(bytearray([(ba[31] & 127) | 64]))
    return ba0 + bytes(s32[1:31]) + ba31


def mysql_ed25519_password(pwd):
    # h = SHA512(password)
    h = hashlib.sha512(pwd).digest()
    # s = prune(first_half(h))
    s = _scalar_clamp(h[:32])
    # A = encoded point [s]B
    A = crypto_scalarmult_ed25519_base_noclamp(s)
    # encoded pk
    encoded = base64.b64encode(A)[:-1]
    return encoded


if __name__ == "__main__":
    if len(sys.argv) <= 1:
        print("Usage: %s PASSWORD" % sys.argv[0], file=sys.stderr)
        sys.exit(1)
    else:
        pwd = sys.argv[1].encode()
        res = mysql_ed25519_password(pwd)
        print(res.decode(), end='')

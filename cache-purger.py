import os
import json
import shutil
import socket
import sys
from hashlib import md5
from http import HTTPStatus
from http.server import BaseHTTPRequestHandler, HTTPServer


CACHE_DIR = "/mnt/cache"


class CachePurgeException(Exception):
    pass


class HTTPServerIPv6(HTTPServer):
    address_family = socket.AF_INET6


class handler(BaseHTTPRequestHandler):
    def do_POST(self) -> None:
        try:
            check_headers(self.headers)
            content_length = int(self.headers.get("Content-Length", "0"))
            if content_length == 0:
                purgeEverything()
                self.send_response(HTTPStatus.OK, "Purge succeeded")
            else:
                body = self.rfile.read(content_length)
                keys = json.loads(body)
                if isinstance(keys, list):
                    purge(keys)
                    self.send_response(HTTPStatus.OK, "Purge succeeded")
                else:
                    self.send_error(
                        HTTPStatus.BAD_REQUEST, "Missing array of keys to purge"
                    )
        except CachePurgeException as e:
            self.send_response(HTTPStatus.BAD_REQUEST, str(e))
        except json.JSONDecodeError:
            self.send_error(HTTPStatus.BAD_REQUEST, "Invalid JSON")
        self.end_headers()


def check_headers(headers) -> None:
    if "Content-Type" not in headers:
        raise CachePurgeException("Missing Content-Type header")
    if not headers.get("Content-Type") == "application/json":
        raise CachePurgeException("Invalid Content-Type header")
    if "Content-Length" not in headers:
        raise CachePurgeException("Missing Content-Length header")
    try:
        int(headers.get("Content-Length"))
    except ValueError as e:
        raise CachePurgeException("Invalid Content-Length header") from e


def purge(keys: list[str]) -> None:
    for key in keys:
        filename = md5(key.encode("utf-8")).hexdigest()
        path = os.path.join(  # because nginx cache_path levels=1:2
            CACHE_DIR, filename[-1], filename[-3:-1], filename
        )
        try:
            if os.path.isfile(path):
                os.remove(path)
                log(f"Purged {key}")
        except OSError as e:
            log(f"Failed to purge {key}: {e}")
            raise CachePurgeException("Purge failed") from e


def purgeEverything() -> None:
    for filename in os.listdir(CACHE_DIR):
        if filename == "lost+found":
            continue
        file_path = os.path.join(CACHE_DIR, filename)
        try:
            if os.path.isfile(file_path) or os.path.islink(file_path):
                os.unlink(file_path)
            elif os.path.isdir(file_path):
                shutil.rmtree(file_path)
        except Exception as e:
            log(f"Failed to purge entire cache: {e}")
            raise CachePurgeException("Purge failed") from e


def log(message: str) -> None:
    print(message, file=sys.stderr)


def main() -> None:
    with HTTPServerIPv6(("::", 8081), handler) as server:
        server.serve_forever()


if __name__ == "__main__":
    main()

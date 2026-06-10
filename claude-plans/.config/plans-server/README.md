# Intent

This package installs a local plan site at http://plans.claude:

- A per-user MkDocs (Material) dev server renders `~/plans/src/*.md` with live-reload on save.
- A Caddy system service binds 127.0.0.2:80 and reverse-proxies to the MkDocs server.

Authoring vocabulary for documents lives in `AUTHORING.md`. Setup via `make install`.

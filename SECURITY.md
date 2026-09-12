# Security

## Reporting a vulnerability

Please **do not open a public issue** for a security problem.

Email **security@goya24.com** with what you found, how to reproduce it, and what you think the impact is. You will get an acknowledgement within two working days and a fix or a plan within a week for anything confirmed.

## What is in scope

- This package: the address it loads, what it passes to the page, the channel it listens on, and what it does with links.

The messenger itself, the goya24 API and goya24.com are covered by the same address but are not in this repository.

## What the package does and does not do

- It loads one page from the configured origin (goya24.com unless set otherwise) in a WebView, with the workspace key and the signed-in user's id, name, email and the hash of the id in the query. The identity secret is never in the app — the hash comes from your server.
- It listens on one JavaScript channel, `Goya24Host`, and acts only on messages of the messenger's own shape; anything else is ignored.
- It follows navigation only on the messenger's own origin. A link anywhere else is handed to the app through `onOpenLink` and not loaded.
- It makes no network requests of its own.

## Supported versions

The latest release receives security fixes.

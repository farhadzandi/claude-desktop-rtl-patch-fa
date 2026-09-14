# Roadmap

## Current release: v1.3.2

Supported target:

- Claude Desktop for Windows

Current priorities:

- Keep compatibility with Claude Desktop updates.
- Expand Persian mixed-direction test coverage.
- Reduce remaining runtime supply-chain dependency on `npx`.
- Improve release signing / provenance for public GitHub artifacts.

## Deferred: ChatGPT Desktop / Codex

Not supported in v1.3.2.

A read-only inspection of the currently installed Windows Codex package showed an Electron `app.asar`,
but Claude's executable hash/certificate path cannot be safely assumed to apply to OpenAI's app.

Future support requires:

1. A separate target adapter.
2. Target-specific integrity/signature analysis.
3. Independent backup/rollback tests.
4. ACL snapshot/restore tests.
5. No reuse of Claude's `cowork-svc.exe` certificate logic.

Until those conditions are met, the public menu will not advertise Codex/ChatGPT Desktop support.

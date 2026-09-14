# Contributing

Contributions are welcome.

## Ground rules

- Preserve the upstream MIT license and attribution to `shraga100`.
- Keep the secure build free of scheduled persistence and remote self-updaters.
- Do not add broad recursive `takeown /R` or `icacls /T` access to application package trees.
- Fail closed when Claude's integrity layout is not recognized.
- Preserve rollback paths and post-change verification.
- Add/update Node tests for RTL-engine changes.
- Use Windows PowerShell 5.1 compatibility for public patch scripts.

## Pull requests

Please include:

- What changed and why.
- Claude Desktop version(s) tested.
- Windows version tested.
- `npm test` result.
- Any security/ACL/certificate impact.
- Rollback behavior.

## Other desktop apps

Codex/ChatGPT Desktop support must use a separate target adapter. Do not reuse Claude's
`cowork-svc.exe` certificate path without independent evidence and tests.

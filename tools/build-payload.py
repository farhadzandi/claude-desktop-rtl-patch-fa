#!/usr/bin/env python3
"""Assemble the renderer RTL payload from src/ and inject it into patch.ps1.

A faithful port of tools/build-payload.ps1 for environments without PowerShell
(Linux/macOS CI, WSL). Same contract, same output bytes:

  1. read src/rtl-core.js, strip its module.exports guard
  2. inline it into src/rtl-payload.js at the /*__RTL_CORE__*/ marker
  3. validate the assembled blob with `node --check`
  4. replace the region between the CLAUDE RTL PATCH START/END markers in patch.ps1
  5. write patch.ps1 back as UTF-8 WITH a BOM, LF line endings

Difference from the upstream .ps1 build tool: patch.ps1 is written WITH a BOM.
Upstream keeps it BOM-less because their install.ps1 adds the BOM itself before
running the file; this build is meant to be run straight from disk, and without a
BOM PowerShell 5.1 reads it in the system ANSI code page -- which mangles the few
box-drawing characters in the menu and can stop the script from parsing at all on
a non-UTF-8 locale such as Persian Windows.

After running this you MUST re-sign with tools/sign-release.ps1 if you publish it.
"""
import io
import os
import re
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CORE = os.path.join(ROOT, 'src', 'rtl-core.js')
PAY = os.path.join(ROOT, 'src', 'rtl-payload.js')
PATCH = os.path.join(ROOT, 'patch.ps1')
MARKER = '/*__RTL_CORE__*/'


def read_lf(path):
    # utf-8-sig: transparently drops a BOM if present, so the text we work with is
    # BOM-free regardless of how the file is stored.
    with io.open(path, encoding='utf-8-sig') as fh:
        return fh.read().replace('\r\n', '\n')


def fail(msg):
    print('ERROR: ' + msg, file=sys.stderr)
    sys.exit(1)


def main():
    for p in (CORE, PAY, PATCH):
        if not os.path.exists(p):
            fail('missing: ' + p)

    core = read_lf(CORE)
    guard = core.find('if (typeof module !==')
    if guard >= 0:
        core = core[:guard].rstrip() + '\n'

    pay = read_lf(PAY)
    if MARKER not in pay:
        fail('placeholder %s not found in rtl-payload.js' % MARKER)
    inlined = pay.replace(MARKER, core.rstrip('\n'))

    # The assembled payload is spliced into a BOM-less patch.ps1 that PowerShell 5.1
    # reads with the system ANSI code page. Any non-ASCII byte in the JS corrupts and
    # breaks parsing on a Persian/Hebrew locale -- use \u escapes instead.
    non_ascii = [i + 1 for i, line in enumerate(inlined.split('\n'))
                 if any(ord(c) > 127 for c in line)]
    if non_ascii:
        fail('non-ASCII characters in the payload at line(s): %s' % non_ascii)

    tmp = os.path.join(ROOT, '.payload-check.tmp.js')
    with io.open(tmp, 'w', encoding='utf-8', newline='\n') as fh:
        fh.write(inlined)
    rc = subprocess.call(['node', '--check', tmp])
    os.remove(tmp)
    if rc != 0:
        fail('node --check failed - aborting, patch.ps1 untouched.')

    block = ('// --- CLAUDE RTL PATCH START ---\n' + inlined.rstrip('\n') +
             '\n// --- CLAUDE RTL PATCH END ---')

    patch = read_lf(PATCH)
    pattern = re.compile(
        r'// --- CLAUDE RTL PATCH START ---.*?// --- CLAUDE RTL PATCH END ---',
        re.S)
    if not pattern.search(patch):
        fail('RTL PATCH markers not found in patch.ps1')
    updated = pattern.sub(lambda m: block, patch, count=1)

    if len(updated) < len(patch) / 2:
        fail('SANITY FAIL: assembled file too short (%d chars)' % len(updated))

    if updated == patch:
        print('Payload unchanged - patch.ps1 already up to date.')
        return

    with io.open(PATCH, 'w', encoding='utf-8-sig', newline='\n') as fh:
        fh.write(updated)
    print('Injected payload into patch.ps1 (block %d chars; file now %d bytes).'
          % (len(block), os.path.getsize(PATCH)))


if __name__ == '__main__':
    main()

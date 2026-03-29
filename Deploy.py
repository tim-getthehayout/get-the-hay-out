#!/usr/bin/env python3
"""
deploy.py — Get The Hay Out build stamp utility
Run before every git push. Stamps index.html and ARCHITECTURE.md with a
matching UTC build stamp, then prints a suggested commit message.
"""

import re
import sys
from datetime import datetime, timezone

HTML_FILE  = 'index.html'
ARCH_FILE  = 'ARCHITECTURE.md'

def make_stamp():
    return 'b' + datetime.now(timezone.utc).strftime('%Y%m%d.%H%M')

def stamp_html(stamp):
    with open(HTML_FILE, 'r', encoding='utf-8') as f:
        content = f.read()
    updated = re.sub(
        r'(<meta name="app-version" content=")[^"]*(")',
        rf'\g<1>{stamp}\2',
        content
    )
    if updated == content:
        print(f'⚠️  Could not find app-version meta tag in {HTML_FILE}')
        sys.exit(1)
    with open(HTML_FILE, 'w', encoding='utf-8') as f:
        f.write(updated)
    print(f'✅ {HTML_FILE} stamped → {stamp}')

def stamp_arch(stamp):
    with open(ARCH_FILE, 'r', encoding='utf-8') as f:
        content = f.read()
    updated = re.sub(
        r'(\*\*Current build:\*\*\s*)`[^`]*`',
        rf'\g<1>`{stamp}`',
        content
    )
    if updated == content:
        print(f'⚠️  Could not find **Current build:** line in {ARCH_FILE}')
        sys.exit(1)
    with open(ARCH_FILE, 'w', encoding='utf-8') as f:
        f.write(updated)
    print(f'✅ {ARCH_FILE} stamped → {stamp}')

if __name__ == '__main__':
    stamp = make_stamp()
    stamp_html(stamp)
    stamp_arch(stamp)
    print()
    print(f'Suggested commit message:')
    print(f'  {stamp}: <describe what changed>')
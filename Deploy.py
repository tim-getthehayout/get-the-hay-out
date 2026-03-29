{\rtf1\ansi\ansicpg1252\cocoartf2868
\cocoatextscaling0\cocoaplatform0{\fonttbl\f0\fswiss\fcharset0 Helvetica;}
{\colortbl;\red255\green255\blue255;}
{\*\expandedcolortbl;;}
\margl1440\margr1440\vieww11520\viewh8400\viewkind0
\pard\tx720\tx1440\tx2160\tx2880\tx3600\tx4320\tx5040\tx5760\tx6480\tx7200\tx7920\tx8640\pardirnatural\partightenfactor0

\f0\fs24 \cf0 #!/usr/bin/env python3\
"""\
deploy.py \'97 Pre-push helper for Get The Hay Out\
Run this at the end of every session before git push.\
Stamps index.html and ARCHITECTURE.md with current UTC time.\
"""\
import re, sys\
from datetime import datetime, timezone\
\
HTML_FILE   = 'index.html'\
ARCH_FILE   = 'ARCHITECTURE.md'\
\
# Generate build stamp from current UTC time\
stamp = 'b' + datetime.now(timezone.utc).strftime('%Y%m%d.%H%M')\
\
# --- Update HTML build stamp ---\
with open(HTML_FILE, 'r', encoding='utf-8') as f:\
    html = f.read()\
\
updated_html, n = re.subn(\
    r'(app-version" content=")b\\d\{8\}\\.\\d\{4\}',\
    r'\\g<1>' + stamp,\
    html\
)\
if n == 0:\
    print('ERROR: Could not find app-version meta tag in index.html.')\
    sys.exit(1)\
\
with open(HTML_FILE, 'w', encoding='utf-8') as f:\
    f.write(updated_html)\
print(f'index.html stamped:   \{stamp\}')\
\
# --- Update ARCHITECTURE.md stamp ---\
with open(ARCH_FILE, 'r', encoding='utf-8') as f:\
    arch = f.read()\
\
updated_arch, n = re.subn(\
    r'\\*\\*Current build:\\*\\* `b\\d\{8\}\\.\\d\{4\}`',\
    f'**Current build:** `\{stamp\}`',\
    arch\
)\
if n == 0:\
    print('WARNING: Could not find current build line in ARCHITECTURE.md.')\
    print('Update it manually before pushing.')\
else:\
    with open(ARCH_FILE, 'w', encoding='utf-8') as f:\
        f.write(updated_arch)\
    print(f'ARCHITECTURE stamped: \{stamp\}')\
\
print()\
print('Suggested commit message:')\
print(f'  \{stamp\}: <describe what changed>')\
print()\
print('Now run:')\
print('  git add -A')\
print(f'  git commit -m "\{stamp\}: your description here"')\
print('  git push')}
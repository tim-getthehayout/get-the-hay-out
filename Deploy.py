#!/usr/bin/env python3
"""
deploy.py — Get The Hay Out build & release utility

Usage:
  python3 deploy.py              Stamp files with current UTC build number
  python3 deploy.py deploy       Stamp, commit, merge dev → main, push (goes live)
  python3 deploy.py release      Stamp, commit, merge dev → main, push, tag + release
"""

import re
import sys
import subprocess
from datetime import datetime, timezone

HTML_FILE = 'index.html'
ARCH_FILE = 'ARCHITECTURE.md'


def run(cmd, check=True):
    """Run a shell command and return stdout."""
    result = subprocess.run(cmd, shell=True, capture_output=True, text=True)
    if check and result.returncode != 0:
        print(f'Error running: {cmd}')
        print(result.stderr.strip())
        sys.exit(1)
    return result.stdout.strip()


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
        print(f'Could not find app-version meta tag in {HTML_FILE}')
        sys.exit(1)
    with open(HTML_FILE, 'w', encoding='utf-8') as f:
        f.write(updated)
    print(f'  {HTML_FILE} stamped -> {stamp}')


def stamp_arch(stamp):
    with open(ARCH_FILE, 'r', encoding='utf-8') as f:
        content = f.read()
    updated = re.sub(
        r'(\*\*Current build:\*\*\s*)`[^`]*`',
        rf'\g<1>`{stamp}`',
        content
    )
    if updated == content:
        print(f'Could not find **Current build:** line in {ARCH_FILE}')
        sys.exit(1)
    with open(ARCH_FILE, 'w', encoding='utf-8') as f:
        f.write(updated)
    print(f'  {ARCH_FILE} stamped -> {stamp}')


def current_branch():
    return run('git rev-parse --abbrev-ref HEAD')


def has_changes():
    status = run('git status --porcelain')
    return len(status) > 0


def stamp_only(stamp):
    """Mode 1: Just stamp the files (default)."""
    print(f'\nStamping build: {stamp}')
    stamp_html(stamp)
    stamp_arch(stamp)
    print(f'\nDone. Commit when ready:')
    print(f'  git add -A && git commit -m "{stamp}"')


def deploy(stamp):
    """Mode 2: Stamp, commit on dev, merge to main, push."""
    branch = current_branch()
    if branch == 'main':
        print('Already on main. Switch to dev first:')
        print('  git checkout dev')
        sys.exit(1)

    print(f'\nDeploying build: {stamp}')
    stamp_html(stamp)
    stamp_arch(stamp)

    # Commit any pending changes on dev
    if has_changes():
        run('git add -A')
        run(f'git commit -m "{stamp}"')
        print(f'  Committed on {branch}')

    # Merge to main and push
    run('git checkout main')
    run(f'git merge {branch} --no-ff -m "Deploy {stamp}"')
    run('git push origin main')
    print(f'  Pushed to main — live on GitHub Pages')

    # Return to dev
    run(f'git checkout {branch}')
    print(f'  Back on {branch}')
    print(f'\nDeployed: {stamp}')


def release(stamp):
    """Mode 3: Deploy + create a git tag."""
    branch = current_branch()
    if branch == 'main':
        print('Already on main. Switch to dev first:')
        print('  git checkout dev')
        sys.exit(1)

    print(f'\nReleasing build: {stamp}')
    stamp_html(stamp)
    stamp_arch(stamp)

    # Commit any pending changes on dev
    if has_changes():
        run('git add -A')
        run(f'git commit -m "{stamp}"')
        print(f'  Committed on {branch}')

    # Merge to main
    run('git checkout main')
    run(f'git merge {branch} --no-ff -m "Release {stamp}"')

    # Tag
    run(f'git tag -a {stamp} -m "Release {stamp}"')
    print(f'  Tagged: {stamp}')

    # Push main + tag
    run('git push origin main')
    run(f'git push origin {stamp}')
    print(f'  Pushed to main + tag — live on GitHub Pages')

    # Check for gh CLI for GitHub Release
    gh_check = subprocess.run('which gh', shell=True, capture_output=True)
    if gh_check.returncode == 0:
        print(f'\n  Creating GitHub Release...')
        notes = input('  Release notes (one line, or Enter to skip): ').strip()
        if notes:
            run(f'gh release create {stamp} --title "{stamp}" --notes "{notes}"')
            print(f'  GitHub Release created: {stamp}')
        else:
            run(f'gh release create {stamp} --title "{stamp}" --generate-notes')
            print(f'  GitHub Release created with auto-generated notes')
    else:
        print(f'\n  Tip: Install gh CLI (brew install gh) to auto-create GitHub Releases')
        print(f'  For now, create one manually at:')
        print(f'  https://github.com/timjoseph/get-the-hay-out/releases/new?tag={stamp}')

    # Return to dev
    run(f'git checkout {branch}')
    print(f'  Back on {branch}')
    print(f'\nReleased: {stamp}')


if __name__ == '__main__':
    stamp = make_stamp()
    mode = sys.argv[1] if len(sys.argv) > 1 else 'stamp'

    if mode == 'stamp':
        stamp_only(stamp)
    elif mode == 'deploy':
        deploy(stamp)
    elif mode == 'release':
        release(stamp)
    else:
        print(f'Unknown mode: {mode}')
        print('Usage: python3 deploy.py [stamp|deploy|release]')
        sys.exit(1)

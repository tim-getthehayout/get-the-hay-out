#!/bin/bash

# Get The Hay Out — One-click deploy
# Double-click this file to push a new build to GitHub
# Downloads folder: ~/Desktop/GTHY-Deliverables/

# ── Paths ──────────────────────────────────────────
REPO="$HOME/Github/get-the-hay-out"
DOWNLOADS="$HOME/Desktop/GTHY-Deliverables"
# ───────────────────────────────────────────────────

cd "$REPO" || { echo "❌ Could not find repo at $REPO"; read -p "Press Enter to close..."; exit 1; }

echo ""
echo "┌─────────────────────────────────────┐"
echo "│       Get The Hay Out — Deploy      │"
echo "└─────────────────────────────────────┘"
echo ""

# ── Step 1: Find deliverables ───────────────────────

if [ ! -d "$DOWNLOADS" ]; then
  echo "❌ Deliverables folder not found at $DOWNLOADS"
  echo "   Create it and drop your Claude.ai downloads there first."
  read -p "Press Enter to close..."
  exit 1
fi

# Find latest stamped HTML
HTML_SRC=$(ls "$DOWNLOADS"/get-the-hay-out_b*.html 2>/dev/null | sort | tail -1)
ARCH_SRC=$(ls "$DOWNLOADS"/ARCHITECTURE_b*.md 2>/dev/null | sort | tail -1)
OI_SRC=$(ls "$DOWNLOADS"/OPEN_ITEMS_b*.md 2>/dev/null | sort | tail -1)
CL_SRC=$(ls "$DOWNLOADS"/PROJECT_CHANGELOG_b*.md 2>/dev/null | sort | tail -1)
MT_SRC=$(ls "$DOWNLOADS"/MASTER_TEMPLATE_v*.md 2>/dev/null | sort | tail -1)
SR_SRC=$(ls "$DOWNLOADS"/SESSION_RULES.md 2>/dev/null | tail -1)

# Extract build stamp from HTML filename
if [ -n "$HTML_SRC" ]; then
  STAMP=$(basename "$HTML_SRC" | grep -o 'b[0-9]*\.[0-9]*')
else
  STAMP="(no HTML found)"
fi

# ── Step 2: Show what was found ─────────────────────

echo "Found in $DOWNLOADS:"
echo ""
[ -n "$HTML_SRC" ]  && echo "  ✅ $(basename $HTML_SRC)" || echo "  ⚠️  No HTML file found"
[ -n "$ARCH_SRC" ]  && echo "  ✅ $(basename $ARCH_SRC)" || echo "  ⚠️  No ARCHITECTURE found"
[ -n "$OI_SRC" ]    && echo "  ✅ $(basename $OI_SRC)"   || echo "  ⚠️  No OPEN_ITEMS found"
[ -n "$CL_SRC" ]    && echo "  ✅ $(basename $CL_SRC)"   || echo "  ⚠️  No PROJECT_CHANGELOG found"
[ -n "$MT_SRC" ]    && echo "  ✅ $(basename $MT_SRC)"   || echo "  ℹ️  No MASTER_TEMPLATE (optional)"
[ -n "$SR_SRC" ]    && echo "  ✅ SESSION_RULES.md"      || echo "  ℹ️  No SESSION_RULES (optional)"
echo ""
echo "  Build stamp: $STAMP"
echo ""

# ── Step 3: Confirm ─────────────────────────────────

read -p "Proceed with this build? (y/n): " CONFIRM
if [ "$CONFIRM" != "y" ] && [ "$CONFIRM" != "Y" ]; then
  echo "❌ Cancelled."
  read -p "Press Enter to close..."
  exit 1
fi

# Require at minimum the HTML file
if [ -z "$HTML_SRC" ]; then
  echo "❌ Cannot proceed — no HTML file found in $DOWNLOADS"
  read -p "Press Enter to close..."
  exit 1
fi

echo ""

# ── Step 4: Copy and rename into repo ───────────────

echo "▶ Copying files into repo..."
cp "$HTML_SRC"  "$REPO/index.html"    && echo "  index.html"
[ -n "$ARCH_SRC" ] && cp "$ARCH_SRC" "$REPO/ARCHITECTURE.md"       && echo "  ARCHITECTURE.md"
[ -n "$OI_SRC" ]   && cp "$OI_SRC"   "$REPO/OPEN_ITEMS.md"         && echo "  OPEN_ITEMS.md"
[ -n "$CL_SRC" ]   && cp "$CL_SRC"   "$REPO/PROJECT_CHANGELOG.md"  && echo "  PROJECT_CHANGELOG.md"
[ -n "$MT_SRC" ]   && cp "$MT_SRC"   "$REPO/MASTER_TEMPLATE.md"    && echo "  MASTER_TEMPLATE.md"
[ -n "$SR_SRC" ]   && cp "$SR_SRC"   "$REPO/SESSION_RULES.md"      && echo "  SESSION_RULES.md"

# ── Step 5: Commit message ──────────────────────────

echo ""
read -p "Commit message: " MSG

if [ -z "$MSG" ]; then
  echo "❌ No message entered — deploy cancelled."
  read -p "Press Enter to close..."
  exit 1
fi

# ── Step 6: Deploy ──────────────────────────────────

echo ""
echo "▶ Running deploy.py..."
python3 deploy.py || { echo "❌ deploy.py failed"; read -p "Press Enter to close..."; exit 1; }

echo "▶ Staging files..."
git add -A

echo "▶ Committing..."
git commit -m "$MSG"

echo "▶ Pushing to GitHub..."
git push && echo "" && echo "✅ Done — check Actions at github.com for deploy status." || echo "❌ Push failed — check your internet connection or token."

# ── Step 7: Clear deliverables folder ───────────────

echo ""
read -p "Clear the GTHY-Deliverables folder? (y/n): " CLEAR
if [ "$CLEAR" = "y" ] || [ "$CLEAR" = "Y" ]; then
  rm "$DOWNLOADS"/get-the-hay-out_b*.html 2>/dev/null
  rm "$DOWNLOADS"/ARCHITECTURE_b*.md 2>/dev/null
  rm "$DOWNLOADS"/OPEN_ITEMS_b*.md 2>/dev/null
  rm "$DOWNLOADS"/PROJECT_CHANGELOG_b*.md 2>/dev/null
  rm "$DOWNLOADS"/MASTER_TEMPLATE_v*.md 2>/dev/null
  rm "$DOWNLOADS"/SESSION_RULES.md 2>/dev/null
  echo "✅ Deliverables folder cleared."
fi

echo ""
read -p "Press Enter to close..."

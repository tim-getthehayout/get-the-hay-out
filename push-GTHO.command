#!/bin/bash

# Get The Hay Out — One-click deploy
# Double-click this file to push a new build to GitHub

# ── Change this to your actual repo path ──
REPO="$HOME/github/get-the-hay-out"
# ──────────────────────────────────────────

cd "$REPO" || { echo "❌ Could not find repo at $REPO — check the path in push.command"; read -p "Press Enter to close..."; exit 1; }

echo ""
echo "┌─────────────────────────────────────┐"
echo "│       Get The Hay Out — Deploy      │"
echo "└─────────────────────────────────────┘"
echo ""

# Prompt for commit message
read -p "Commit message: " MSG

if [ -z "$MSG" ]; then
  echo "❌ No message entered — deploy cancelled."
  read -p "Press Enter to close..."
  exit 1
fi

echo ""
echo "▶ Running deploy.py..."
python3 deploy.py || { echo "❌ deploy.py failed"; read -p "Press Enter to close..."; exit 1; }

echo "▶ Staging files..."
git add -A

echo "▶ Committing..."
git commit -m "$MSG"

echo "▶ Pushing to GitHub..."
git push && echo "" && echo "✅ Done — check Actions at github.com for deploy status." || echo "❌ Push failed — check your internet connection or token."

echo ""
read -p "Press Enter to close..."

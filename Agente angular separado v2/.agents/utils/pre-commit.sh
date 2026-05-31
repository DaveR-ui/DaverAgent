#!/bin/sh
#
# Pre-commit hook: Validate .agents/ markdown links before each commit.
# Prevents broken links from entering the repository.
#
# Install: copy this file to .git/hooks/pre-commit and make it executable.
#   On Windows (PowerShell):
#     Copy-Item .agents/utils/pre-commit.sh .git/hooks/pre-commit
#   On Unix:
#     cp .agents/utils/pre-commit.sh .git/hooks/pre-commit && chmod +x .git/hooks/pre-commit

echo "🔗 Validating .agents/ markdown links..."

node .agents/utils/validate-links.mjs

if [ $? -ne 0 ]; then
  echo ""
  echo "❌ Commit blocked: broken links detected."
  echo "   Run 'npm run agents:repair-links' to attempt auto-fix,"
  echo "   or fix the links manually before committing."
  exit 1
fi

echo "✅ Link validation passed."

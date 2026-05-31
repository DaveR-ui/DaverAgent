#!/bin/bash
# Agent File Validator
# Validates agent markdown files for correct structure and content

set -euo pipefail

# Usage
if [ $# -eq 0 ]; then
  echo "Usage: $0 <path/to/agent.md>"
  echo ""
  echo "Validates agent file for:"
  echo "  - YAML frontmatter structure"
  echo "  - Required fields (name, description, model, color)"
  echo "  - Field formats and constraints"
  echo "  - System prompt presence and length"
  echo "  - Example blocks in description"
  exit 1
fi

AGENT_FILE="$1"
NORMALIZED_AGENT=$(tr -d '\r' < "$AGENT_FILE")

echo "🔍 Validating agent file: $AGENT_FILE"
echo ""

# Check 1: File exists
if [ ! -f "$AGENT_FILE" ]; then
  echo "❌ File not found: $AGENT_FILE"
  exit 1
fi
echo "✅ File exists"

# Check 2: Starts with ---
FIRST_LINE=$(printf '%s\n' "$NORMALIZED_AGENT" | head -1)
if [ "$FIRST_LINE" != "---" ]; then
  echo "❌ File must start with YAML frontmatter (---)"
  exit 1
fi
echo "✅ Starts with frontmatter"

# Check 3: Has closing ---
if ! printf '%s\n' "$NORMALIZED_AGENT" | awk 'NR > 1 && $0 == "---" { found = 1; exit } END { exit !found }'; then
  echo "❌ Frontmatter not closed (missing second ---)"
  exit 1
fi
echo "✅ Frontmatter properly closed"

# Extract frontmatter and system prompt
FRONTMATTER=$(printf '%s\n' "$NORMALIZED_AGENT" | sed -n '/^---$/,/^---$/{ /^---$/d; p; }')
SYSTEM_PROMPT=$(printf '%s\n' "$NORMALIZED_AGENT" | awk '/^---$/{i++; next} i>=2')

extract_frontmatter_field() {
  local field_name="$1"
  printf '%s\n' "$FRONTMATTER" | sed -n "s/^${field_name}: *//p" | head -1
}

extract_frontmatter_description() {
  printf '%s\n' "$FRONTMATTER" | awk '
    BEGIN { in_block = 0 }
    in_block {
      if ($0 ~ /^[^[:space:]]/) {
        exit
      }
      sub(/^[[:space:]]*/, "", $0)
      print
      next
    }
    /^description:[[:space:]]*\|[[:space:]]*$/ {
      in_block = 1
      next
    }
    /^description:[[:space:]]*/ {
      sub(/^description:[[:space:]]*/, "", $0)
      print
      exit
    }
  '
}

# Check 4: Required fields
echo ""
echo "Checking required fields..."

error_count=0
warning_count=0

# Check name field
NAME=$(extract_frontmatter_field "name" | sed 's/^"\(.*\)"$/\1/')

if [ -z "$NAME" ]; then
  echo "❌ Missing required field: name"
  ((error_count += 1))
else
  echo "✅ name: $NAME"

  # Validate name format
  if ! [[ "$NAME" =~ ^[[:alnum:]][-[:alnum:][:space:]]*[[:alnum:]]$ ]]; then
    echo "❌ name must start/end with alphanumeric and contain only letters, numbers, spaces, or hyphens"
    ((error_count += 1))
  fi

  # Validate name length
  name_length=${#NAME}
  if [ $name_length -lt 3 ]; then
    echo "❌ name too short (minimum 3 characters)"
    ((error_count += 1))
  elif [ $name_length -gt 50 ]; then
    echo "❌ name too long (maximum 50 characters)"
    ((error_count += 1))
  fi

  # Check for generic names
  if [[ "${NAME,,}" =~ ^(helper|assistant|agent|tool)$ ]]; then
    echo "⚠️  name is too generic: $NAME"
    ((warning_count += 1))
  fi
fi

# Check description field
DESCRIPTION=$(extract_frontmatter_description)

if [ -z "$DESCRIPTION" ]; then
  echo "❌ Missing required field: description"
  ((error_count += 1))
else
  desc_length=${#DESCRIPTION}
  echo "✅ description: ${desc_length} characters"

  if [ $desc_length -lt 10 ]; then
    echo "⚠️  description too short (minimum 10 characters recommended)"
    ((warning_count += 1))
  elif [ $desc_length -gt 5000 ]; then
    echo "⚠️  description very long (over 5000 characters)"
    ((warning_count += 1))
  fi

  # Check for example blocks
  if ! echo "$DESCRIPTION" | grep -q '<example>'; then
    echo "⚠️  description should include <example> blocks for triggering"
    ((warning_count += 1))
  fi

  # Check for "Use this agent when" pattern
  if ! echo "$DESCRIPTION" | grep -qi 'use this agent when'; then
    echo "⚠️  description should start with 'Use this agent when...'"
    ((warning_count += 1))
  fi
fi

# Check model field
MODEL=$(extract_frontmatter_field "model")

if [ -z "$MODEL" ]; then
  echo "❌ Missing required field: model"
  ((error_count += 1))
else
  echo "✅ model: $MODEL"

  case "$MODEL" in
    gpt-5.4|gpt-5.3-codex|gemini-flash)
      # Valid model
      ;;
    inherit|sonnet|opus|haiku)
      echo "❌ Deprecated model: $MODEL (supported: gpt-5.4, gpt-5.3-codex, gemini-flash)"
      ((error_count += 1))
      ;;
    *)
      echo "❌ Unknown model: $MODEL (supported: gpt-5.4, gpt-5.3-codex, gemini-flash)"
      ((error_count += 1))
      ;;
  esac
fi

# Check color field
COLOR=$(extract_frontmatter_field "color")

if [ -z "$COLOR" ]; then
  echo "❌ Missing required field: color"
  ((error_count += 1))
else
  echo "✅ color: $COLOR"

  case "$COLOR" in
    blue|cyan|green|yellow|magenta|red)
      # Valid color
      ;;
    *)
      echo "⚠️  Unknown color: $COLOR (valid: blue, cyan, green, yellow, magenta, red)"
      ((warning_count += 1))
      ;;
  esac
fi

# Check tools field (optional)
TOOLS=$(extract_frontmatter_field "tools")

if [ -n "$TOOLS" ]; then
  echo "✅ tools: $TOOLS"
else
  echo "💡 tools: not specified (agent has access to all tools)"
fi

# Check 5: System prompt
echo ""
echo "Checking system prompt..."

if [ -z "$SYSTEM_PROMPT" ]; then
  echo "❌ System prompt is empty"
  ((error_count += 1))
else
  prompt_length=${#SYSTEM_PROMPT}
  echo "✅ System prompt: $prompt_length characters"

  if [ $prompt_length -lt 20 ]; then
    echo "❌ System prompt too short (minimum 20 characters)"
    ((error_count += 1))
  elif [ $prompt_length -gt 10000 ]; then
    echo "⚠️  System prompt very long (over 10,000 characters)"
    ((warning_count += 1))
  fi

  # Check for second person
  if ! echo "$SYSTEM_PROMPT" | grep -q "You are\|You will\|Your"; then
    echo "⚠️  System prompt should use second person (You are..., You will...)"
    ((warning_count += 1))
  fi

  # Check for structure
  if ! echo "$SYSTEM_PROMPT" | grep -qi "responsibilities\|process\|steps"; then
    echo "💡 Consider adding clear responsibilities or process steps"
  fi

  if ! echo "$SYSTEM_PROMPT" | grep -qi "output"; then
    echo "💡 Consider defining output format expectations"
  fi
fi

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [ $error_count -eq 0 ] && [ $warning_count -eq 0 ]; then
  echo "✅ All checks passed!"
  exit 0
elif [ $error_count -eq 0 ]; then
  echo "⚠️  Validation passed with $warning_count warning(s)"
  exit 0
else
  echo "❌ Validation failed with $error_count error(s) and $warning_count warning(s)"
  exit 1
fi
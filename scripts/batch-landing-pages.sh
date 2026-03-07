#!/bin/bash

# Stoke Landing Page Batch Generator
# Processes search terms and creates landing pages using Claude Code
#
# Usage:
#   ./scripts/batch-landing-pages.sh                    # Process all terms
#   ./scripts/batch-landing-pages.sh --start 5         # Start from term #5
#   ./scripts/batch-landing-pages.sh --dry-run         # Preview without running
#   ./scripts/batch-landing-pages.sh --single "term"   # Process single term

set -e

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
TERMS_FILE="$SCRIPT_DIR/search-terms.txt"
DEV_GUIDE="/Users/dal/Desktop/StokeV2docs/Distribution/Landing page dev plan.md"
LOG_FILE="$SCRIPT_DIR/batch-log-$(date +%Y%m%d-%H%M%S).txt"
PROGRESS_FILE="$SCRIPT_DIR/progress.txt"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Parse arguments
START_INDEX=1
DRY_RUN=false
SINGLE_TERM=""

while [[ $# -gt 0 ]]; do
    case $1 in
        --start)
            START_INDEX="$2"
            shift 2
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --single)
            SINGLE_TERM="$2"
            shift 2
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Functions
log() {
    local message="[$(date '+%Y-%m-%d %H:%M:%S')] $1"
    echo -e "$message"
    echo "$message" >> "$LOG_FILE"
}

log_success() {
    log "${GREEN}✓ $1${NC}"
}

log_error() {
    log "${RED}✗ $1${NC}"
}

log_info() {
    log "${BLUE}→ $1${NC}"
}

# Read terms from file (skip comments and empty lines)
read_terms() {
    grep -v '^#' "$TERMS_FILE" | grep -v '^[[:space:]]*$'
}

# Count total terms
count_terms() {
    read_terms | wc -l | tr -d ' '
}

# Get term by index
get_term() {
    read_terms | sed -n "${1}p"
}

# Process a single search term
process_term() {
    local term="$1"
    local index="$2"
    local total="$3"

    log_info "Processing [$index/$total]: $term"

    if [ "$DRY_RUN" = true ]; then
        echo "  [DRY RUN] Would process: $term"
        return 0
    fi

    # Create the prompt for Claude
    local prompt="Create a landing page for the search term: \"$term\"

Follow the development guide exactly. Complete these steps:

1. Research the term using web search (Google results, influencer content)
2. Identify the gap in existing content
3. Write the article following all rules in the guide
4. Create the markdown file at src/content/articles/[slug].md
5. Run 'npm run build' to verify it works
6. Commit with message: \"Add landing page: $term\"
7. Push to origin

The article must:
- Be 450-700 words
- Have zero em dashes
- Have zero bullet points
- Not mention Stoke in the article body
- Include the search term in the first 100 words
- Follow the voice and tone guidelines exactly

After completing, confirm the page is live by stating the slug."

    # Run Claude Code
    cd "$PROJECT_DIR"

    # Read dev guide content for system prompt
    local system_prompt
    system_prompt=$(cat "$DEV_GUIDE")

    if claude -p "$prompt" \
        --system-prompt "$system_prompt" \
        --allowedTools "Bash(git:*),Bash(npm:*),Edit,Write,Read,Glob,Grep,WebSearch,WebFetch" \
        --permission-mode bypassPermissions \
        --model sonnet \
        >> "$LOG_FILE" 2>&1; then

        log_success "Completed: $term"
        echo "$index|$term|success|$(date '+%Y-%m-%d %H:%M:%S')" >> "$PROGRESS_FILE"
        return 0
    else
        log_error "Failed: $term"
        echo "$index|$term|failed|$(date '+%Y-%m-%d %H:%M:%S')" >> "$PROGRESS_FILE"
        return 1
    fi
}

# Main execution
main() {
    echo ""
    echo "=========================================="
    echo "  Stoke Landing Page Batch Generator"
    echo "=========================================="
    echo ""

    # Validate files exist
    if [ ! -f "$TERMS_FILE" ]; then
        log_error "Terms file not found: $TERMS_FILE"
        exit 1
    fi

    if [ ! -f "$DEV_GUIDE" ]; then
        log_error "Dev guide not found: $DEV_GUIDE"
        exit 1
    fi

    local total=$(count_terms)
    log_info "Found $total search terms"
    log_info "Log file: $LOG_FILE"
    log_info "Starting from index: $START_INDEX"

    if [ "$DRY_RUN" = true ]; then
        log_info "DRY RUN MODE - No changes will be made"
    fi

    echo ""

    # Handle single term mode
    if [ -n "$SINGLE_TERM" ]; then
        log_info "Single term mode: $SINGLE_TERM"
        process_term "$SINGLE_TERM" 1 1
        exit $?
    fi

    # Process terms
    local success=0
    local failed=0
    local skipped=0

    for i in $(seq "$START_INDEX" "$total"); do
        local term=$(get_term "$i")

        if [ -z "$term" ]; then
            continue
        fi

        # Check if already processed
        if [ -f "$PROGRESS_FILE" ] && grep -q "|$term|success|" "$PROGRESS_FILE"; then
            log_info "Skipping (already done): $term"
            ((skipped++))
            continue
        fi

        if process_term "$term" "$i" "$total"; then
            ((success++))
        else
            ((failed++))
            # Continue to next term even on failure
        fi

        # Small delay between terms to avoid rate limiting
        sleep 2
    done

    # Summary
    echo ""
    echo "=========================================="
    echo "  Batch Complete"
    echo "=========================================="
    echo ""
    log_info "Success: $success"
    log_info "Failed: $failed"
    log_info "Skipped: $skipped"
    log_info "Log: $LOG_FILE"
}

main

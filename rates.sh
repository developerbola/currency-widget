#!/bin/bash

LOG_FILE="./Currency.widget/log.txt"
LOG_DIR=$(dirname "$LOG_FILE")

# Ensure the directory exists
mkdir -p "$LOG_DIR"

# Get today's date dynamically
TODAY="$(date +%Y-%m-%d 2>/dev/null || date -v 0d +%Y-%m-%d 2>/dev/null)"

if [ -z "$TODAY" ]; then
    echo "Error: Failed to get today's date." >&2
    exit 1
fi

# Check if log file exists and was created/modified today
if [ -f "$LOG_FILE" ]; then
    # Get the modification date of the file
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        FILE_DATE=$(stat -f "%Sm" -t "%Y-%m-%d" "$LOG_FILE")
    else
        # Linux and others
        FILE_DATE=$(date -r "$LOG_FILE" +%Y-%m-%d 2>/dev/null)
    fi
    
    # If file was modified today, use cached data
    if [ "$FILE_DATE" = "$TODAY" ]; then
        cat "$LOG_FILE"
        exit 0
    fi
fi

# If we get here, we need to fetch new data

# Array to store the dates (today and the previous 7 days)
DATES=()
# Add today's date
DATES+=("$TODAY")
# Calculate the previous 7 days
for i in {1..7}; do
    PREV_DATE=$(date -d "$TODAY - $i days" +%Y-%m-%d 2>/dev/null || date -v-$i"d" +%Y-%m-%d 2>/dev/null)
    if [ -z "$PREV_DATE" ]; then
        echo "Error: Failed to calculate date for $i days ago." >&2
        exit 1
    fi
    DATES+=("$PREV_DATE")
done

# Arrays to store the rates, diffs, and actual dates from API
RATES=()
DIFFS=()
ACTUAL_DATES=()

# Fetch the rate and diff for each date
for DATE in "${DATES[@]}"; do
    while :; do
        # Construct the API URL
        URL="https://cbu.uz/uz/arkhiv-kursov-valyut/json/USD/$DATE/"
        
        # Fetch the data using curl
        RESPONSE=$(curl -s "$URL")
        if [ -z "$RESPONSE" ]; then
            echo "Error: Failed to fetch data for $DATE" >&2
            RATES+=("N/A")
            DIFFS+=("N/A")
            ACTUAL_DATES+=("$DATE")
            break
        fi
        
        # Parse the rate using grep and sed
        RATE=$(echo "$RESPONSE" | grep -o '"Rate":"[0-9.]*"' | sed 's/"Rate":"\(.*\)"/\1/')
        if [ -z "$RATE" ]; then
            echo "Error: Failed to parse rate for $DATE" >&2
            RATES+=("N/A")
            DIFFS+=("N/A")
            ACTUAL_DATES+=("$DATE")
            break
        fi
        
        # Check for duplicate rate
        if [[ " ${RATES[@]} " =~ " $RATE " ]]; then
            # If duplicate, go back one more day
            DATE=$(date -d "$DATE - 1 day" +%Y-%m-%d 2>/dev/null || date -v-1d -j -f "%Y-%m-%d" "$DATE" +%Y-%m-%d 2>/dev/null)
            continue
        fi
        
        # Parse the diff using grep and sed
        DIFF=$(echo "$RESPONSE" | grep -o '"Diff":"[-0-9.]*"' | sed 's/"Diff":"\(.*\)"/\1/')
        [ -z "$DIFF" ] && DIFF="N/A"
        
        # Get the actual date from API response
        API_DATE=$(echo "$RESPONSE" | grep -o '"Date":"[0-9-]*"' | sed 's/"Date":"\(.*\)"/\1/')
        [ -z "$API_DATE" ] && API_DATE="$DATE"
        
        RATES+=("$RATE")
        DIFFS+=("$DIFF")
        ACTUAL_DATES+=("$API_DATE")
        break
    done
done

# Build a single string with date-rate-diff triplets separated by !!
OUTPUT=""
for i in {0..7}; do
    DATE=${ACTUAL_DATES[$i]}
    RATE=${RATES[$i]}
    DIFF=${DIFFS[$i]}
    TRIPLET="$DATE:$RATE:$DIFF"
    if [ -z "$OUTPUT" ]; then
        OUTPUT="$TRIPLET"
    else
        OUTPUT="$OUTPUT!!$TRIPLET"
    fi
done

# Save output to log file
echo "$OUTPUT" > "$LOG_FILE"

# Output the single line
echo "$OUTPUT"
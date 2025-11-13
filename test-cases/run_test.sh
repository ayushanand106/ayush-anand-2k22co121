#!/bin/bash

# --- Configuration ---
BASE_URL="http://127.0.0.1:5000"
DB_FILE="boostly.db" # The name of your sqlite db file in the app.py

# --- Colors for Output ---
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# --- State ---
PASSED=0
FAILED=0
ALICE_ID=""
BOB_ID=""
CHARLIE_ID=""
RECOGNITION_ID=""

# --- Helper Function ---
# Usage: report_result "Test Name" "pass"
# Usage: report_result "Test Name" "fail" "Optional failure message"
report_result() {
    local test_name="$1"
    local result="$2"
    
    if [ "$result" = "pass" ]; then
        echo -e "  [${GREEN}PASS${NC}] $test_name"
        ((PASSED++))
    else
        echo -e "  [${RED}FAIL${NC}] $test_name"
        [ ! -z "$3" ] && echo "    -> $3"
        ((FAILED++))
    fi
}

# --- Prerequisite Check ---
if ! command -v jq &> /dev/null; then
    echo -e "${RED}Error: 'jq' is not installed.${NC}"
    echo "This script requires 'jq' to parse JSON responses."
    echo "Please install it to continue (e.g., 'sudo apt-get install jq' or 'brew install jq')."
    exit 1
fi

echo -e "${YELLOW}--- Preparing Environment ---${NC}"
echo "  - Stopping Flask app (if running) to reset DB..."
# Find and kill any existing Flask app on port 5000
pkill -f "flask run" &>/dev/null
sleep 1

echo "  - Deleting old database ($DB_FILE)..."
rm -f "$DB_FILE"

echo "  - Re-initializing database..."
flask db-create-all

echo "  - Starting Flask app in the background..."
flask run &> /dev/null &
FLASK_PID=$!
# Give the server a moment to start
sleep 2
echo "  - Flask app running with PID $FLASK_PID"


# --- Test: Initial Setup ---
echo -e "\n${YELLOW}--- Initial Setup: Create Test Users ---${NC}"
# We use -s for silent, and capture the JSON response
RESPONSE=$(curl -s -X POST "$BASE_URL/students" -H "Content-Type: application/json" -d '{"username": "alice", "email": "alice@example.com"}')
ALICE_ID=$(echo "$RESPONSE" | jq '.id')
[ ! -z "$ALICE_ID" ] && report_result "Create 'alice'" "pass" || report_result "Create 'alice'" "fail" "Response: $RESPONSE"

RESPONSE=$(curl -s -X POST "$BASE_URL/students" -H "Content-Type: application/json" -d '{"username": "bob", "email": "bob@example.com"}')
BOB_ID=$(echo "$RESPONSE" | jq '.id')
[ ! -z "$BOB_ID" ] && report_result "Create 'bob'" "pass" || report_result "Create 'bob'" "fail" "Response: $RESPONSE"

RESPONSE=$(curl -s -X POST "$BASE_URL/students" -H "Content-Type: application/json" -d '{"username": "charlie", "email": "charlie@example.com"}')
CHARLIE_ID=$(echo "$RESPONSE" | jq '.id')
[ ! -z "$CHARLIE_ID" ] && report_result "Create 'charlie'" "pass" || report_result "Create 'charlie'" "fail" "Response: $RESPONSE"


# --- Test: 1. Recognition Feature ---
echo -e "\n${YELLOW}--- 1. Recognition Feature ---${NC}"

# Test 1.1: Successful Recognition
# We use -w "%{http_code}" to get the status code, and -o /dev/null to discard the body
RESPONSE_1_1=$(curl -s -w "%{http_code}" -X POST "$BASE_URL/recognitions" -H "Content-Type: application/json" -d "{\"sender_id\": $ALICE_ID, \"receiver_id\": $BOB_ID, \"credits\": 20, \"message\": \"Great teamwork!\"}")
STATUS_1_1=${RESPONSE_1_1: -3} # Extract last 3 chars (the status code)
BODY_1_1=${RESPONSE_1_1:0:${#RESPONSE_1_1}-3} # Extract the body
RECOGNITION_ID=$(echo "$BODY_1_1" | jq '.id')

if [ "$STATUS_1_1" = "201" ]; then
    report_result "Test 1.1: Successful Recognition (Status 201)" "pass"
    # Now check balances
    ALICE_CREDITS=$(curl -s "$BASE_URL/students/$ALICE_ID" | jq '.sending_credits')
    BOB_CREDITS=$(curl -s "$BASE_URL/students/$BOB_ID" | jq '.redeemable_credits')
    
    [ "$ALICE_CREDITS" = "80" ] && report_result "Test 1.1: Alice's sending_credits == 80" "pass" || report_result "Test 1.1: Alice's sending_credits == 80" "fail" "Got $ALICE_CREDITS"
    [ "$BOB_CREDITS" = "20" ] && report_result "Test 1.1: Bob's redeemable_credits == 20" "pass" || report_result "Test 1.1: Bob's redeemable_credits == 20" "fail" "Got $BOB_CREDITS"
else
    report_result "Test 1.1: Successful Recognition (Status 201)" "fail" "Got status $STATUS_1_1"
fi

# Test 1.2: Failed Recognition (Self-Recognition)
STATUS_1_2=$(curl -s -o /dev/null -w "%{http_code}" -X POST "$BASE_URL/recognitions" -H "Content-Type: application/json" -d "{\"sender_id\": $ALICE_ID, \"receiver_id\": $ALICE_ID, \"credits\": 10}")
[ "$STATUS_1_2" = "400" ] && report_result "Test 1.2: Failed (Self-Recognition) (Status 400)" "pass" || report_result "Test 1.2: Failed (Self-Recognition) (Status 400)" "fail" "Got status $STATUS_1_2"

# Test 1.3: Failed Recognition (Insufficient Credits)
STATUS_1_3=$(curl -s -o /dev/null -w "%{http_code}" -X POST "$BASE_URL/recognitions" -H "Content-Type: application/json" -d "{\"sender_id\": $ALICE_ID, \"receiver_id\": $BOB_ID, \"credits\": 90}")
[ "$STATUS_1_3" = "400" ] && report_result "Test 1.3: Failed (Insufficient Credits) (Status 400)" "pass" || report_result "Test 1.3: Failed (Insufficient Credits) (Status 400)" "fail" "Got status $STATUS_1_3"


# --- Test: 2. Endorsements Feature ---
echo -e "\n${YELLOW}--- 2. Endorsements Feature ---${NC}"

# Test 2.1: Successful Endorsement
STATUS_2_1=$(curl -s -o /dev/null -w "%{http_code}" -X POST "$BASE_URL/endorsements" -H "Content-Type: application/json" -d "{\"endorser_id\": $CHARLIE_ID, \"recognition_id\": $RECOGNITION_ID}")
[ "$STATUS_2_1" = "201" ] && report_result "Test 2.1: Successful Endorsement (Status 201)" "pass" || report_result "Test 2.1: Successful Endorsement (Status 201)" "fail" "Got status $STATUS_2_1"

# Test 2.2: Failed Endorsement (Duplicate)
STATUS_2_2=$(curl -s -o /dev/null -w "%{http_code}" -X POST "$BASE_URL/endorsements" -H "Content-Type: application/json" -d "{\"endorser_id\": $CHARLIE_ID, \"recognition_id\": $RECOGNITION_ID}")
[ "$STATUS_2_2" = "409" ] && report_result "Test 2.2: Failed (Duplicate Endorsement) (Status 409)" "pass" || report_result "Test 2.2: Failed (Duplicate Endorsement) (Status 409)" "fail" "Got status $STATUS_2_2"


# --- Test: 3. Redemption Feature ---
echo -e "\n${YELLOW}--- 3. Redemption Feature ---${NC}"

# Test 3.1: Successful Redemption
REDEEM_RESPONSE=$(curl -s -X POST "$BASE_URL/redeem" -H "Content-Type: application/json" -d "{\"student_id\": $BOB_ID, \"credits_to_redeem\": 15}")
REDEEM_BALANCE=$(echo "$REDEEM_RESPONSE" | jq '.new_redeemable_balance')

if [ "$REDEEM_BALANCE" = "5" ]; then
    report_result "Test 3.1: Successful Redemption (Response body)" "pass"
    # Double-check by GET-ing the student
    BOB_BALANCE_GET=$(curl -s "$BASE_URL/students/$BOB_ID" | jq '.redeemable_credits')
    [ "$BOB_BALANCE_GET" = "5" ] && report_result "Test 3.1: Successful Redemption (GET /students)" "pass" || report_result "Test 3.1: Successful Redemption (GET /students)" "fail" "Got $BOB_BALANCE_GET"
else
    report_result "Test 3.1: Successful Redemption (Response body)" "fail" "Got balance $REDEEM_BALANCE"
fi

# Test 3.2: Failed Redemption (Insufficient Credits)
STATUS_3_2=$(curl -s -o /dev/null -w "%{http_code}" -X POST "$BASE_URL/redeem" -H "Content-Type: application/json" -d "{\"student_id\": $BOB_ID, \"credits_to_redeem\": 10}")
[ "$STATUS_3_2" = "400" ] && report_result "Test 3.2: Failed (Insufficient Credits) (Status 400)" "pass" || report_result "Test 3.2: Failed (Insufficient Credits) (Status 400)" "fail" "Got status $STATUS_3_2"


# --- Test: 4. List and Filter Students ---
echo -e "\n${YELLOW}--- 4. List and Filter Students ---${NC}"

# Test 4.1: Get All Students
COUNT_4_1=$(curl -s "$BASE_URL/students" | jq '. | length')
[ "$COUNT_4_1" = "3" ] && report_result "Test 4.1: Get All Students (Count == 3)" "pass" || report_result "Test 4.1: Get All Students (Count == 3)" "fail" "Got $COUNT_4_1"

# Test 4.2: Filter by Username (Partial Match)
COUNT_4_2=$(curl -s "$BASE_URL/students?username=ali" | jq '. | length')
[ "$COUNT_4_2" = "1" ] && report_result "Test 4.2: Filter by Username 'ali' (Count == 1)" "pass" || report_result "Test 4.2: Filter by Username 'ali' (Count == 1)" "fail" "Got $COUNT_4_2"

# Test 4.3: Filter by Email (Case-Insensitive)
COUNT_4_3=$(curl -s "$BASE_URL/students?email=BOB@EXAMPLE.COM" | jq '. | length')
[ "$COUNT_4_3" = "1" ] && report_result "Test 4.3: Filter by Email 'BOB@EXAMPLE.COM' (Count == 1)" "pass" || report_result "Test 4.3: Filter by Email 'BOB@EXAMPLE.COM' (Count == 1)" "fail" "Got $COUNT_4_3"

# Test 4.4: Filter with No Results
COUNT_4_4=$(curl -s "$BASE_URL/students?username=dave" | jq '. | length')
[ "$COUNT_4_4" = "0" ] && report_result "Test 4.4: Filter with No Results (Count == 0)" "pass" || report_result "Test 4.4: Filter with No Results (Count == 0)" "fail" "Got $COUNT_4_4"

# Test 4.5: Filter by Username and Email
COUNT_4_5=$(curl -s "$BASE_URL/students?username=char&email=charlie@example.com" | jq '. | length')
[ "$COUNT_4_5" = "1" ] && report_result "Test 4.5: Filter by Username and Email (Count == 1)" "pass" || report_result "Test 4.5: Filter by Username and Email (Count == 1)" "fail" "Got $COUNT_4_5"


# --- Cleanup & Summary ---
echo -e "\n${YELLOW}--- Test Summary ---${NC}"
echo "  - Stopping Flask app (PID $FLASK_PID)..."
kill $FLASK_PID

echo -e "  - ${GREEN}Passed: $PASSED${NC}"
echo -e "  - ${RED}Failed: $FAILED${NC}"

if [ "$FAILED" -gt 0 ]; then
    exit 1
else
    exit 0
fi
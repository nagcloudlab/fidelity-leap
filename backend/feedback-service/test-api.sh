#!/bin/bash

BASE=http://localhost:8080
BOLD='\033[1m'
GREEN='\033[0;32m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

print_header() {
  echo ""
  echo -e "${BOLD}${CYAN}=== $1 ===${NC}"
}

# ─── Register ────────────────────────────────────────────────────

print_header "1. Register user (valid)"
curl -s -w "\nHTTP %{http_code}" -X POST "$BASE/register" \
  -H "Content-Type: application/json" \
  -d '{"username":"alice","password":"pass123","email":"alice@test.com"}' | jq -R -s 'split("\n") | {body: (.[:-1] | join("\n") | fromjson? // .[:-1] | join("\n")), status: .[-1]}'

print_header "2. Register duplicate username → 409"
curl -s -w "\nHTTP %{http_code}" -X POST "$BASE/register" \
  -H "Content-Type: application/json" \
  -d '{"username":"alice","password":"pass123","email":"alice2@test.com"}' | jq -R -s 'split("\n") | {body: (.[:-1] | join("\n") | fromjson? // .[:-1] | join("\n")), status: .[-1]}'

print_header "3. Register with missing fields → 400"
curl -s -w "\nHTTP %{http_code}" -X POST "$BASE/register" \
  -H "Content-Type: application/json" \
  -d '{"username":"","password":"","email":"bad"}' | jq -R -s 'split("\n") | {body: (.[:-1] | join("\n") | fromjson? // .[:-1] | join("\n")), status: .[-1]}'

print_header "4. Register admin user"
curl -s -w "\nHTTP %{http_code}" -X POST "$BASE/register" \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"admin123","email":"admin@test.com"}' | jq -R -s 'split("\n") | {body: (.[:-1] | join("\n") | fromjson? // .[:-1] | join("\n")), status: .[-1]}'

# ─── Login ───────────────────────────────────────────────────────

print_header "5. Login with wrong password → 401"
curl -s -w "\nHTTP %{http_code}" -X POST "$BASE/login" \
  -H "Content-Type: application/json" \
  -d '{"username":"alice","password":"wrong"}' | jq -R -s 'split("\n") | {body: (.[:-1] | join("\n") | fromjson? // .[:-1] | join("\n")), status: .[-1]}'

print_header "6. Login alice → JWT"
ALICE_RESP=$(curl -s -X POST "$BASE/login" \
  -H "Content-Type: application/json" \
  -d '{"username":"alice","password":"pass123"}')
ALICE_TOKEN=$(echo "$ALICE_RESP" | jq -r '.token')
echo "$ALICE_RESP" | jq .
echo -e "${GREEN}Token saved.${NC}"

print_header "7. Login admin → JWT"
ADMIN_RESP=$(curl -s -X POST "$BASE/login" \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"admin123"}')
ADMIN_TOKEN=$(echo "$ADMIN_RESP" | jq -r '.token')
echo "$ADMIN_RESP" | jq .
echo -e "${GREEN}Token saved.${NC}"

# ─── Decode JWT (peek at claims) ────────────────────────────────

print_header "8. Decode alice JWT payload"
echo "$ALICE_TOKEN" | cut -d. -f2 | base64 -d 2>/dev/null | jq .

print_header "9. Decode admin JWT payload"
echo "$ADMIN_TOKEN" | cut -d. -f2 | base64 -d 2>/dev/null | jq .

# ─── Create Feedback ────────────────────────────────────────────

print_header "10. Create feedback as alice (valid) → 201"
curl -s -w "\nHTTP %{http_code}" -X POST "$BASE/api/v1/feedbacks" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $ALICE_TOKEN" \
  -d '{"mood":"Happy","rating":5,"comment":"Great service!"}' | jq -R -s 'split("\n") | {body: (.[:-1] | join("\n") | fromjson? // .[:-1] | join("\n")), status: .[-1]}'

print_header "11. Create feedback with invalid rating → 400"
curl -s -w "\nHTTP %{http_code}" -X POST "$BASE/api/v1/feedbacks" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $ALICE_TOKEN" \
  -d '{"mood":"Sad","rating":10,"comment":"bad rating"}' | jq -R -s 'split("\n") | {body: (.[:-1] | join("\n") | fromjson? // .[:-1] | join("\n")), status: .[-1]}'

print_header "12. Create feedback as admin"
curl -s -w "\nHTTP %{http_code}" -X POST "$BASE/api/v1/feedbacks" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -d '{"mood":"Neutral","rating":3,"comment":"Admin feedback"}' | jq -R -s 'split("\n") | {body: (.[:-1] | join("\n") | fromjson? // .[:-1] | join("\n")), status: .[-1]}'

# ─── Get Feedbacks ───────────────────────────────────────────────

print_header "13. Get feedbacks as alice (own only)"
curl -s -w "\nHTTP %{http_code}" -X GET "$BASE/api/v1/feedbacks" \
  -H "Authorization: Bearer $ALICE_TOKEN" | jq -R -s 'split("\n") | {body: (.[:-1] | join("\n") | fromjson? // .[:-1] | join("\n")), status: .[-1]}'

print_header "14. Get feedbacks as admin (sees all)"
curl -s -w "\nHTTP %{http_code}" -X GET "$BASE/api/v1/feedbacks" \
  -H "Authorization: Bearer $ADMIN_TOKEN" | jq -R -s 'split("\n") | {body: (.[:-1] | join("\n") | fromjson? // .[:-1] | join("\n")), status: .[-1]}'

# ─── Delete Feedback ─────────────────────────────────────────────

print_header "15. Delete feedback as alice (non-admin) → 403"
curl -s -w "\nHTTP %{http_code}" -X DELETE "$BASE/api/v1/feedbacks/1" \
  -H "Authorization: Bearer $ALICE_TOKEN" | jq -R -s 'split("\n") | {body: (.[:-1] | join("\n") | fromjson? // .[:-1] | join("\n")), status: .[-1]}'

print_header "16. Delete feedback as admin → 204"
curl -s -w "\nHTTP %{http_code}" -X DELETE "$BASE/api/v1/feedbacks/1" \
  -H "Authorization: Bearer $ADMIN_TOKEN" | jq -R -s 'split("\n") | {body: (.[:-1] | join("\n") | fromjson? // .[:-1] | join("\n")), status: .[-1]}'

# ─── Invalid / Expired Token ────────────────────────────────────

print_header "17. Request with invalid token → 401"
curl -s -w "\nHTTP %{http_code}" -X GET "$BASE/api/v1/feedbacks" \
  -H "Authorization: Bearer invalid.token.here" | jq -R -s 'split("\n") | {body: (.[:-1] | join("\n") | fromjson? // .[:-1] | join("\n")), status: .[-1]}'

print_header "18. Request with no token → 401"
curl -s -w "\nHTTP %{http_code}" -X GET "$BASE/api/v1/feedbacks" | jq -R -s 'split("\n") | {body: (.[:-1] | join("\n") | fromjson? // .[:-1] | join("\n")), status: .[-1]}'

echo ""
echo -e "${BOLD}${GREEN}Done.${NC}"

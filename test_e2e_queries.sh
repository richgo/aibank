#!/bin/bash

echo "========================================"
echo "E2E Query Tests"
echo "========================================"

echo ""
echo "1. Testing Account Overview Query..."
curl -s -X POST http://localhost:8080/chat \
  -H "Content-Type: application/json" \
  -d '{"message": "show my accounts"}' | python3 -c "
import sys, json
data = json.load(sys.stdin)
print('✓ Text Response:', data['text'])
print('✓ A2UI Messages:', len(data['a2ui']))
print('✓ First A2UI message type:', data['a2ui'][0].get('type', 'unknown'))
"

echo ""
echo "2. Testing Transaction Query..."
curl -s -X POST http://localhost:8080/chat \
  -H "Content-Type: application/json" \
  -d '{"message": "show my transactions"}' | python3 -c "
import sys, json
data = json.load(sys.stdin)
print('✓ Text Response:', data['text'])
print('✓ A2UI Messages:', len(data['a2ui']))
"

echo ""
echo "3. Testing Mortgage Query..."
curl -s -X POST http://localhost:8080/chat \
  -H "Content-Type: application/json" \
  -d '{"message": "mortgage balance"}' | python3 -c "
import sys, json
data = json.load(sys.stdin)
print('✓ Text Response:', data['text'])
print('✓ A2UI Messages:', len(data['a2ui']))
"

echo ""
echo "4. Testing Credit Card Query..."
curl -s -X POST http://localhost:8080/chat \
  -H "Content-Type: application/json" \
  -d '{"message": "credit card statement"}' | python3 -c "
import sys, json
data = json.load(sys.stdin)
print('✓ Text Response:', data['text'])
print('✓ A2UI Messages:', len(data['a2ui']))
"

echo ""
echo "5. Testing Savings Query..."
curl -s -X POST http://localhost:8080/chat \
  -H "Content-Type: application/json" \
  -d '{"message": "savings account"}' | python3 -c "
import sys, json
data = json.load(sys.stdin)
print('✓ Text Response:', data['text'])
print('✓ A2UI Messages:', len(data['a2ui']))
"

echo ""
echo "6. Testing Account Detail Query..."
curl -s -X POST http://localhost:8080/chat \
  -H "Content-Type: application/json" \
  -d '{"message": "show account detail"}' | python3 -c "
import sys, json
data = json.load(sys.stdin)
print('✓ Text Response:', data['text'])
print('✓ A2UI Messages:', len(data['a2ui']))
"

echo ""
echo "========================================"
echo "All queries completed!"
echo "========================================"

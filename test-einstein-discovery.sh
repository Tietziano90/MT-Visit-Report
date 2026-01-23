#!/bin/bash

# Script to discover available Einstein Platform models and features
# Usage: ./test-einstein-discovery.sh <access_token>

if [ -z "$1" ]; then
    echo "Usage: $0 <access_token>"
    echo "Get access token from Salesforce org JWT"
    exit 1
fi

ACCESS_TOKEN="$1"
BASE_URL="https://api.salesforce.com/einstein/platform/v1"

echo "==================================================================="
echo "Testing Einstein Platform API Discovery"
echo "==================================================================="
echo ""

# Test 1: List available models (common endpoint pattern)
echo "1. Attempting to list models..."
curl -s -X GET "${BASE_URL}/models" \
  -H "Authorization: Bearer ${ACCESS_TOKEN}" \
  -H "x-sfdc-app-context: EinsteinGPT" \
  -H "x-client-feature-id: external-edc" | jq '.' 2>/dev/null || echo "Endpoint not available or error"
echo ""
echo "-------------------------------------------------------------------"

# Test 2: Check transcribe models specifically
echo "2. Checking transcribe models..."
curl -s -X GET "${BASE_URL}/models/transcribeInternalV1" \
  -H "Authorization: Bearer ${ACCESS_TOKEN}" \
  -H "x-sfdc-app-context: EinsteinGPT" \
  -H "x-client-feature-id: external-edc" | jq '.' 2>/dev/null || echo "Endpoint not available or error"
echo ""
echo "-------------------------------------------------------------------"

# Test 3: Check available capabilities
echo "3. Checking capabilities..."
curl -s -X GET "${BASE_URL}/capabilities" \
  -H "Authorization: Bearer ${ACCESS_TOKEN}" \
  -H "x-sfdc-app-context: EinsteinGPT" \
  -H "x-client-feature-id: external-edc" | jq '.' 2>/dev/null || echo "Endpoint not available or error"
echo ""
echo "-------------------------------------------------------------------"

# Test 4: Check jobs endpoint (for batch operations)
echo "4. Checking jobs endpoint..."
curl -s -X GET "${BASE_URL}/jobs" \
  -H "Authorization: Bearer ${ACCESS_TOKEN}" \
  -H "x-sfdc-app-context: EinsteinGPT" \
  -H "x-client-feature-id: external-edc" | jq '.' 2>/dev/null || echo "Endpoint not available or error"
echo ""
echo "-------------------------------------------------------------------"

# Test 5: Check available engines
echo "5. Checking available engines..."
curl -s -X GET "${BASE_URL}/engines" \
  -H "Authorization: Bearer ${ACCESS_TOKEN}" \
  -H "x-sfdc-app-context: EinsteinGPT" \
  -H "x-client-feature-id: external-edc" | jq '.' 2>/dev/null || echo "Endpoint not available or error"
echo ""
echo "-------------------------------------------------------------------"

# Test 6: OPTIONS request to transcriptions endpoint
echo "6. Checking OPTIONS on transcriptions endpoint..."
curl -s -X OPTIONS "${BASE_URL}/models/transcribeInternalV1/transcriptions" \
  -H "Authorization: Bearer ${ACCESS_TOKEN}" \
  -H "x-sfdc-app-context: EinsteinGPT" \
  -H "x-client-feature-id: external-edc" -v 2>&1 | grep -E "Allow:|HTTP"
echo ""
echo "-------------------------------------------------------------------"

echo ""
echo "==================================================================="
echo "Discovery Complete"
echo "==================================================================="
echo ""
echo "Known Endpoints from Documentation:"
echo "  - Micro-batch Transcription: ${BASE_URL}/models/transcribeInternalV1/transcriptions"
echo "  - Speech Synthesis: ${BASE_URL}/models/transcribeInternalV1/speech-synthesis"
echo "  - Translation: ${BASE_URL}/models/transcribeInternalV1/translations"
echo "  - Batch Jobs: ${BASE_URL}/jobs"
echo ""
echo "Known Models:"
echo "  - transcribeInternalV1 (current)"
echo "  - transcribeAWSV1 (batch jobs)"
echo ""
echo "Known Engines:"
echo "  - internal (Einstein native)"
echo "  - aws (Amazon Transcribe/Polly)"
echo "  - elevenlabs (Speech Synthesis v2)"
echo ""

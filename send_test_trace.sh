#!/bin/bash

# Professional Test Trace Generator for DSLM Demo
# Simulates realistic microservices environment

# Arrays of professional service names and operations
SERVICES=("user-authentication" "payment-gateway" "order-processing" "inventory-service" "notification-service" "analytics-engine" "content-delivery" "fraud-detection")
OPERATIONS=("authenticate_user" "process_payment" "create_order" "check_inventory" "send_notification" "track_event" "serve_content" "analyze_transaction")
HTTP_METHODS=("GET" "POST" "PUT" "DELETE")
STATUS_CODES=("200" "201" "400" "404" "500")
REGIONS=("us-east-1" "eu-west-1" "ap-southeast-1")

# Generate random values
SERVICE=${SERVICES[$RANDOM % ${#SERVICES[@]}]}
OPERATION=${OPERATIONS[$RANDOM % ${#OPERATIONS[@]}]}
HTTP_METHOD=${HTTP_METHODS[$RANDOM % ${#HTTP_METHODS[@]}]}
STATUS_CODE=${STATUS_CODES[$RANDOM % ${#STATUS_CODES[@]}]}
REGION=${REGIONS[$RANDOM % ${#REGIONS[@]}]}

# Generate realistic trace and span IDs
TRACE_ID=$(openssl rand -hex 16)
SPAN_ID=$(openssl rand -hex 8)
PARENT_SPAN_ID=$(openssl rand -hex 8)

# Random duration between 10ms and 2s
DURATION_MS=$((RANDOM % 2000 + 10))
START_TIME=$(date +%s%N)
END_TIME=$((START_TIME + DURATION_MS * 1000000))

# Random error injection (10% chance)
if [ $((RANDOM % 10)) -eq 0 ]; then
    STATUS_CODE="500"
    ERROR_MESSAGE="Internal service error"
    SPAN_STATUS='"status": {"code": 2, "message": "'$ERROR_MESSAGE'"},'
else
    SPAN_STATUS=""
fi

echo "Generating trace for: $SERVICE → $OPERATION ($HTTP_METHOD) in $REGION"

# Send professional trace to Tempo
curl -X POST http://localhost:4318/v1/traces \
  -H "Content-Type: application/json" \
  -d '{
    "resourceSpans": [
      {
        "resource": {
          "attributes": [
            {
              "key": "service.name",
              "value": {"stringValue": "'$SERVICE'"}
            },
            {
              "key": "service.version",
              "value": {"stringValue": "v1.2.3"}
            },
            {
              "key": "deployment.environment",
              "value": {"stringValue": "production"}
            },
            {
              "key": "cloud.region",
              "value": {"stringValue": "'$REGION'"}
            },
            {
              "key": "cloud.provider",
              "value": {"stringValue": "aws"}
            }
          ]
        },
        "scopeSpans": [
          {
            "scope": {
              "name": "opentelemetry-js",
              "version": "1.17.0"
            },
            "spans": [
              {
                "traceId": "'$TRACE_ID'",
                "spanId": "'$SPAN_ID'",
                "parentSpanId": "'$PARENT_SPAN_ID'",
                "name": "'$OPERATION'",
                "kind": 1,
                "startTimeUnixNano": "'$START_TIME'",
                "endTimeUnixNano": "'$END_TIME'",
                '$SPAN_STATUS'
                "attributes": [
                  {
                    "key": "http.method",
                    "value": {"stringValue": "'$HTTP_METHOD'"}
                  },
                  {
                    "key": "http.status_code",
                    "value": {"intValue": '$STATUS_CODE'}
                  },
                  {
                    "key": "http.url",
                    "value": {"stringValue": "https://api.company.com/v1/'$OPERATION'"}
                  },
                  {
                    "key": "user.id",
                    "value": {"stringValue": "user_'$((RANDOM % 1000))'"}
                  },
                  {
                    "key": "request.id",
                    "value": {"stringValue": "req_'$(openssl rand -hex 8)'"}
                  },
                  {
                    "key": "duration_ms",
                    "value": {"doubleValue": '$DURATION_MS'}
                  },
                  {
                    "key": "team",
                    "value": {"stringValue": "platform-engineering"}
                  }
                ]
              }
            ]
          }
        ]
      }
    ]
  }' > /dev/null 2>&1

if [ $? -eq 0 ]; then
    echo "✅ Professional trace sent: $SERVICE → $OPERATION ($DURATION_MS ms)"
else
    echo "❌ Failed to send trace"
fi
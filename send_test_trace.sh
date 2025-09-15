#!/bin/bash

# Send a test trace to Tempo
curl -X POST http://localhost:4318/v1/traces \
  -H "Content-Type: application/json" \
  -d '{
    "resourceSpans": [
      {
        "resource": {
          "attributes": [
            {
              "key": "service.name",
              "value": {
                "stringValue": "test-service"
              }
            }
          ]
        },
        "scopeSpans": [
          {
            "scope": {
              "name": "test-scope",
              "version": "1.0.0"
            },
            "spans": [
              {
                "traceId": "0123456789abcdef0123456789abcdef",
                "spanId": "0123456789abcdef",
                "name": "test-span",
                "kind": 1,
                "startTimeUnixNano": "'$(date +%s%N)'",
                "endTimeUnixNano": "'$(($(date +%s%N) + 1000000000))'",
                "attributes": [
                  {
                    "key": "http.method",
                    "value": {
                      "stringValue": "GET"
                    }
                  }
                ]
              }
            ]
          }
        ]
      }
    ]
  }'

echo "Test trace sent!"
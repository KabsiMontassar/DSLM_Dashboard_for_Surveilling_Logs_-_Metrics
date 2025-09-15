#!/bin/bash

# Professional DSLM Demo Data Generator
# Creates realistic microservices traces for demonstration

echo "🚀 Starting Professional DSLM Demo Data Generation"
echo "================================================="

# Generate 50 professional traces with realistic patterns
echo "📊 Generating 50 professional microservice traces..."

for i in {1..50}; do
    ./send_test_trace.sh
    
    # Add some realistic delays between requests
    sleep_time=$(echo "scale=2; $RANDOM / 32767 * 0.5" | bc -l 2>/dev/null || echo "0.1")
    sleep $sleep_time
    
    # Progress indicator
    if [ $((i % 10)) -eq 0 ]; then
        echo "📈 Generated $i traces..."
    fi
done

echo ""
echo "✅ Demo data generation complete!"
echo "📊 Generated 50 professional traces across multiple services"
echo ""
echo "🔍 View in Grafana:"
echo "   → http://localhost:3000"
echo "   → Explore → Tempo → Search: {}"
echo ""
echo "🎯 Try these professional queries:"
echo "   → {service.name=\"user-authentication\"}"
echo "   → {service.name=\"payment-gateway\"}"
echo "   → {http.status_code=500}"
echo "   → {cloud.region=\"us-east-1\"}"
echo "   → {team=\"platform-engineering\"}"
echo ""
echo "⏱️  Wait 30-60 seconds for traces to be fully indexed"
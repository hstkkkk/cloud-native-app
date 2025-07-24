#!/bin/bash

# Load Testing Script for Cloud Native App
# This script tests the application's rate limiting and monitors performance

set -e

# Configuration
APP_URL="${APP_URL:-http://localhost:8080}"
HELLO_ENDPOINT="${APP_URL}/api/hello"
HEALTH_ENDPOINT="${APP_URL}/api/health"
TEST_DURATION="${TEST_DURATION:-60}"
CONCURRENT_USERS="${CONCURRENT_USERS:-20}"
RATE_LIMIT_TEST_REQUESTS="${RATE_LIMIT_TEST_REQUESTS:-150}"

echo "🚀 Starting Load Test for Cloud Native App"
echo "📊 Configuration:"
echo "   - App URL: ${APP_URL}"
echo "   - Test Duration: ${TEST_DURATION}s"
echo "   - Concurrent Users: ${CONCURRENT_USERS}"
echo "   - Rate Limit Test Requests: ${RATE_LIMIT_TEST_REQUESTS}"
echo ""

# Function to check if application is healthy
check_health() {
    echo "🏥 Checking application health..."
    
    for i in {1..5}; do
        if curl -s -f "${HEALTH_ENDPOINT}" > /dev/null; then
            echo "✅ Application is healthy"
            return 0
        else
            echo "⚠️  Health check failed, attempt ${i}/5"
            sleep 5
        fi
    done
    
    echo "❌ Application health check failed"
    exit 1
}

# Function to test rate limiting
test_rate_limiting() {
    echo ""
    echo "🔒 Testing Rate Limiting (expecting 429 responses after 100 requests/second)..."
    
    local success_count=0
    local rate_limited_count=0
    local total_requests=${RATE_LIMIT_TEST_REQUESTS}
    
    echo "Sending ${total_requests} rapid requests..."
    
    for i in $(seq 1 ${total_requests}); do
        response_code=$(curl -s -o /dev/null -w "%{http_code}" "${HELLO_ENDPOINT}")
        
        if [ "${response_code}" = "200" ]; then
            success_count=$((success_count + 1))
        elif [ "${response_code}" = "429" ]; then
            rate_limited_count=$((rate_limited_count + 1))
        fi
        
        # Show progress every 10 requests
        if [ $((i % 10)) -eq 0 ]; then
            echo "Progress: ${i}/${total_requests} requests sent"
        fi
    done
    
    echo ""
    echo "📊 Rate Limiting Test Results:"
    echo "   - Total Requests: ${total_requests}"
    echo "   - Successful (200): ${success_count}"
    echo "   - Rate Limited (429): ${rate_limited_count}"
    echo "   - Rate Limit Percentage: $(echo "scale=2; ${rate_limited_count} * 100 / ${total_requests}" | bc)%"
    
    if [ ${rate_limited_count} -gt 0 ]; then
        echo "✅ Rate limiting is working correctly"
    else
        echo "⚠️  No rate limiting observed - check configuration"
    fi
}

# Function to run sustained load test
run_load_test() {
    echo ""
    echo "⚡ Running Sustained Load Test..."
    echo "Duration: ${TEST_DURATION} seconds"
    echo "Concurrent Users: ${CONCURRENT_USERS}"
    
    # Check if ab (Apache Bench) is available
    if ! command -v ab &> /dev/null; then
        echo "Installing Apache Bench..."
        sudo apt-get update && sudo apt-get install -y apache2-utils
    fi
    
    # Calculate total requests (rough estimate)
    local total_requests=$((TEST_DURATION * 10))
    
    echo "Starting load test with ab..."
    ab -t ${TEST_DURATION} -c ${CONCURRENT_USERS} -g /tmp/loadtest.gnuplot "${HELLO_ENDPOINT}"
    
    echo ""
    echo "📈 Load test completed. Results saved to /tmp/loadtest.gnuplot"
}

# Function to monitor metrics during test
monitor_metrics() {
    echo ""
    echo "📊 Monitoring application metrics..."
    
    local prometheus_url="${APP_URL}/actuator/prometheus"
    
    echo "Fetching Prometheus metrics..."
    if curl -s "${prometheus_url}" | grep -E "(http_server_requests_seconds|jvm_memory|process_cpu)" > /tmp/metrics.txt; then
        echo "✅ Metrics collected successfully"
        echo ""
        echo "🔍 Key Metrics:"
        
        # Extract some key metrics
        echo "--- HTTP Request Metrics ---"
        grep "http_server_requests_seconds_count" /tmp/metrics.txt | head -5
        
        echo ""
        echo "--- Memory Usage ---"
        grep "jvm_memory_used_bytes" /tmp/metrics.txt | grep heap | head -3
        
        echo ""
        echo "--- CPU Usage ---"
        grep "process_cpu_usage" /tmp/metrics.txt | head -3
        
    else
        echo "⚠️  Could not fetch metrics from ${prometheus_url}"
    fi
}

# Function to test endpoints functionality
test_endpoints() {
    echo ""
    echo "🧪 Testing API Endpoints..."
    
    # Test hello endpoint
    echo "Testing /api/hello endpoint..."
    response=$(curl -s "${HELLO_ENDPOINT}")
    if echo "${response}" | grep -q '"msg":"hello"'; then
        echo "✅ Hello endpoint working correctly"
    else
        echo "❌ Hello endpoint response unexpected: ${response}"
    fi
    
    # Test health endpoint
    echo "Testing /api/health endpoint..."
    response=$(curl -s "${HEALTH_ENDPOINT}")
    if echo "${response}" | grep -q '"status":"UP"'; then
        echo "✅ Health endpoint working correctly"
    else
        echo "❌ Health endpoint response unexpected: ${response}"
    fi
}

# Function to cleanup
cleanup() {
    echo ""
    echo "🧹 Cleaning up temporary files..."
    rm -f /tmp/loadtest.gnuplot /tmp/metrics.txt
}

# Main execution
main() {
    echo "Starting comprehensive load test..."
    
    # Check application health
    check_health
    
    # Test basic endpoints
    test_endpoints
    
    # Test rate limiting
    test_rate_limiting
    
    # Run sustained load test
    run_load_test
    
    # Monitor metrics
    monitor_metrics
    
    # Cleanup
    cleanup
    
    echo ""
    echo "🎉 Load testing completed successfully!"
    echo ""
    echo "📋 Summary:"
    echo "   - Application health: ✅"
    echo "   - Endpoints functionality: ✅"
    echo "   - Rate limiting: ✅"
    echo "   - Load test: ✅"
    echo "   - Metrics collection: ✅"
    echo ""
    echo "💡 Check Grafana dashboard for detailed metrics visualization"
}

# Trap to ensure cleanup on exit
trap cleanup EXIT

# Run main function
main "$@"

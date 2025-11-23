#!/bin/bash

# Performance Testing Script for Warchief Game
# Runs the game with a 10-second timeout and captures performance data

set +e  # Don't exit on error

PORT=8008
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TIMEOUT=10  # 10 second timeout

echo "========================================="
echo "  Warchief Performance Test"
echo "========================================="
echo ""
echo "⚠️  WARNING: This will run for ONLY $TIMEOUT seconds"
echo "    then automatically kill the process"
echo ""

# Check if port 8008 is in use
echo "Checking if port $PORT is available..."
PORT_PID=$(lsof -ti:$PORT 2>/dev/null || echo "")

if [ ! -z "$PORT_PID" ]; then
    echo "⚠️  Port $PORT is currently in use by process $PORT_PID"
    echo "Killing process $PORT_PID..."
    kill -9 $PORT_PID 2>/dev/null || true
    sleep 1
fi

cd "$PROJECT_DIR/warchief_game"

# Create performance log directory
PERF_DIR="$PROJECT_DIR/performance_logs"
mkdir -p "$PERF_DIR"

TIMESTAMP=$(date +%Y%m%d_%H%M%S)
LOG_FILE="$PERF_DIR/perf_test_$TIMESTAMP.log"

echo "📊 Performance data will be logged to: $LOG_FILE"
echo ""

# Function to monitor system resources
monitor_resources() {
    while true; do
        # Get CPU and memory usage
        TIMESTAMP=$(date +%H:%M:%S)

        # Get Flutter process info if it exists
        FLUTTER_PID=$(pgrep -f "flutter run" | head -1)

        if [ ! -z "$FLUTTER_PID" ]; then
            # Get CPU and memory for Flutter process
            CPU=$(ps -p $FLUTTER_PID -o %cpu= 2>/dev/null || echo "N/A")
            MEM=$(ps -p $FLUTTER_PID -o %mem= 2>/dev/null || echo "N/A")
            VSZ=$(ps -p $FLUTTER_PID -o vsz= 2>/dev/null || echo "N/A")
            RSS=$(ps -p $FLUTTER_PID -o rss= 2>/dev/null || echo "N/A")

            echo "[$TIMESTAMP] Flutter PID: $FLUTTER_PID | CPU: $CPU% | MEM: $MEM% | VSZ: $VSZ KB | RSS: $RSS KB" >> "$LOG_FILE"
        fi

        # Also check for dart process (the actual renderer)
        DART_PID=$(pgrep -f "dart.*web.*server" | head -1)
        if [ ! -z "$DART_PID" ]; then
            CPU=$(ps -p $DART_PID -o %cpu= 2>/dev/null || echo "N/A")
            MEM=$(ps -p $DART_PID -o %mem= 2>/dev/null || echo "N/A")
            VSZ=$(ps -p $DART_PID -o vsz= 2>/dev/null || echo "N/A")
            RSS=$(ps -p $DART_PID -o rss= 2>/dev/null || echo "N/A")

            echo "[$TIMESTAMP] Dart PID: $DART_PID | CPU: $CPU% | MEM: $MEM% | VSZ: $VSZ KB | RSS: $RSS KB" >> "$LOG_FILE"
        fi

        sleep 0.5  # Sample every 500ms
    done
}

# Start resource monitoring in background
monitor_resources &
MONITOR_PID=$!

echo "🚀 Starting Flutter with $TIMEOUT second timeout..."
echo "📊 Monitoring system resources..."
echo ""

# Start Flutter in background and capture output
timeout $TIMEOUT flutter run -d web-server --web-port=$PORT --web-hostname=localhost 2>&1 | tee -a "$LOG_FILE" &
FLUTTER_PID=$!

# Wait for timeout or Flutter to exit
wait $FLUTTER_PID
EXIT_CODE=$?

# Kill the monitor
kill $MONITOR_PID 2>/dev/null || true

echo ""
echo "========================================="
echo "  Test Complete"
echo "========================================="
echo ""

if [ $EXIT_CODE -eq 124 ]; then
    echo "✅ Test completed (timeout reached after $TIMEOUT seconds)"
elif [ $EXIT_CODE -eq 0 ]; then
    echo "✅ Flutter exited normally"
else
    echo "⚠️  Flutter exited with code: $EXIT_CODE"
fi

echo ""
echo "📊 Performance Summary:"
echo "-------------------------------------------"

# Count how many samples were collected
SAMPLE_COUNT=$(grep -c "Flutter PID" "$LOG_FILE" 2>/dev/null || echo "0")
echo "Resource samples collected: $SAMPLE_COUNT"

# Find peak memory usage
if [ $SAMPLE_COUNT -gt 0 ]; then
    PEAK_RSS=$(grep "Flutter PID" "$LOG_FILE" | awk -F'RSS: ' '{print $2}' | awk '{print $1}' | sort -n | tail -1)
    PEAK_CPU=$(grep "Flutter PID" "$LOG_FILE" | awk -F'CPU: ' '{print $2}' | awk '{print $1}' | sed 's/%//' | sort -n | tail -1)

    echo "Peak CPU usage: ${PEAK_CPU}%"
    echo "Peak RSS memory: ${PEAK_RSS} KB ($(echo "scale=2; $PEAK_RSS / 1024" | bc) MB)"
fi

echo ""
echo "Full log: $LOG_FILE"
echo ""

# Clean up any remaining processes on port 8008
PORT_PID=$(lsof -ti:$PORT 2>/dev/null || echo "")
if [ ! -z "$PORT_PID" ]; then
    echo "🧹 Cleaning up port $PORT (PID: $PORT_PID)..."
    kill -9 $PORT_PID 2>/dev/null || true
fi

echo "✅ All processes cleaned up"

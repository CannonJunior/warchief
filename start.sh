#!/bin/bash

# Warchief Game Start Script
# Checks if port 8008 is in use and kills the process if needed
# Then starts the Flutter web server

set -e

PORT=8008
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "========================================="
echo "  Warchief 3D Isometric Game Launcher"
echo "========================================="
echo ""

# Kill stale Flutter processes from previous sessions
STALE_PIDS=$(ps aux | grep -E 'flutter.*(run|web-server|web-port)' | grep -v grep | awk '{print $2}' || true)
if [ ! -z "$STALE_PIDS" ]; then
    STALE_COUNT=$(echo "$STALE_PIDS" | wc -w)
    echo "Found $STALE_COUNT stale Flutter process(es), cleaning up..."
    echo "$STALE_PIDS" | xargs kill -9 2>/dev/null || true
    sleep 1
    echo "✅ Stale processes killed"
else
    echo "✅ No stale Flutter processes found"
fi

# Also kill any defunct dart processes from previous flutter runs
DEFUNCT_PIDS=$(ps aux | grep -E 'dart.*(flutter_tool|frontend_server)' | grep -v grep | awk '{print $2}' || true)
if [ ! -z "$DEFUNCT_PIDS" ]; then
    DEFUNCT_COUNT=$(echo "$DEFUNCT_PIDS" | wc -w)
    echo "Found $DEFUNCT_COUNT stale Dart subprocess(es), cleaning up..."
    echo "$DEFUNCT_PIDS" | xargs kill -9 2>/dev/null || true
    sleep 1
    echo "✅ Stale Dart subprocesses killed"
fi

# Check if port 8008 is still in use after cleanup
echo "Checking if port $PORT is available..."
PORT_PID=$(lsof -ti:$PORT 2>/dev/null || echo "")

if [ ! -z "$PORT_PID" ]; then
    echo "⚠️  Port $PORT is still in use by process $PORT_PID"
    echo "Killing process $PORT_PID..."
    kill -9 $PORT_PID 2>/dev/null || true
    sleep 1
    echo "✅ Process killed successfully"
else
    echo "✅ Port $PORT is available"
fi

echo ""

# Check if Flutter is installed
if ! command -v flutter &> /dev/null; then
    echo "❌ Error: Flutter is not installed or not in PATH"
    echo "Please install Flutter from https://docs.flutter.dev/get-started/install"
    exit 1
fi

echo "Flutter version:"
flutter --version | head -n 1

echo ""

# Determine the actual game directory
GAME_DIR="$PROJECT_DIR"
if [ -d "$PROJECT_DIR/warchief_game" ]; then
    GAME_DIR="$PROJECT_DIR/warchief_game"
fi

# Check if we have a Flutter project
if [ ! -f "$GAME_DIR/pubspec.yaml" ]; then
    echo "⚠️  No Flutter project found in $GAME_DIR"
    echo "Creating new Flutter project..."
    cd "$PROJECT_DIR"
    flutter create --platforms=web --org=com.warchief warchief_game
    GAME_DIR="$PROJECT_DIR/warchief_game"
fi

cd "$GAME_DIR"

# Generate source tree for Settings panel
echo "Generating source tree..."
if [ -f "$GAME_DIR/scripts/generate_source_tree.py" ]; then
    python3 "$GAME_DIR/scripts/generate_source_tree.py" \
        --root "$GAME_DIR" \
        --output "$GAME_DIR/assets/data/source-tree.json" \
        --project-name "warchief_game" 2>/dev/null || true
    echo "✅ Source tree generated"
fi

# Get Flutter dependencies
echo "Getting Flutter dependencies..."
flutter pub get

echo ""
echo "========================================="
echo "  Starting Warchief on http://localhost:$PORT"
echo "========================================="
echo ""
echo "Press Ctrl+C to stop the server"
echo ""

# Start Flutter web server on port 8008
flutter run -d web-server --web-port=$PORT --web-hostname=localhost

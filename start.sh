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

# Check if port 8008 is in use
echo "Checking if port $PORT is available..."
PORT_PID=$(lsof -ti:$PORT 2>/dev/null || echo "")

if [ ! -z "$PORT_PID" ]; then
    echo "⚠️  Port $PORT is currently in use by process $PORT_PID"
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

# Check if we're in a Flutter project
if [ ! -f "$PROJECT_DIR/pubspec.yaml" ]; then
    echo "⚠️  No Flutter project found in $PROJECT_DIR"
    echo "Creating new Flutter project..."
    cd "$PROJECT_DIR"
    flutter create --platforms=web --org=com.warchief warchief_game
    cd warchief_game
    PROJECT_DIR="$PROJECT_DIR/warchief_game"
fi

cd "$PROJECT_DIR"

# Generate source tree for Settings panel
echo "Generating source tree..."
GAME_DIR="$PROJECT_DIR"
# Check if we're in parent directory (warchief/) or game directory (warchief_game/)
if [ -d "$PROJECT_DIR/warchief_game" ]; then
    GAME_DIR="$PROJECT_DIR/warchief_game"
fi
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

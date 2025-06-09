#!/usr/bin/env bash

#
# Quick test of the hyperfine benchmark functionality
# This runs a minimal benchmark to demonstrate the setup
#

set -euo pipefail

# Colors for output
readonly GREEN='\033[0;32m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

echo -e "${BLUE}🚀 Quick Hyperfine Benchmark Test${NC}"
echo "=================================="
echo

# Check if hyperfine is available
if ! command -v hyperfine &> /dev/null; then
    echo "❌ hyperfine is not installed. Please install it first:"
    echo "  macOS: brew install hyperfine"
    echo "  Linux: check your package manager or cargo install hyperfine"
    exit 1
fi

# Check if binaries exist
if [[ ! -f "./rust/target/release/rotate_cli" ]]; then
    echo "❌ Rust binary not found. Please build it first:"
    echo "  cd rust && cargo build --release"
    exit 1
fi

if [[ ! -f "./go/bin/rotate" ]]; then
    echo "❌ Go binary not found. Please build it first:"
    echo "  cd go && go build -o ./bin/rotate ./cmd/rotate"
    exit 1
fi

if [[ ! -f "./typescript/dist/index.js" ]]; then
    echo "❌ TypeScript binary not found. Please build it first:"
    echo "  cd typescript && npm run build"
    exit 1
fi

# Check if Python virtual environment and package are available
if [[ ! -f "./python/venv/bin/python" ]]; then
    echo "❌ Python virtual environment not found. Please create it first:"
    echo "  cd python && python -m venv venv && source venv/bin/activate && pip install -e \".[dev]\""
    exit 1
fi

if ! ./python/venv/bin/python -c "import rotate_cli" &> /dev/null; then
    echo "❌ Python package not found in venv. Please install it first:"
    echo "  cd python && source venv/bin/activate && pip install -e \".[dev]\""
    exit 1
fi

# Create a larger test file to get more meaningful benchmarks
mkdir -p ./benchmarks/results
{
    echo "id,json"
    # Generate 50 rows with various matrix sizes for more substantial workload
    for i in {1..50}; do
        case $((i % 4)) in
            0) # 2x2 matrices  
                echo "${i},\"[${i}, $((i+1)), $((i+2)), $((i+3))]\""
                ;;
            1) # 3x3 matrices
                echo "${i},\"[${i}, $((i+1)), $((i+2)), $((i+3)), $((i+4)), $((i+5)), $((i+6)), $((i+7)), $((i+8))]\""
                ;;
            2) # 4x4 matrices
                nums=""
                for j in {0..15}; do
                    if [ $j -eq 0 ]; then
                        nums="$((i+j))"
                    else
                        nums="${nums}, $((i+j))"
                    fi
                done
                echo "${i},\"[${nums}]\""
                ;;
            3) # 1x1 matrices (some simple cases)
                echo "${i},\"[${i}]\""
                ;;
        esac
    done
} > ./benchmarks/results/quick_test.csv

echo "Running quick benchmark comparison..."
echo

# Run a simple comparison
hyperfine \
    --shell=none \
    --warmup 2 \
    --min-runs 5 \
    --max-runs 10 \
    --export-markdown "./benchmarks/results/quick_test_results.md" \
    --command-name "🦀 Rust CLI" "./rust/target/release/rotate_cli ./benchmarks/results/quick_test.csv" \
    --command-name "🐹 Go CLI" "./go/bin/rotate ./benchmarks/results/quick_test.csv" \
    --command-name "📜 TypeScript CLI" "node ./typescript/dist/index.js ./benchmarks/results/quick_test.csv" \
    --command-name "🐍 Python CLI" "./python/venv/bin/python -m rotate_cli ./benchmarks/results/quick_test.csv"

echo
echo -e "${GREEN}✅ Quick test completed!${NC}"
echo "📄 Results saved to: ./benchmarks/results/quick_test_results.md"
echo

# Show the markdown results
if [[ -f "./benchmarks/results/quick_test_results.md" ]]; then
    echo "📊 Results Summary:"
    echo "==================="
    cat "./benchmarks/results/quick_test_results.md"
fi

# Cleanup
rm -f ./benchmarks/results/quick_test.csv 
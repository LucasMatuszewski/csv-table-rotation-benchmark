#!/usr/bin/env bash

#
# Cross-language CLI Performance Benchmarks using Hyperfine
#
# This script benchmarks the Rust and TypeScript implementations of the
# CSV table rotation CLI tool using hyperfine. It focuses on end-to-end
# CLI performance rather than micro-benchmarks.
#
# Based on best practices from:
# - https://github.com/sharkdp/hyperfine
# - Internal rotation_bench.rs for test case inspiration
#

set -euo pipefail

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

# Configuration
readonly RUST_BINARY="./rust/target/release/rotate_cli"
readonly TS_BINARY="node ./typescript/dist/index.js"
readonly PYTHON_BINARY="./python/venv/bin/python -m rotate_cli"
readonly GO_BINARY="./go/bin/rotate"
readonly INPUT_SAMPLE="./input-samples/sample-1k.csv"
readonly BENCHMARKS_DIR="./benchmarks"
readonly RESULTS_DIR="${BENCHMARKS_DIR}/results"

# Hyperfine options - balanced for reasonable runtime vs statistical significance
readonly MIN_RUNS=10
readonly MAX_RUNS=20
readonly WARMUP_RUNS=3

# Create results directory
mkdir -p "${RESULTS_DIR}"

# Helper functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

check_dependencies() {
    log_info "Checking dependencies..."
    
    # Check if hyperfine is installed
    if ! command -v hyperfine &> /dev/null; then
        log_error "hyperfine is not installed. Please install it first:"
        echo "  macOS: brew install hyperfine"
        echo "  Linux: check your package manager or cargo install hyperfine"
        exit 1
    fi
    
    # Check if Rust binary exists and is built in release mode
    if [[ ! -f "${RUST_BINARY}" ]]; then
        log_warning "Rust binary not found. Building in release mode..."
        (cd rust && cargo build --release)
        
        if [[ ! -f "${RUST_BINARY}" ]]; then
            log_error "Failed to build Rust binary"
            exit 1
        fi
    fi
    
    # Check if TypeScript is compiled
    if [[ ! -f "./typescript/dist/index.js" ]]; then
        log_warning "TypeScript not compiled. Building..."
        (cd typescript && npm install && npm run build)
        
        if [[ ! -f "./typescript/dist/index.js" ]]; then
            log_error "Failed to build TypeScript"
            exit 1
        fi
    fi
    
    # Check if Go binary exists and is built
    if [[ ! -f "${GO_BINARY}" ]]; then
        log_warning "Go binary not found. Building..."
        (cd go && go build -o ./bin/rotate ./cmd/rotate)
        
        if [[ ! -f "${GO_BINARY}" ]]; then
            log_error "Failed to build Go binary"
            exit 1
        fi
    fi
    
    # Check if input sample exists
    if [[ ! -f "${INPUT_SAMPLE}" ]]; then
        log_error "Input sample file not found: ${INPUT_SAMPLE}"
        exit 1
    fi
    
    # Check if node is available for TypeScript
    if ! command -v node &> /dev/null; then
        log_error "Node.js is required for TypeScript benchmarks"
        exit 1
    fi
    
    # Check if go is available for Go
    if ! command -v go &> /dev/null; then
        log_error "Go is required for Go benchmarks"
        exit 1
    fi
    
    # Check if Python virtual environment exists and package is installed
    if [[ ! -f "./python/venv/bin/python" ]]; then
        log_warning "Python virtual environment not found. Creating..."
        (cd python && python -m venv venv)
    fi
    
    if ! ./python/venv/bin/python -c "import rotate_cli" &> /dev/null; then
        log_warning "Python package not installed in venv. Installing..."
        (cd python && ./venv/bin/pip install -e ".[dev]")
        
        if ! ./python/venv/bin/python -c "import rotate_cli" &> /dev/null; then
            log_error "Failed to install Python package in venv"
            exit 1
        fi
    fi
    
    log_success "All dependencies check passed"
}



benchmark_basic_performance() {
    local test_data_dir="$1"
    local timestamp=$(date +"%Y%m%d_%H%M%S")
    
    log_info "Running basic performance benchmarks..."
    
    # Basic comparison using the medium dataset
    log_info "Benchmarking with medium dataset..."
    
    hyperfine \
        --shell=none \
        --warmup ${WARMUP_RUNS} \
        --min-runs ${MIN_RUNS} \
        --max-runs ${MAX_RUNS} \
        --export-markdown "${RESULTS_DIR}/basic_performance_${timestamp}.md" \
        --export-json "${RESULTS_DIR}/basic_performance_${timestamp}.json" \
        --export-csv "${RESULTS_DIR}/basic_performance_${timestamp}.csv" \
        --command-name "Rust CLI" "${RUST_BINARY} ${test_data_dir}/medium.csv" \
        --command-name "Go CLI" "${GO_BINARY} ${test_data_dir}/medium.csv" \
        --command-name "TypeScript CLI" "${TS_BINARY} ${test_data_dir}/medium.csv" \
        --command-name "Python CLI" "${PYTHON_BINARY} ${test_data_dir}/medium.csv"
    
    log_success "Basic performance benchmark completed"
}

benchmark_data_size_scaling() {
    local test_data_dir="$1"
    local timestamp=$(date +"%Y%m%d_%H%M%S")
    
    log_info "Running data size scaling benchmarks..."
    
    # Compare performance across different data sizes
    log_info "Benchmarking with small dataset..."
    hyperfine \
        --shell=none \
        --warmup ${WARMUP_RUNS} \
        --min-runs ${MIN_RUNS} \
        --max-runs ${MAX_RUNS} \
        --export-markdown "${RESULTS_DIR}/scaling_small_${timestamp}.md" \
        --command-name "Rust (small)" "${RUST_BINARY} ${test_data_dir}/small.csv" \
        --command-name "Go (small)" "${GO_BINARY} ${test_data_dir}/small.csv" \
        --command-name "TypeScript (small)" "${TS_BINARY} ${test_data_dir}/small.csv" \
        --command-name "Python (small)" "${PYTHON_BINARY} ${test_data_dir}/small.csv"
    
    log_info "Benchmarking with medium dataset..."
    hyperfine \
        --shell=none \
        --warmup ${WARMUP_RUNS} \
        --min-runs ${MIN_RUNS} \
        --max-runs ${MAX_RUNS} \
        --export-markdown "${RESULTS_DIR}/scaling_medium_${timestamp}.md" \
        --command-name "Rust (medium)" "${RUST_BINARY} ${test_data_dir}/medium.csv" \
        --command-name "Go (medium)" "${GO_BINARY} ${test_data_dir}/medium.csv" \
        --command-name "TypeScript (medium)" "${TS_BINARY} ${test_data_dir}/medium.csv" \
        --command-name "Python (medium)" "${PYTHON_BINARY} ${test_data_dir}/medium.csv"
    
    log_info "Benchmarking with large dataset..."
    hyperfine \
        --shell=none \
        --warmup ${WARMUP_RUNS} \
        --min-runs ${MIN_RUNS} \
        --max-runs ${MAX_RUNS} \
        --export-markdown "${RESULTS_DIR}/scaling_large_${timestamp}.md" \
        --command-name "Rust (large)" "${RUST_BINARY} ${test_data_dir}/large.csv" \
        --command-name "Go (large)" "${GO_BINARY} ${test_data_dir}/large.csv" \
        --command-name "TypeScript (large)" "${TS_BINARY} ${test_data_dir}/large.csv" \
        --command-name "Python (large)" "${PYTHON_BINARY} ${test_data_dir}/large.csv"
    
    log_success "Data size scaling benchmarks completed"
}

benchmark_startup_overhead() {
    local test_data_dir="$1"
    local timestamp=$(date +"%Y%m%d_%H%M%S")
    
    log_info "Running startup overhead benchmarks..."
    
    # Focus on startup time by using minimal data and more runs
    hyperfine \
        --shell=none \
        --warmup 5 \
        --min-runs 15 \
        --max-runs 25 \
        --export-markdown "${RESULTS_DIR}/startup_overhead_${timestamp}.md" \
        --command-name "Rust startup" "${RUST_BINARY} ${test_data_dir}/small.csv" \
        --command-name "Go startup" "${GO_BINARY} ${test_data_dir}/small.csv" \
        --command-name "TypeScript startup" "${TS_BINARY} ${test_data_dir}/small.csv" \
        --command-name "Python startup" "${PYTHON_BINARY} ${test_data_dir}/small.csv"
    
    log_success "Startup overhead benchmarks completed"
}

benchmark_with_preparation() {
    local test_data_dir="$1"
    local timestamp=$(date +"%Y%m%d_%H%M%S")
    
    log_info "Running benchmarks with cache clearing (cold cache simulation)..."
    
    # Benchmark with cache clearing to simulate cold cache performance
    # Note: This requires appropriate permissions on some systems
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        # Linux cache clearing (requires sudo)
        log_warning "Linux detected. Cache clearing requires sudo permissions."
        log_info "Running cold cache benchmark (Linux)..."
        
        if sudo -n true 2>/dev/null; then
                         hyperfine \
                 --shell=none \
                 --warmup 2 \
                 --min-runs 8 \
                 --max-runs 15 \
                 --prepare 'sync && sudo sh -c "echo 3 > /proc/sys/vm/drop_caches"' \
                 --export-markdown "${RESULTS_DIR}/cold_cache_${timestamp}.md" \
                 --command-name "Rust (cold cache)" "${RUST_BINARY} ${test_data_dir}/large.csv" \
                 --command-name "Go (cold cache)" "${GO_BINARY} ${test_data_dir}/large.csv" \
                 --command-name "TypeScript (cold cache)" "${TS_BINARY} ${test_data_dir}/large.csv"
            log_success "Cold cache benchmarks completed"
        else
            log_warning "Sudo access not available. Skipping cold cache benchmarks."
        fi
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS - no good way to clear caches without sudo, so we skip
        log_warning "macOS detected. Skipping cold cache benchmarks (requires special permissions)."
    else
        log_warning "Unknown OS. Skipping cold cache benchmarks."
    fi
}

run_comprehensive_comparison() {
    local test_data_dir="$1"
    local timestamp=$(date +"%Y%m%d_%H%M%S")
    
    log_info "Running comprehensive CLI comparison..."
    
    # Comprehensive comparison with detailed output
    hyperfine \
        --shell=none \
        --warmup ${WARMUP_RUNS} \
        --min-runs 15 \
        --max-runs 25 \
        --export-markdown "${RESULTS_DIR}/comprehensive_comparison_${timestamp}.md" \
        --export-json "${RESULTS_DIR}/comprehensive_comparison_${timestamp}.json" \
        --style full \
        --command-name "🦀 Rust Implementation" "${RUST_BINARY} ${test_data_dir}/large.csv" \
        --command-name "🐹 Go Implementation" "${GO_BINARY} ${test_data_dir}/large.csv" \
        --command-name "📜 TypeScript Implementation" "${TS_BINARY} ${test_data_dir}/large.csv" \
        --command-name "🐍 Python Implementation" "${PYTHON_BINARY} ${test_data_dir}/large.csv"
    
    log_success "Comprehensive comparison completed"
}

cleanup() {
    log_info "Cleaning up temporary files..."
    if [[ -d "${RESULTS_DIR}/temp_data" ]]; then
        rm -rf "${RESULTS_DIR}/temp_data"
    fi
    log_success "Cleanup completed"
}

print_summary() {
    local results_count=$(find "${RESULTS_DIR}" -name "*.md" -newer "${RESULTS_DIR}" 2>/dev/null | wc -l || echo "0")
    
    echo
    echo "==============================================="
    echo "🎯 Benchmark Results Summary"
    echo "==============================================="
    echo
    echo "📁 Results location: ${RESULTS_DIR}"
    echo "📊 Generated reports: ${results_count} markdown files"
    echo
    echo "📋 Available reports:"
    find "${RESULTS_DIR}" -name "*.md" -newer "${RESULTS_DIR}" 2>/dev/null | sort | sed 's/^/   • /' || echo "   No new reports found"
    echo
    echo "💡 Tip: View markdown files for formatted results, or use JSON/CSV for further analysis"
    echo
    
    # Show quick summary of the comprehensive comparison if it exists
    local comprehensive_file=$(find "${RESULTS_DIR}" -name "comprehensive_comparison_*.md" -newer "${RESULTS_DIR}" 2>/dev/null | head -1)
    if [[ -n "${comprehensive_file}" && -f "${comprehensive_file}" ]]; then
        echo "🏆 Quick Results (from comprehensive comparison):"
        echo "=================================================="
        tail -10 "${comprehensive_file}" | head -8
        echo
    fi
}

# Trap to ensure cleanup on exit
trap cleanup EXIT

main() {
    echo "🚀 CSV Table Rotation CLI - Cross-Language Performance Benchmarks"
    echo "=================================================================="
    echo
    
    check_dependencies
    
    # Generate test data
    log_info "Generating test data for different scenarios..."
    local test_data_dir="${RESULTS_DIR}/temp_data"
    mkdir -p "${test_data_dir}"
    
    # Small data (for startup overhead tests - 1x1 to 3x3 matrices)
    log_info "Generating small test dataset..."
    {
        echo "id,json"
        echo '1,"[1]"'  # 1x1
        echo '2,"[1, 2, 3, 4]"'  # 2x2  
        echo '3,"[1, 2, 3, 4, 5, 6, 7, 8, 9]"'  # 3x3
        echo '4,"[1, 2, 3]"'  # Invalid
        echo '5,"[40, 20, 90, 10]"'  # 2x2
    } > "${test_data_dir}/small.csv"

    # Medium data (matrices up to 10x10 - for regular comparison)
    log_info "Generating medium test dataset..."
    {
        echo "id,json"
        # Generate 50 rows with matrix sizes 1x1 to 10x10
        for i in {1..50}; do
            case $((i % 6)) in
                0) # 1x1 matrices
                    echo "${i},\"[${i}]\""
                    ;;
                1) # 4x4 matrices (16 elements)
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
                2) # 6x6 matrices (36 elements)
                    nums=""
                    for j in {0..35}; do
                        if [ $j -eq 0 ]; then
                            nums="$((i+j))"
                        else
                            nums="${nums}, $((i+j))"
                        fi
                    done
                    echo "${i},\"[${nums}]\""
                    ;;
                3) # 8x8 matrices (64 elements)
                    nums=""
                    for j in {0..63}; do
                        if [ $j -eq 0 ]; then
                            nums="$((i+j))"
                        else
                            nums="${nums}, $((i+j))"
                        fi
                    done
                    echo "${i},\"[${nums}]\""
                    ;;
                4) # 10x10 matrices (100 elements)
                    nums=""
                    for j in {0..99}; do
                        if [ $j -eq 0 ]; then
                            nums="$((i+j))"
                        else
                            nums="${nums}, $((i+j))"
                        fi
                    done
                    echo "${i},\"[${nums}]\""
                    ;;
                5) # Invalid data
                    echo "${i},\"[1, 2, 3]\""
                    ;;
            esac
        done
    } > "${test_data_dir}/medium.csv"
    
    # Large data (matrices up to 50x50 - for performance scaling tests)
    log_info "Generating large test dataset (this may take a moment)..."
    {
        echo "id,json"
        # Generate rows with large matrix sizes to see performance differences
        for i in {1..100}; do
            case $((i % 7)) in
                0) # 15x15 matrices (225 elements)
                    nums=""
                    for j in {0..224}; do
                        if [ $j -eq 0 ]; then
                            nums="$((i+j))"
                        else
                            nums="${nums}, $((i+j))"
                        fi
                    done
                    echo "${i},\"[${nums}]\""
                    ;;
                1) # 20x20 matrices (400 elements)
                    nums=""
                    for j in {0..399}; do
                        if [ $j -eq 0 ]; then
                            nums="$((i+j))"
                        else
                            nums="${nums}, $((i+j))"
                        fi
                    done
                    echo "${i},\"[${nums}]\""
                    ;;
                2) # 25x25 matrices (625 elements)
                    nums=""
                    for j in {0..624}; do
                        if [ $j -eq 0 ]; then
                            nums="$((i+j))"
                        else
                            nums="${nums}, $((i+j))"
                        fi
                    done
                    echo "${i},\"[${nums}]\""
                    ;;
                3) # 30x30 matrices (900 elements)
                    nums=""
                    for j in {0..899}; do
                        if [ $j -eq 0 ]; then
                            nums="$((i+j))"
                        else
                            nums="${nums}, $((i+j))"
                        fi
                    done
                    echo "${i},\"[${nums}]\""
                    ;;
                4) # 40x40 matrices (1600 elements)
                    nums=""
                    for j in {0..1599}; do
                        if [ $j -eq 0 ]; then
                            nums="$((i+j))"
                        else
                            nums="${nums}, $((i+j))"
                        fi
                    done
                    echo "${i},\"[${nums}]\""
                    ;;
                5) # 50x50 matrices (2500 elements)
                    nums=""
                    for j in {0..2499}; do
                        if [ $j -eq 0 ]; then
                            nums="$((i+j))"
                        else
                            nums="${nums}, $((i+j))"
                        fi
                    done
                    echo "${i},\"[${nums}]\""
                    ;;
                6) # Some invalid data mixed in
                    echo "${i},\"[1, 2, 3, 5, 7]\""
                    ;;
            esac
        done
    } > "${test_data_dir}/large.csv"
    
    log_success "Test data generated in ${test_data_dir}"
    
    # Run benchmarks
    benchmark_basic_performance "${test_data_dir}"
    benchmark_data_size_scaling "${test_data_dir}"
    benchmark_startup_overhead "${test_data_dir}"
    benchmark_with_preparation "${test_data_dir}"
    run_comprehensive_comparison "${test_data_dir}"
    
    # Print summary
    print_summary
    
    log_success "All benchmarks completed successfully! 🎉"
}

# Check if script is being sourced or executed
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi 
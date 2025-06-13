#!/usr/bin/env bash

#
# Cross-language CLI Performance Benchmarks using Hyperfine
#
# This script benchmarks the Rust and TypeScript implementations of the
# CSV table rotation CLI tool using hyperfine. It focuses on end-to-end
# CLI performance rather than micro-benchmarks.
#
# USAGE:
#   ./benchmarks/run_hyperfine.sh
#
# ENVIRONMENT VARIABLES:
#   KEEP_RESULTS=true     - Keep benchmark results after completion (default: false)
#   DISABLE_CLEANUP=true  - Disable all cleanup (for CI/CD) (default: false)
#
# FILE MANAGEMENT:
#   - Persistent datasets: ./input-samples/*.csv (kept between runs)
#   - Temporary results: ./benchmarks/results/*.{md,json,csv} (cleaned by default)
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
readonly TS_NODE_DEFAULT="node ./typescript/dist/index.js"
readonly TS_NODE_PAPAPARSE="./typescript/run-papaparse.sh"
readonly TS_BUN_DEFAULT="bun ./typescript/dist/index.js"
readonly TS_BUN_PAPAPARSE="./typescript/run-bun-papaparse.sh"
readonly PYTHON_BINARY="./python/venv/bin/python -m rotate_cli"
readonly GO_BINARY="./go/bin/rotate"
readonly INPUT_SAMPLE="./input-samples/sample-1k.csv"
readonly BENCHMARKS_DIR="./benchmarks"
readonly RESULTS_DIR="${BENCHMARKS_DIR}/results"
readonly INPUT_SAMPLES_DIR="./input-samples"

# Hyperfine options - balanced for reasonable runtime vs statistical significance
readonly MIN_RUNS=10
readonly MAX_RUNS=20
readonly WARMUP_RUNS=3

# Create results and input samples directories
mkdir -p "${RESULTS_DIR}"
mkdir -p "${INPUT_SAMPLES_DIR}"

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
    
    # Check if bun is available (optional - will skip Bun benchmarks if not found)
    if ! command -v bun &> /dev/null; then
        log_warning "Bun not found. Bun benchmarks will be skipped."
        readonly BUN_AVAILABLE=false
    else
        readonly BUN_AVAILABLE=true
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

generate_test_datasets() {
    log_info "Checking and generating test datasets..."
    
    # Small data (for startup overhead tests - 1x1 to 3x3 matrices)
    if [[ ! -f "${INPUT_SAMPLES_DIR}/small.csv" ]]; then
        log_info "Generating small test dataset..."
        {
            echo "id,json"
            echo '1,"[1]"'  # 1x1
            echo '2,"[1, 2, 3, 4]"'  # 2x2  
            echo '3,"[1, 2, 3, 4, 5, 6, 7, 8, 9]"'  # 3x3
            echo '4,"[1, 2, 3]"'  # Invalid
            echo '5,"[40, 20, 90, 10]"'  # 2x2
        } > "${INPUT_SAMPLES_DIR}/small.csv"
        log_success "Small dataset saved to ${INPUT_SAMPLES_DIR}/small.csv"
    else
        log_info "Using existing small dataset from ${INPUT_SAMPLES_DIR}/small.csv"
    fi

    # Medium data (matrices up to 10x10 - for regular comparison)
    if [[ ! -f "${INPUT_SAMPLES_DIR}/medium.csv" ]]; then
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
        } > "${INPUT_SAMPLES_DIR}/medium.csv"
        log_success "Medium dataset saved to ${INPUT_SAMPLES_DIR}/medium.csv"
    else
        log_info "Using existing medium dataset from ${INPUT_SAMPLES_DIR}/medium.csv"
    fi
    
    # Large data (matrices up to 50x50 - for performance scaling tests)
    if [[ ! -f "${INPUT_SAMPLES_DIR}/large.csv" ]]; then
        log_info "Generating large test dataset (this may take a moment)..."
        {
            echo "id,json"
            # Generate 100 rows with large matrix sizes to see performance differences
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
        } > "${INPUT_SAMPLES_DIR}/large.csv"
        log_success "Large dataset saved to ${INPUT_SAMPLES_DIR}/large.csv"
    else
        log_info "Using existing large dataset from ${INPUT_SAMPLES_DIR}/large.csv"
    fi
    
    # XLarge data (matrices up to 70x70 - 1000 rows for real-world large file scenarios)
    if [[ ! -f "${INPUT_SAMPLES_DIR}/xlarge.csv" ]]; then
        log_info "Generating xlarge test dataset (this will take a few minutes)..."
        {
            echo "id,json"
            # Generate 1000 rows with larger matrix sizes for real-world testing
            for i in {1..1000}; do
                case $((i % 6)) in
                    0) # 30x30 matrices (900 elements)
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
                    1) # 40x40 matrices (1600 elements)
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
                    2) # 50x50 matrices (2500 elements)
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
                    3) # 60x60 matrices (3600 elements)
                        nums=""
                        for j in {0..3599}; do
                            if [ $j -eq 0 ]; then
                                nums="$((i+j))"
                            else
                                nums="${nums}, $((i+j))"
                            fi
                        done
                        echo "${i},\"[${nums}]\""
                        ;;
                    4) # 70x70 matrices (4900 elements)
                        nums=""
                        for j in {0..4899}; do
                            if [ $j -eq 0 ]; then
                                nums="$((i+j))"
                            else
                                nums="${nums}, $((i+j))"
                            fi
                        done
                        echo "${i},\"[${nums}]\""
                        ;;
                    5) # Some invalid data mixed in
                        echo "${i},\"[1, 2, 3, 5, 7]\""
                        ;;
                esac
            done
        } > "${INPUT_SAMPLES_DIR}/xlarge.csv"
        log_success "XLarge dataset saved to ${INPUT_SAMPLES_DIR}/xlarge.csv"
    else
        log_info "Using existing xlarge dataset from ${INPUT_SAMPLES_DIR}/xlarge.csv"
    fi
    
    log_success "All test datasets are ready in ${INPUT_SAMPLES_DIR}"
}

benchmark_js_runtime_comparison() {
    local timestamp=$(date +"%Y%m%d_%H%M%S")
    
    log_info "Running JavaScript runtime & library comparison..."
    
    # Build command array dynamically based on available runtimes
    local commands=()
    
    # Node.js variants (always available)
    commands+=(--command-name "🟢 Node.js + csv-stream" "${TS_NODE_DEFAULT} ${INPUT_SAMPLES_DIR}/medium.csv")
    commands+=(--command-name "🟢 Node.js + PapaParse" "${TS_NODE_PAPAPARSE} ${INPUT_SAMPLES_DIR}/medium.csv")
    
    # Bun variants (if available)
    if [[ "${BUN_AVAILABLE}" == "true" ]]; then
        commands+=(--command-name "🔥 Bun + csv-stream" "${TS_BUN_DEFAULT} ${INPUT_SAMPLES_DIR}/medium.csv")
        commands+=(--command-name "🔥 Bun + PapaParse" "${TS_BUN_PAPAPARSE} ${INPUT_SAMPLES_DIR}/medium.csv")
    fi
    
    hyperfine \
        --shell=none \
        --warmup ${WARMUP_RUNS} \
        --min-runs ${MIN_RUNS} \
        --max-runs ${MAX_RUNS} \
        --export-markdown "${RESULTS_DIR}/js_runtime_comparison_${timestamp}.md" \
        --export-json "${RESULTS_DIR}/js_runtime_comparison_${timestamp}.json" \
        "${commands[@]}"
    
    log_success "JavaScript runtime comparison completed"
}

benchmark_data_size_scaling() {
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
        --command-name "Rust (small)" "${RUST_BINARY} ${INPUT_SAMPLES_DIR}/small.csv" \
        --command-name "Go (small)" "${GO_BINARY} ${INPUT_SAMPLES_DIR}/small.csv" \
        --command-name "TypeScript (small)" "${TS_NODE_DEFAULT} ${INPUT_SAMPLES_DIR}/small.csv" \
        --command-name "Python (small)" "${PYTHON_BINARY} ${INPUT_SAMPLES_DIR}/small.csv"
    
    log_info "Benchmarking with medium dataset..."
    hyperfine \
        --shell=none \
        --warmup ${WARMUP_RUNS} \
        --min-runs ${MIN_RUNS} \
        --max-runs ${MAX_RUNS} \
        --export-markdown "${RESULTS_DIR}/scaling_medium_${timestamp}.md" \
        --command-name "Rust (medium)" "${RUST_BINARY} ${INPUT_SAMPLES_DIR}/medium.csv" \
        --command-name "Go (medium)" "${GO_BINARY} ${INPUT_SAMPLES_DIR}/medium.csv" \
        --command-name "TypeScript (medium)" "${TS_NODE_DEFAULT} ${INPUT_SAMPLES_DIR}/medium.csv" \
        --command-name "Python (medium)" "${PYTHON_BINARY} ${INPUT_SAMPLES_DIR}/medium.csv"
    
    log_info "Benchmarking with large dataset..."
    hyperfine \
        --shell=none \
        --warmup ${WARMUP_RUNS} \
        --min-runs ${MIN_RUNS} \
        --max-runs ${MAX_RUNS} \
        --export-markdown "${RESULTS_DIR}/scaling_large_${timestamp}.md" \
        --command-name "Rust (large)" "${RUST_BINARY} ${INPUT_SAMPLES_DIR}/large.csv" \
        --command-name "Go (large)" "${GO_BINARY} ${INPUT_SAMPLES_DIR}/large.csv" \
        --command-name "TypeScript (large)" "${TS_NODE_DEFAULT} ${INPUT_SAMPLES_DIR}/large.csv" \
        --command-name "Python (large)" "${PYTHON_BINARY} ${INPUT_SAMPLES_DIR}/large.csv"

           
    log_info "Benchmarking with xlarge dataset..."
    hyperfine \
        --shell=none \
        --warmup ${WARMUP_RUNS} \
        --min-runs ${MIN_RUNS} \
        --max-runs ${MAX_RUNS} \
        --export-markdown "${RESULTS_DIR}/scaling_xlarge_${timestamp}.md" \
        --command-name "Rust (xlarge)" "${RUST_BINARY} ${INPUT_SAMPLES_DIR}/xlarge.csv" \
        --command-name "Go (xlarge)" "${GO_BINARY} ${INPUT_SAMPLES_DIR}/xlarge.csv" \
        --command-name "TypeScript (xlarge)" "${TS_NODE_DEFAULT} ${INPUT_SAMPLES_DIR}/xlarge.csv" \
        --command-name "Python (xlarge)" "${PYTHON_BINARY} ${INPUT_SAMPLES_DIR}/xlarge.csv"
    
    log_success "Data size scaling benchmarks completed"
}

benchmark_xlarge_dataset() {
    local timestamp=$(date +"%Y%m%d_%H%M%S")
    
    log_info "Running xlarge dataset benchmarks (real-world large file scenario)..."
    
    # Build command array dynamically for xlarge dataset
    local commands=()
    commands+=(--command-name "🦀 Rust (xlarge)" "${RUST_BINARY} ${INPUT_SAMPLES_DIR}/xlarge.csv")
    commands+=(--command-name "🐹 Go (xlarge)" "${GO_BINARY} ${INPUT_SAMPLES_DIR}/xlarge.csv")
    commands+=(--command-name "🟢 Node+csv-stream (xlarge)" "${TS_NODE_DEFAULT} ${INPUT_SAMPLES_DIR}/xlarge.csv")
    commands+=(--command-name "🟢 Node+PapaParse (xlarge)" "${TS_NODE_PAPAPARSE} ${INPUT_SAMPLES_DIR}/xlarge.csv")
    commands+=(--command-name "🐍 Python (xlarge)" "${PYTHON_BINARY} ${INPUT_SAMPLES_DIR}/xlarge.csv")
    
    # Add Bun variants if available
    if [[ "${BUN_AVAILABLE}" == "true" ]]; then
        commands+=(--command-name "🔥 Bun+csv-stream (xlarge)" "${TS_BUN_DEFAULT} ${INPUT_SAMPLES_DIR}/xlarge.csv")
        commands+=(--command-name "🔥 Bun+PapaParse (xlarge)" "${TS_BUN_PAPAPARSE} ${INPUT_SAMPLES_DIR}/xlarge.csv")
    fi
    
    # Use fewer runs for xlarge dataset to save time
    hyperfine \
        --shell=none \
        --warmup 2 \
        --min-runs 5 \
        --max-runs 10 \
        --export-markdown "${RESULTS_DIR}/xlarge_dataset_${timestamp}.md" \
        --export-json "${RESULTS_DIR}/xlarge_dataset_${timestamp}.json" \
        "${commands[@]}"
    
    log_success "XLarge dataset benchmarks completed"
}

benchmark_js_library_scaling() {
    local timestamp=$(date +"%Y%m%d_%H%M%S")
    
    log_info "Running JavaScript library scaling comparison..."
    
    # Test JS libraries across all dataset sizes
    for dataset in "small" "medium" "large"; do
        log_info "JS library comparison with ${dataset} dataset..."
        
        local commands=()
        commands+=(--command-name "Node+csv-stream (${dataset})" "${TS_NODE_DEFAULT} ${INPUT_SAMPLES_DIR}/${dataset}.csv")
        commands+=(--command-name "Node+PapaParse (${dataset})" "${TS_NODE_PAPAPARSE} ${INPUT_SAMPLES_DIR}/${dataset}.csv")
        
        if [[ "${BUN_AVAILABLE}" == "true" ]]; then
            commands+=(--command-name "Bun+csv-stream (${dataset})" "${TS_BUN_DEFAULT} ${INPUT_SAMPLES_DIR}/${dataset}.csv")
            commands+=(--command-name "Bun+PapaParse (${dataset})" "${TS_BUN_PAPAPARSE} ${INPUT_SAMPLES_DIR}/${dataset}.csv")
        fi
        
        hyperfine \
            --shell=none \
            --warmup ${WARMUP_RUNS} \
            --min-runs ${MIN_RUNS} \
            --max-runs ${MAX_RUNS} \
            --export-markdown "${RESULTS_DIR}/js_library_${dataset}_${timestamp}.md" \
            "${commands[@]}"
    done
    
    log_success "JavaScript library scaling comparison completed"
}

benchmark_startup_overhead() {
    local timestamp=$(date +"%Y%m%d_%H%M%S")
    
    log_info "Running startup overhead benchmarks (one line with 1x1 matrix)..."
    
    # Create a minimal CSV file for startup testing (just header + 1 tiny row)
    local startup_csv="${INPUT_SAMPLES_DIR}/startup.csv"
    if [[ ! -f "${startup_csv}" ]]; then
        {
            echo "id,json"
            echo '1,"[1]"'  # Single 1x1 matrix
        } > "${startup_csv}"
    fi
    
    # Build command array dynamically based on available runtimes
    local commands=()
    commands+=(--command-name "Rust startup" "${RUST_BINARY} ${startup_csv}")
    commands+=(--command-name "Go startup" "${GO_BINARY} ${startup_csv}")
    commands+=(--command-name "Node.js startup" "${TS_NODE_DEFAULT} ${startup_csv}")
    commands+=(--command-name "Python startup" "${PYTHON_BINARY} ${startup_csv}")
    
    # Add Bun if available
    if [[ "${BUN_AVAILABLE}" == "true" ]]; then
        commands+=(--command-name "Bun startup" "${TS_BUN_DEFAULT} ${startup_csv}")
    fi
    
    # Focus on startup time by using minimal data and more runs
    hyperfine \
        --shell=none \
        --warmup 5 \
        --min-runs 20 \
        --max-runs 30 \
        --export-markdown "${RESULTS_DIR}/startup_overhead_${timestamp}.md" \
        "${commands[@]}"
    
    log_success "Startup overhead benchmarks completed"
}

benchmark_with_preparation() {
    local timestamp=$(date +"%Y%m%d_%H%M%S")
    
    log_info "Running benchmarks with cache clearing (cold cache simulation)..."
    
    # Skip cold cache benchmarks in CI environments to avoid permission issues
    if [[ "${CI:-false}" == "true" ]] || [[ "${GITHUB_ACTIONS:-false}" == "true" ]]; then
        log_warning "CI environment detected. Skipping cold cache benchmarks (requires system-level permissions)."
        return 0
    fi
    
    # Benchmark with cache clearing to simulate cold cache performance
    # Note: This requires appropriate permissions on some systems
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        # Linux cache clearing (requires sudo)
        log_warning "Linux detected. Cache clearing requires sudo permissions."
        log_info "Running cold cache benchmark (Linux)..."
        
        if sudo -n true 2>/dev/null; then
            # Use || true to make this non-fatal - cold cache is nice-to-have, not essential
            hyperfine \
                --shell=none \
                --warmup 2 \
                --min-runs 8 \
                --max-runs 15 \
                --prepare 'sync && sudo sh -c "echo 3 > /proc/sys/vm/drop_caches"' \
                --export-markdown "${RESULTS_DIR}/cold_cache_${timestamp}.md" \
                --command-name "Rust (cold cache)" "${RUST_BINARY} ${INPUT_SAMPLES_DIR}/large.csv" \
                --command-name "Go (cold cache)" "${GO_BINARY} ${INPUT_SAMPLES_DIR}/large.csv" \
                --command-name "TypeScript (cold cache)" "${TS_NODE_DEFAULT} ${INPUT_SAMPLES_DIR}/large.csv" \
                || log_warning "Cold cache benchmark failed (permission issues), but continuing..."
            
            if [[ -f "${RESULTS_DIR}/cold_cache_${timestamp}.md" ]]; then
                log_success "Cold cache benchmarks completed"
            else
                log_warning "Cold cache benchmarks skipped due to system restrictions"
            fi
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
    local timestamp=$(date +"%Y%m%d_%H%M%S")
    
    log_info "Running comprehensive CLI comparison (using xlarge dataset for meaningful performance differences)..."
    
    # Build command array dynamically - using xlarge dataset for comprehensive comparison
    local commands=()
    commands+=(--command-name "🦀 Rust Implementation" "${RUST_BINARY} ${INPUT_SAMPLES_DIR}/xlarge.csv")
    commands+=(--command-name "🐹 Go Implementation" "${GO_BINARY} ${INPUT_SAMPLES_DIR}/xlarge.csv")
    commands+=(--command-name "🟢 Node+csv-stream" "${TS_NODE_DEFAULT} ${INPUT_SAMPLES_DIR}/xlarge.csv")
    commands+=(--command-name "🟢 Node+PapaParse" "${TS_NODE_PAPAPARSE} ${INPUT_SAMPLES_DIR}/xlarge.csv")
    commands+=(--command-name "🐍 Python Implementation" "${PYTHON_BINARY} ${INPUT_SAMPLES_DIR}/xlarge.csv")
    
    # Add Bun variants if available
    if [[ "${BUN_AVAILABLE}" == "true" ]]; then
        commands+=(--command-name "🔥 Bun+csv-stream" "${TS_BUN_DEFAULT} ${INPUT_SAMPLES_DIR}/xlarge.csv")
        commands+=(--command-name "🔥 Bun+PapaParse" "${TS_BUN_PAPAPARSE} ${INPUT_SAMPLES_DIR}/xlarge.csv")
    fi
    
    # Comprehensive comparison with detailed output
    hyperfine \
        --shell=none \
        --warmup ${WARMUP_RUNS} \
        --min-runs 15 \
        --max-runs 25 \
        --export-markdown "${RESULTS_DIR}/comprehensive_comparison_${timestamp}.md" \
        --export-json "${RESULTS_DIR}/comprehensive_comparison_${timestamp}.json" \
        --style full \
        "${commands[@]}"
    
    log_success "Comprehensive comparison completed"
}

cleanup() {
    log_info "Cleaning up temporary files..."
    
    # Clean up benchmark results to prevent accumulation
    # Keep datasets persistent, but clean results unless explicitly requested to keep them
    if [[ "${KEEP_RESULTS:-false}" != "true" ]]; then
        if [[ -d "${RESULTS_DIR}" ]]; then
            log_info "Cleaning up benchmark results from ${RESULTS_DIR}"
            # Remove all result files but keep the directory structure
            find "${RESULTS_DIR}" -name "*.md" -delete 2>/dev/null || true
            find "${RESULTS_DIR}" -name "*.json" -delete 2>/dev/null || true
            find "${RESULTS_DIR}" -name "*.csv" -delete 2>/dev/null || true
            log_info "Benchmark results cleaned up (use KEEP_RESULTS=true to preserve)"
        fi
    else
        log_info "Keeping benchmark results (KEEP_RESULTS=true)"
    fi
    
    # Always preserve persistent datasets in input-samples/
    log_info "Persistent datasets preserved in ${INPUT_SAMPLES_DIR}"
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

# Trap to ensure cleanup on exit (unless disabled)
if [[ "${DISABLE_CLEANUP:-false}" != "true" ]]; then
    trap cleanup EXIT
fi

main() {
    echo "🚀 CSV Table Rotation CLI - Cross-Language Performance Benchmarks"
    echo "=================================================================="
    echo
    echo "💡 File Management Strategy:"
    echo "   • Persistent datasets: ${INPUT_SAMPLES_DIR}/*.csv (kept between runs)"
    echo "   • Temporary results: ${RESULTS_DIR}/*.{md,json,csv} (cleaned unless KEEP_RESULTS=true)"
    echo "   • Cleanup: $([ "${DISABLE_CLEANUP:-false}" = "true" ] && echo "DISABLED" || echo "ENABLED") (use DISABLE_CLEANUP=true to disable)"
    echo
    
    check_dependencies
    generate_test_datasets
    
    log_success "Test datasets are ready in ${INPUT_SAMPLES_DIR}"
    
    # Run benchmarks
    benchmark_js_runtime_comparison
    benchmark_data_size_scaling
    benchmark_js_library_scaling
    benchmark_startup_overhead
    benchmark_with_preparation
    run_comprehensive_comparison  # This uses xlarge dataset
    
    # Print summary
    print_summary
    
    log_success "All benchmarks completed successfully! 🎉"
}

# Check if script is being sourced or executed
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi 
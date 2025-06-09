# Table Rotation CLI - Polyglot Implementation

[![CI](https://github.com/LucasMatuszewski/csv-table-rotation-benchmark/actions/workflows/ci.yml/badge.svg)](https://github.com/LucasMatuszewski/csv-table-rotation-benchmark/actions/workflows/ci.yml)
[![Benchmarks](https://github.com/LucasMatuszewski/csv-table-rotation-benchmark/actions/workflows/bench.yml/badge.svg)](https://github.com/LucasMatuszewski/csv-table-rotation-benchmark/actions/workflows/bench.yml)

## 🚀 TL;DR - Performance Results

A high-performance CSV table rotation CLI tools implemented in **Rust, Go, TypeScript, and Python** using identical algorithms. [See full benchmarks](#performance-benchmarks). Built with AI assistance (see [Zed vs Cursor comparison](#-ai-tools-comparison)) to demonstrate cross-language performance characteristics.

**🏆 Benchmark Results (Comprehensive Dataset):**

| Language          | Small Dataset | Medium Dataset | Large Dataset | Startup Time | Performance Rank           |
| ----------------- | ------------- | -------------- | ------------- | ------------ | -------------------------- |
| 🦀 **Rust**       | 1.4ms         | 1.4ms          | 3.0ms         | 1.4ms        | 🥇 **1st** - Fastest       |
| 🐹 **Go**         | 1.8ms         | 2.0ms          | 12.8ms        | 1.7ms        | 🥈 **2nd** - Excellent     |
| 🐍 **Python**     | 17.0ms        | 17.7ms         | 35.8ms        | 16.6ms       | 🥉 **3rd** - Solid         |
| 📜 **TypeScript** | 32.0ms        | 34.0ms         | 42.7ms        | 29.0ms       | **4th** - Node.js overhead |

**Key Insights:**

- **Rust wins overall** - Zero-cost abstractions and compiled efficiency
- **Go excellent startup** - Only 28% slower than Rust for small tasks
- **Python consistency** - Steady ~12× gap, efficient interpreter
- **TypeScript struggles** - V8 startup overhead dominates small workloads
- **Algorithm-level performance** - Go is 2.3-2.6× slower than Rust in [micro-benchmarks](#1-micro-benchmarks-algorithm-level-performance) (pure rotation algorithm)

---

## Table of Contents

- [Table Rotation CLI - Polyglot Implementation](#table-rotation-cli---polyglot-implementation)
  - [🚀 TL;DR - Performance Results](#-tldr---performance-results)
  - [Table of Contents](#table-of-contents)
  - [Problem Statement](#problem-statement)
  - [How it works](#how-it-works)
    - [Implementation Strategy](#implementation-strategy)
    - [Table Validation](#table-validation)
    - [Table Interpretation](#table-interpretation)
    - [Clockwise Rotation (One-Step Shift)](#clockwise-rotation-one-step-shift)
    - [Input \& Output CSV data Example](#input--output-csv-data-example)
  - [Algorithm Explanation](#algorithm-explanation)
    - [Concentric Rings Concept](#concentric-rings-concept)
    - [Rotation Process](#rotation-process)
    - [Complexity Analysis](#complexity-analysis)
    - [Edge Cases Handled](#edge-cases-handled)
  - [Quick Start](#quick-start)
  - [Repository Structure](#repository-structure)
  - [Language Implementations](#language-implementations)
    - [Rust](#rust)
    - [Go](#go)
    - [TypeScript](#typescript)
    - [Python](#python)
  - [Performance Benchmarks](#performance-benchmarks)
    - [1. Micro-benchmarks (Algorithm-level performance)](#1-micro-benchmarks-algorithm-level-performance)
    - [2. End-to-end CLI benchmarks (Hyperfine - Cross-language)](#2-end-to-end-cli-benchmarks-hyperfine---cross-language)
  - [🤖 AI Tools Comparison](#-ai-tools-comparison)
    - [Tools Used](#tools-used)
      - [1. **macOS ChatGPT App with o3** + Search + "Work with Apps" (Cursor access)](#1-macos-chatgpt-app-with-o3--search--work-with-apps-cursor-access)
      - [2. **Zed Editor** (Rust-based, fast but unstable)](#2-zed-editor-rust-based-fast-but-unstable)
      - [3. **Cursor** (Primary development environment)](#3-cursor-primary-development-environment)
    - [Cost Analysis](#cost-analysis)
    - [Key Takeaways](#key-takeaways)
  - [Development Setup](#development-setup)
    - [**VSCode/Cursor Setup**](#vscodecursor-setup)
    - [**Manual Formatting Commands**](#manual-formatting-commands)
  - [Testing](#testing)
  - [CI/CD](#cicd)

## Problem Statement

This tool processes CSV files containing square numerical tables and rotates them by shifting each element one position clockwise around its ring. Given an input CSV with columns `id` and `json` (where json contains a stringified array of numbers), the tool:

1. Parses each JSON array
2. Determines if it can form a square table (N×N where N² equals array length)
3. If valid, rotates the table by one step clockwise and outputs the flattened result
4. If invalid, marks it as such and outputs an empty array
5. Writes results to stdout as CSV with columns: `id`, `json`, `is_valid`

## How it works

### Implementation Strategy

- **Memory efficient**: In-place rotation using ring-by-ring element shifting
- **Streaming**: Process CSV row-by-row to handle large files

### Table Validation

For a JSON array to be valid for rotation:

- Must contain only numbers (integers/floats)
- Array length must be a perfect square (1, 4, 9, 16, 25, ...)
- This ensures it can form an N×N square table where N = √(array length)

### Table Interpretation

Numbers are arranged in the square table **row by row** (left-to-right, top-to-bottom):

For `[40, 20, 90, 10]` (length 4 → 2×2 table):

```
Position: [0, 1, 2, 3]
Table:    40  20
          90  10
```

For `[1, 2, 3, 4, 5, 6, 7, 8, 9]` (length 9 → 3×3 table):

```
Position: [0, 1, 2, 3, 4, 5, 6, 7, 8]
Table:    1  2  3
          4  5  6
          7  8  9
```

### Clockwise Rotation (One-Step Shift)

Each element moves one position clockwise around its concentric ring. The algorithm processes each ring independently from outside to inside.

**2×2 Example:**

```
Original:     After one-step clockwise:
40  20   →    90  40
90  10        10  20
```

Ring elements: `40 → 20 → 10 → 90` becomes `90 → 40 → 20 → 10`
Reading row-by-row: `[90, 40, 10, 20]`

**3×3 Example:**

```
Original:     After one-step clockwise:
1  2  3  →    4  1  2
4  5  6       7  5  3
7  8  9       8  9  6
```

Outer ring: `1 → 2 → 3 → 6 → 9 → 8 → 7 → 4` becomes `4 → 1 → 2 → 3 → 6 → 9 → 8 → 7`
Center element `5` stays in place.
Reading row-by-row: `[4, 1, 2, 7, 5, 3, 8, 9, 6]`

Note: In odd-sized tables (3×3, 5×5, etc.), the center element stays in place.

### Input & Output CSV data Example

**Input:**

```csv
id,json
1,"[1, 2, 3, 4, 5, 6, 7, 8, 9]"
2,"[40, 20, 90, 10]"
3,"[-5]"
4,"[2, -5, -5]"
```

**Output:**

```csv
id,json,is_valid
1,"[4, 1, 2, 7, 5, 3, 8, 9, 6]",true
2,"[90, 40, 10, 20]",true
3,"[-5]",true
4,"[]",false
```

## Algorithm Explanation

### Concentric Rings Concept

Think of the square matrix as nested "onion skins" or concentric rings:

```
5×5 grid:           Rings labeled:
1  2  3  4  5       A  A  A  A  A
6  7  8  9 10       A  B  B  B  A
11 12 13 14 15  →   A  B  C  B  A
16 17 18 19 20      A  B  B  B  A
21 22 23 24 25      A  A  A  A  A
```

- **Ring A** = outer perimeter (20 elements)
- **Ring B** = inner frame (12 elements)
- **Ring C** = center cell (1 element, never moves in odd-sized grids)

### Rotation Process

For each ring independently, every element moves **one position clockwise**:

1. **Layer-by-layer processing**: Start from outermost ring, work inward
2. **Clockwise walk**: Top row → Right column → Bottom row → Left column
3. **In-place swaps**: Use only two temporary variables for O(1) space

### Complexity Analysis

- **Time**: O(N²) - where N is the side length
- **Space**: O(1) - uses only two temporary variables (prev, temp)
- **Optimal**: No faster algorithm exists since every element must move

### Edge Cases Handled

- Empty arrays → invalid
- Non-square arrays (length not perfect square) → invalid
- Single element (1×1 grid) → unchanged
- Negative numbers → handled normally
- Large datasets → streaming CSV processing
- Malformed JSON → marked invalid

## Quick Start

```bash
# Clone and navigate
git clone git@github.com:LucasMatuszewski/csv-table-rotation-benchmark.git
cd csv-table-rotation-benchmark

# Run any implementation
./rust/target/release/rotate_cli input-samples/sample-1k.csv > output.csv
./go/bin/rotate input-samples/sample-1k.csv > output.csv
node typescript/dist/index.js input-samples/sample-1k.csv > output.csv
python -m rotate_cli input-samples/sample-1k.csv > output.csv
```

## Repository Structure

```
csv-table-rotation-benchmark/
├── input-samples/
│   └── sample-1k.csv          # Shared test fixtures
├── benchmarks/
│   └── run_hyperfine.sh       # Cross-language performance testing
├── rust/                      # Rust implementation
│   ├── Cargo.toml
│   ├── src/
│   ├── tests/
│   └── benches/
├── go/                        # Go implementation
│   ├── go.mod
│   ├── internal/rotate/
│   ├── cmd/rotate/
│   └── bin/
├── typescript/                # TypeScript/Node.js implementation
│   ├── package.json
│   ├── src/
│   └── tests/
├── python/                    # Python implementation
│   ├── pyproject.toml
│   ├── src/
│   └── tests/
└── .github/workflows/         # CI/CD pipelines
```

## Language Implementations

### Rust

**Build & Run:**

```bash
cd rust
cargo build --release
./target/release/rotate_cli ../input-samples/sample-1k.csv > output-rust.csv
```

**Test:**

```bash
cargo test
cargo bench  # Performance benchmarks
```

**Features:**

- Streaming CSV processing with zero-copy where possible
- Memory-efficient in-place rotation algorithm
- Comprehensive error handling with custom error types
- Property-based testing with `proptest`

### Go

**Build & Run:**

```bash
cd go
go build -o ./bin/rotate ./cmd/rotate
./bin/rotate ../input-samples/sample-1k.csv > output-go.csv
```

**Test:**

```bash
go test ./... -v                                        # All tests
go test -bench=. -run=^$ ./internal/rotate              # Benchmarks only
go test -bench=BenchmarkRotationSizes ./internal/rotate # Specific benchmark
```

**Features:**

- Streaming CSV processing using standard library
- Memory-efficient in-place rotation with generics
- Comprehensive error handling with custom error types
- Zero third-party dependencies (stdlib only)
- CLI integration tests with temporary file handling
- Built-in benchmarking with testing.B

### TypeScript

**Build & Run:**

```bash
cd typescript
pnpm install
pnpm build
node dist/cli.js ../input-samples/sample-1k.csv > output-typescript.csv
```

**Test:**

```bash
pnpm test
pnpm lint
```

**Features:**

- Modern TypeScript with strict type checking
- Streaming CSV processing
- Jest testing with CLI integration tests
- ESLint + Prettier for code quality

### Python

**Build & Run:**

```bash
cd python
# Create virtual environment (recommended)
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate

# Install package with dependencies
pip install -e ".[dev]"

# Run the CLI
python -m rotate_cli ../input-samples/sample-1k.csv > output-python.csv
```

**Test:**

```bash
# Activate virtual environment first
source venv/bin/activate  # On Windows: venv\Scripts\activate

pytest tests/ -v
mypy rotate_cli/  # Type checking
```

**Features:**

- Type hints throughout with strict mypy configuration
- Built-in CSV module for streaming
- pytest with benchmark plugin
- PEP 621 compliant project structure (no requirements.txt needed)
- Virtual environment support for dependency isolation

## Performance Benchmarks

We provide two complementary types of benchmarks:

### 1. Micro-benchmarks (Algorithm-level performance)

Detailed algorithm-level performance analysis for compiled languages:

**Rust:**

Criterion is used for Rust benchmarks.

```bash
cd rust
cargo bench --bench rotation_bench
```

**Go:**

Go uses testing.B for benchmarks.

```bash
cd go
go test -bench=. -run=^$ ./internal/rotate  # Benchmarks only (excludes unit tests)
# Note: -run=^$ means "run no tests" (empty regex), -bench=. means "run all benchmarks"
```

**What it measures:**

- Pure rotation algorithm performance across different matrix sizes (1×1 to 128×128)
- Memory allocation patterns and scaling characteristics
- JSON parsing + rotation pipeline performance
- Edge case handling performance
- Multiple rotation cycles for consistency testing

**Key Results Comparison (Rust vs Go):**

| Matrix Size | Rust (Criterion) | Go (testing.B) | Go vs Rust  |
| ----------- | ---------------- | -------------- | ----------- |
| 1×1         | ~2.5 ns/op       | ~6.3 ns/op     | 2.5× slower |
| 4×4         | ~8.2 ns/op       | ~20.7 ns/op    | 2.5× slower |
| 10×10       | ~40 ns/op        | ~95.4 ns/op    | 2.4× slower |
| 25×25       | ~200 ns/op       | ~517.5 ns/op   | 2.6× slower |
| 100×100     | ~3.2 μs/op       | ~7.3 μs/op     | 2.3× slower |

**Key insights:**

- **Consistent performance gap**: Go is ~2.3-2.6× slower than Rust across all matrix sizes
- **Perfect O(N²) scaling**: Both languages scale identically with matrix size
- **Memory efficiency**: Go uses single allocation per operation (consistent 1 alloc/op)
- **Validation speed**: Square length validation extremely fast in both (~0.23ns Go, ~0.75ps Rust)
- **Algorithm efficiency**: In-place rotation processes 100×100 matrices at ~1.4 billion elements/second (Go) vs ~3.1 billion (Rust)
- **Memory allocation**: Go's GC overhead visible but minimal impact on algorithmic performance

### 2. End-to-end CLI benchmarks (Hyperfine - Cross-language)

Full program comparison across implementations using [hyperfine](https://github.com/sharkdp/hyperfine):

```bash
# Full benchmark suite (comprehensive analysis)
./benchmarks/run_hyperfine.sh

# Quick test (basic comparison)
./benchmarks/quick_test.sh
```

**Note**: Python benchmarks require a virtual environment setup in `python/venv/`. The benchmark scripts will automatically create and install dependencies if needed, or you can set it up manually:

```bash
cd python
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
pip install -e ".[dev]"
```

**Benchmark Features:**

- **Basic performance** - Direct comparison on standard workloads
- **Data size scaling** - Performance across different input sizes with three dataset tiers:
  - **Small**: 1×1 to 3×3 matrices (startup overhead focus)
  - **Medium**: 1×1 to 10×10 matrices (up to 100 elements)
  - **Large**: 15×15 to 50×50 matrices (up to 2500 elements)
- **Startup overhead** - Language/runtime initialization costs
- **Cache behavior** - Cold vs warm cache performance (Linux only)
- **Comprehensive analysis** - Detailed statistical breakdown
- **Multiple export formats** - JSON, CSV, Markdown for further analysis
- **Automatic dependency checking** - Builds missing binaries automatically
- **Cross-platform support** - macOS, Linux
- **Statistical outlier detection** - Warns about inconsistent measurements

**Sample Results (Data Size Scaling):**

```
| Dataset | Rust  | Go     | Python | TypeScript | Rust vs Go  | Rust vs Py   | Rust vs TS   |
|---------|-------|--------|--------|------------|-------------|--------------|--------------|
| Small   | 1.4ms | 1.8ms  | 17.0ms | 32.0ms     | 1.3× faster | 12.3× faster | 23.3× faster |
| Medium  | 1.4ms | 2.0ms  | 17.7ms | 34.0ms     | 1.4× faster | 12.3× faster | 23.6× faster |
| Large   | 3.0ms | 12.8ms | 35.8ms | 42.7ms     | 4.2× faster | 11.9× faster | 14.3× faster |
```

**Startup Overhead Analysis:**

```
| Language   | Startup Time | vs Rust |
|------------|--------------|---------|
| Rust       | 1.4ms        | 1.00×   |
| Go         | 1.7ms        | 1.28×   |
| Python     | 16.6ms       | 11.9×   |
| TypeScript | 29.0ms       | 20.7×   |
```

**Performance Ranking:**

1. **Rust** (1.4-3.0ms) - Fastest with excellent scaling; compiled efficiency and zero-cost abstractions
2. **Go** (1.7-12.8ms) - ~1.3-4.2× slower; excellent startup time, some variance with large datasets
3. **Python** (16.6-35.8ms) - ~12× slower; consistent performance, efficient built-in modules
4. **TypeScript** (29.0-42.7ms) - ~14-24× slower; V8 JIT performance limited by startup overhead

**Key Performance Insights:**

- **Perfect algorithmic scaling**: Rust demonstrates O(N²) scaling (1.4ms → 3.0ms for ~25× larger matrices)
- **Go performance characteristics**: Excellent startup time (~1.7ms), but shows more variance with large datasets (12.8ms) compared to Rust
- **Startup overhead dominance**: Both Python (~16.6ms) and TypeScript (~29ms) have significant startup costs compared to compiled languages
- **Python consistency**: Maintains steady ~12× performance gap across all dataset sizes, with startup being the primary bottleneck
- **TypeScript scaling**: Shows diminishing startup penalty as datasets grow (21× slower → 13× slower), but startup overhead remains substantial
- **Runtime characteristics**: For small workloads, startup overhead dominates; compiled languages (Rust, Go) have clear advantages. Python's interpreter is more efficient than Node.js V8 initialization
- **Cross-language consistency**: All implementations use identical algorithm ensuring performance comparison reflects language/runtime differences, not algorithmic ones

## 🤖 AI Tools Comparison

This repository was built using various AI-powered development tools to demonstrate their capabilities in cross-language development. Fully codded in my **Viture Pro XR Glasses** during 2 days I get flu and stayed in bed ;)

### Tools Used

#### 1. **macOS ChatGPT App with o3** + Search + "Work with Apps" (Cursor access)

- **Usage**: Research, ideation, best practices, and planning
- **Strengths**: Excellent for high-level architecture and research
- **Role**: Project planning and initial algorithm design

#### 2. **Zed Editor** (Rust-based, fast but unstable)

- **Usage**: Full Rust implementation + part of TypeScript
- **Strengths**:
  - Very fast performance (but I never complained on Cursor/VSCode speed)
  - "Follow Agent" mode
  - Context size counter
  - Privacy and local model support
  - It's OPEN SOURCE, so you can see the code and contribute!
- **Issues Encountered**:
  - 1 crash without explanation (just restart)
  - Auth error lockout (couldn't log back in, "Sign in" button unresponsive)
  - Line-based diff (vs Cursor's character-level diff)
  - Not possible to select and add to chat context (like Cursor's "Add to chat" button)
  - ChatGPT macOS App doesn't support "Work with Apps" for Zed (it does for Cursor)
- **Efficiency**: Used all 150 free trial prompts for just Rust + partial TS implementation
- **Result**: Promising but not production-ready IMHO

#### 3. **Cursor** (Primary development environment)

- **Usage**: Remaining TypeScript, Python, Go, Hyperfine benchmarks, CI/CD
- **Strengths**:
  - Reliable and stable
  - Character-level diff highlighting
  - Full VSCode ecosystem, extensions, etc.
  - More efficient "request" usage (much cheaper than Zed prompts in my tests)
- **Efficiency**: 50 requests accomplished significantly more work than Zed's 150 prompts
- **Result**: Most productive for actual implementation

### Cost Analysis

Both tools offer **$20/month for ~500 requests/prompts**, but:

- **Cursor**: 500 requests = substantial work (this project used ~50 for most implementations)
- **Zed**: 500 prompts = less work (150 prompts only completed Rust + partial TS)
- **Claude Sonnet 4**: Currently uses 0.75 request weight in Cursor

### Key Takeaways

1. **Cursor wins for productivity** - More stable, mature, better diff visualization, efficient request usage
2. **Zed shows promise** - Speed and privacy features are compelling, but needs stability improvements. I love Open Source so will watch it's development and it stays installed on my machine.
3. **AI tool pricing varies significantly** in actual value delivered per dollar
4. **Claude Sonnet 4** replaced Gemini 2.5 Pro as my preferred model for code generation (produces much smaller diff, is more precise in changes, follows instructions better, etc.)

## Development Setup

This project includes automatic formatting configuration for all languages:

### **VSCode/Cursor Setup**

- **Automatic formatting** on save and paste for all languages
- **Recommended extensions** - Install prompted extensions for full language support
- **EditorConfig** - Consistent indentation and line endings across editors

### **Manual Formatting Commands**

```bash
# Go formatting
cd go && gofmt -s -w .

# Rust formatting
cd rust && cargo fmt

# TypeScript formatting
cd typescript && npm run lint:fix

# Python formatting
cd python && black . && isort .
```

## Testing

Each implementation includes:

- **Unit tests** - Pure function testing with edge cases
- **Integration tests** - Full CLI testing with sample data
- **Property tests** - Generative testing (where applicable)
- **Performance regressions** - Benchmarks that fail if significantly slower

## CI/CD

GitHub Actions workflows:

- **`ci.yml`** - Build, test, and lint all four implementations in parallel
- **`bench.yml`** - Performance benchmarking with artifact upload

All implementations must pass:

- Zero compiler/linter warnings
- 100% test success rate
- Performance within acceptable bounds

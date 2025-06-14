# Table Rotation CLI - Polyglot Implementation

[![CI](https://github.com/LucasMatuszewski/csv-table-rotation-benchmark/actions/workflows/ci.yml/badge.svg)](https://github.com/LucasMatuszewski/csv-table-rotation-benchmark/actions/workflows/ci.yml)
[![Benchmarks](https://github.com/LucasMatuszewski/csv-table-rotation-benchmark/actions/workflows/bench.yml/badge.svg)](https://github.com/LucasMatuszewski/csv-table-rotation-benchmark/actions/workflows/bench.yml)

## 🚀 TL;DR - Performance Results & Motivation

A high-performance CSV Table Rotation CLI tool implemented in **Rust, Go, TypeScript, and Python** using an identical [algorithm](#algorithm-explanation). Built with **hyperfine** for cross-language performance benchmarking to demonstrate each language's real-world strengths and trade-offs (see [full benchmarks](#performance-benchmarks)).

**Why this project?**

Imagine coding in multiple languages at full productivity - with the flu - comfortably nestled in your bed, powered by **XR Glasses**, and assisted by the latest **Claude 4 Sonnet** inside cutting-edge AI tools (see [Zed vs Cursor comparison](#-ai-tools-comparison)). This unique scenario inspired the creation of this repository. What a time to be alive!

**🏆 Benchmark Results:**

- XLarge Dataset - 13MB, 1000 rows, up to 70x70 matrices
- Medium Dataset - 8KB, 50 rows, up to 10x10 matrices
- Startup Time - 1 row with 1x1 matrix

| Implementation           | XLarge (vs Rust) | Medium (vs Rust) | Startup | Scaling Behavior                |
| ------------------------ | ---------------- | ---------------- | ------- | ------------------------------- |
| 🦀 **Rust**              | 39.1ms (1.00×)   | 1.4ms (1.00×)    | 1.3ms   | 🥇 **Excellent scaling**        |
| 🔥 **Bun + PapaParse**   | 87.1ms (2.23×)   | 28.7ms (20.5×)   | 25.9ms  | 🥈 **Good for large files**     |
| 🟢 **Node + PapaParse**  | 94.0ms (2.41×)   | 35.7ms (25.5×)   | 33.1ms  | 🥉 **Slowest for small files**  |
| 🔥 **Bun + csv-stream**  | 168.0ms (4.30×)  | 27.3ms (19.5×)   | 25.9ms  | **Better for small files**      |
| 🐹 **Go**                | 207.2ms (5.30×)  | 1.9ms (1.36×)    | 1.6ms   | **Great startup, poor scaling** |
| 🟢 **Node + csv-stream** | 209.7ms (5.37×)  | 34.8ms (24.9×)   | 33.1ms  | **Better for small files**      |
| 🐍 **Python**            | 503.7ms (12.89×) | 20.3ms (14.5×)   | 16.8ms  | **Consistent but slow**         |

**Key Performance Insights:**

- **🦀 Rust dominates across all scales** - Zero-cost abstractions and compiled efficiency shine consistently from small (1.4ms) to xlarge (39.1ms)
- **🔥 Bun + PapaParse emerges as best JS solution** - 2.4× faster than Node.js + csv-stream for large files, with consistent performance
- **📚 CSV library choice matters significantly** - PapaParse 2× faster than csv-stream for large files, but csv-stream wins for small files
- **🐹 Go's scaling paradox** - Stunning small-file performance (1.36× vs Rust), but poor scaling (5.30× vs Rust for xlarge)
- **🟢 Node.js startup penalty, scaling strength** - Heavy startup overhead (25× slower than Rust for medium), but excellent large-file processing (only 2.4× slower than Rust for xlarge)
- **🐍 Python's linear consistency** - Remarkably stable 14-15× performance ratio vs Rust across all scales, but consistently slow overall
- **⚡ Startup vs Processing trade-off revealed** - Compiled languages (Rust, Go) excel at startup, but only Rust maintains advantage at scale where CSV parsing dominates
- **📊 JavaScript runtime evolution** - Both Node.js and Bun scale dramatically better than their startup times suggest, becoming competitive for large datasets
- **🎯 Real-world implications** - For small/quick tasks: Go or Rust. For large CSV processing: Rust > Bun/Node.js + PapaParse > Go
- **Algorithm-level performance** - Go is 2.3-2.6× slower than Rust in [micro-benchmarks](#1-micro-benchmarks-algorithm-level-performance) (pure rotation algorithm)

**Language & Runtime Versions:**

- 🦀 Rust 1.87.0
- 🐹 Go 1.24.4 (darwin/arm64)
- 🟢 Node.js 22.14.0 & 🔥 Bun 1.2.16
- 🐍 Python 3.13.3
- 📊 Testing: Mac Mini M4 (macOS 15.5) + GitHub Actions runner (Ubuntu 24.04)

**Roadmap:**

- [x] ~~Add Bun vs Node.js benchmarks~~ ✅ **Completed** - Bun shows 24% faster startup, significant CSV parsing advantages
- [x] ~~Add PapaParse vs csv-stream comparison~~ ✅ **Completed** - PapaParse 2× faster for large datasets
- [ ] Add Deno runtime benchmarks
- [ ] Add Swift implementation and benchmarks
- [ ] Add multi-type support (string, number, boolean)
- [ ] Parallelize the rotation algorithm (multiple or all layers at once)

---

## Table of Contents

- [Table Rotation CLI - Polyglot Implementation](#table-rotation-cli---polyglot-implementation)
  - [🚀 TL;DR - Performance Results \& Motivation](#-tldr---performance-results--motivation)
  - [Table of Contents](#table-of-contents)
  - [Problem Statement](#problem-statement)
  - [How it works](#how-it-works)
    - [Implementation Strategy](#implementation-strategy)
    - [Table Validation](#table-validation)
    - [Table Interpretation](#table-interpretation)
    - [Clockwise Rotation (One-Step Shift)](#clockwise-rotation-one-step-shift)
    - [Input \& Output CSV data Example](#input--output-csv-data-example)
  - [Algorithm - Deep Dive](#algorithm---deep-dive)
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
  - [🏎️ Performance Benchmarks](#️-performance-benchmarks)
    - [1. Micro-benchmarks (Algorithm-level performance)](#1-micro-benchmarks-algorithm-level-performance)
    - [2. End-to-end CLI benchmarks (Hyperfine - Cross-language)](#2-end-to-end-cli-benchmarks-hyperfine---cross-language)
    - [3. JavaScript Runtime Comparison](#3-javascript-runtime-comparison)
    - [4. CSV Library Performance Analysis](#4-csv-library-performance-analysis)
  - [🤖 AI Tools Comparison](#-ai-tools-comparison)
    - [Tools Used](#tools-used)
      - [1. **ChatGPT App with o3** + Search + "Work with Apps" (Cursor access on macOS)](#1-chatgpt-app-with-o3--search--work-with-apps-cursor-access-on-macos)
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

## Algorithm - Deep Dive

### Concentric Rings Concept

Think of the square matrix as nested "onion skins" or concentric rings:

```
5×5 grid:           Rings labeled:
1  2  3  4  5       A  A  A  A  A
6  7  8  9  10      A  B  B  B  A
11 12 13 14 15  →   A  B  C  B  A
16 17 18 19 20      A  B  B  B  A
21 22 23 24 25      A  A  A  A  A
```

- **Ring A** = outer perimeter (16 elements)
- **Ring B** = inner frame (8 elements)
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

**Version:** `rustc 1.87.0` + `cargo 1.87.0`

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

**Version:** `go 1.24.4` (darwin/arm64)

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
- Built-in benchmarking with `testing.B`

### TypeScript

**Versions:** `Node.js 22.14.0` & `Bun 1.2.16`

**Build & Run:**

```bash
cd typescript
npm install
npm run build
node dist/cli.js ../input-samples/sample-1k.csv > output-typescript.csv
```

**Test:**

```bash
npm test
npm lint
```

**Features:**

- Modern TypeScript with strict type checking
- **Dual CSV library support** - Both csv-stream (default) and PapaParse via environment variable
- Streaming CSV processing for memory efficiency
- **Runtime flexibility** - Works with Node.js, and Bun
- Jest testing with CLI integration tests
- ESLint + Prettier for code quality

**CSV Library Switching:**

```bash
# Default: csv-stream
node dist/index.js input.csv

# PapaParse (much faster for large files, a little slower for small files)
CSV_LIBRARY=papaparse node dist/index.js input.csv

# Or use wrapper scripts (created for Hyperfine to avoid Shell and ENV variables)
./typescript/run-papaparse.sh input.csv      # Node.js + PapaParse
./typescript/run-bun-papaparse.sh input.csv # Bun + PapaParse
```

### Python

**Version:** `Python 3.13.3`

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

## 🏎️ Performance Benchmarks

**Testing Environment:**

- **Local:** Mac Mini M4 (ARM64) - macOS 15.5
- **CI/CD:** GitHub Actions - Ubuntu 24.04.1 basic runner (x86_64)
  - CPU: AMD EPYC 7763 64-Core Processor (4 cores allocated)
  - RAM: 15Gi total, 14Gi available

**Performance Environment Comparison (XLarge Dataset):**

| Implementation | Local (M4) | GitHub Actions | CI Slowdown |
| -------------- | ---------: | -------------: | ----------: |
| 🦀 Rust        |     39.1ms |        110.8ms |        2.8× |
| 🐹 Go          |    207.2ms |        488.1ms |        2.4× |
| 🐍 Python      |    503.7ms |       1322.0ms |        2.6× |
| 🟢 Node+Papa   |     94.0ms |        203.0ms |        2.2× |
| 🔥 Bun+Papa    |     87.1ms |        218.2ms |        2.5× |

_GitHub's standard runners (~2.5× slower) use AMD EPYC 7763 (4 cores) vs Apple Silicon M4's high-performance cores_

---

Below are the detailed benchmarks for Mac Mini M4.

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

Full program performance comparison across implementations using [hyperfine](https://github.com/sharkdp/hyperfine) (Rust based CLI testing tool):

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
| Dataset | Rust  | Go (vs Rust)   | Python (vs Rust) | Node (vs Rust) | Bun (vs Rust)  |
|---------|-------|----------------|------------------|----------------|----------------|
| Small   | 1.4ms | 1.8ms (1.3x)   | 17.6ms (12.6x)   | 37.0ms (26.4x) | 30.9ms (22.1x) |
| Medium  | 1.5ms | 1.9ms (1.3x)   | 18.0ms (12.0x)   | 37.9ms (25.3x) | 30.0ms (20.0x) |
| Large   | 2.9ms | 11.6ms (4.0x)  | 36.9ms (12.7x)   | 41.7ms (14.4x) | 33.4ms (11.5x) |
| XLarge  | 40.0ms| 211.9ms (5.3x) | 513.1ms (12.8x)  | 94.2ms (2.4x)  | 88.6ms (2.2x)  |
```

> Note: for Node.js and Bun we used PapaParse CSV library

**Startup Overhead Analysis (file with only ONE 1x1 matrix):**

```
| Implementation | Startup Time | vs Rust | Notes                    |
|----------------|--------------|---------|--------------------------|
| Rust           | 1.3ms        | 1.00×   | Compiled binary          |
| Go             | 1.7ms        | 1.31×   | Compiled binary          |
| Python         | 17.7ms       | 13.6×   | Interpreter + C modules  |
| Bun            | 26.6ms       | 20.5×   | Optimized JS runtime     |
| Node.js        | 35.0ms       | 26.9×   | V8 JIT compilation       |
```

**Performance Ranking (XLarge Dataset):**

1. **🦀 Rust** (40.0ms) - Fastest with excellent scaling; compiled efficiency and zero-cost abstractions
2. **🔥 Bun + PapaParse** (88.6ms) - Best JavaScript solution; 2.2× slower than Rust
3. **🟢 Node.js + PapaParse** (94.2ms) - Solid JS performance; 2.4× slower than Rust
4. **🔥 Bun + csv-stream** (172.4ms) - Shows CSV library impact; 4.3× slower than Rust
5. **🐹 Go** (211.9ms) - Excellent startup but poor scaling; 5.3× slower than Rust
6. **🟢 Node.js + csv-stream** (212.7ms) - Slower runtime + slower CSV lib; 5.3× slower than Rust
7. **🐍 Python** (513.1ms) - Consistent but slower; 12.8× slower than Rust

**Key Performance Insights:**

- **🦀 Rust's scaling excellence**: Perfect O(N²) scaling from 1.4ms (small) → 40ms (xlarge) for 1000× larger datasets
- **🔥 JavaScript runtime evolution**: Bun consistently 19-24% faster than Node.js across all dataset sizes
- **📚 CSV library impact**: PapaParse 2× faster than csv-stream for large files, minimal difference for small files
- **🐹 Go's scaling challenge**: Excellent startup (1.7ms) but poor large dataset performance (5.3× slower than Rust)
- **🐍 Python's C advantage**: Built-in CSV module's C implementation keeps Python competitive despite interpreter overhead
- **⚡ Startup vs processing trade-off**: Compiled languages dominate startup, but CSV parsing efficiency becomes critical for large files
- **🎯 Runtime characteristics**: For small workloads, startup overhead dominates; for large files, CSV parsing and algorithm efficiency matter most
- **📊 Cross-language consistency**: Identical algorithm ensures performance differences reflect language/runtime characteristics, not implementation variations

### 3. JavaScript Runtime Comparison

**Bun vs Node.js Performance Analysis:**

| Dataset Size | Bun + csv-stream | Node.js + csv-stream | Bun + PapaParse | Node.js + PapaParse |
| ------------ | ---------------- | -------------------- | --------------- | ------------------- |
| Small        | 26.8ms           | 35.2ms (+24%)        | 30.9ms          | 37.0ms (+16%)       |
| Medium       | 28.4ms           | 37.0ms (+23%)        | 30.0ms          | 37.9ms (+21%)       |
| Large        | 36.3ms           | 45.7ms (+21%)        | 33.4ms          | 41.7ms (+20%)       |
| XLarge       | 172.4ms          | 212.7ms (+19%)       | 88.6ms          | 94.2ms (+6%)        |

**Key Insights:**

- **🔥 Bun consistently outperforms Node.js** by 6-24% across all dataset sizes
- **⚡ Startup advantage diminishes with scale** - Bun's edge reduces from 24% (small) to 6% (xlarge) with PapaParse
- **🚀 Runtime efficiency** - Bun's optimized JavaScript engine shows consistent performance gains
- **📊 Library interaction** - Both runtimes benefit equally from better CSV libraries (PapaParse vs csv-stream)

### 4. CSV Library Performance Analysis

**PapaParse vs csv-stream Comparison:**

| Runtime | Small Dataset    | Medium Dataset   | Large Dataset    | XLarge Dataset    | PapaParse Advantage       |
| ------- | ---------------- | ---------------- | ---------------- | ----------------- | ------------------------- |
| Node.js | 37.0ms vs 35.2ms | 37.9ms vs 37.0ms | 41.7ms vs 45.7ms | 94.2ms vs 212.7ms | **2.26× faster (xlarge)** |
| Bun     | 30.9ms vs 26.8ms | 30.0ms vs 28.4ms | 33.4ms vs 36.3ms | 88.6ms vs 172.4ms | **1.95× faster (xlarge)** |

**Research-Backed Analysis** ([LeanyLabs CSV Parser Benchmarks](https://leanylabs.com/blog/js-csv-parsers-benchmarks/)):

- **📈 PapaParse dominates large files** - Fastest JavaScript CSV parser, even beating `String.split()` in some cases
- **🐌 fast-csv is actually the slowest** - Despite the name, performs worst in comprehensive benchmarks
- **📦 Small overhead for small files** - Library choice matters less for datasets under 1MB
- **🎯 Streaming efficiency** - PapaParse's streaming implementation excels with large datasets
- **⚖️ Bundle size trade-off** - PapaParse (6.8k gzipped) vs csv-parser (1.5k gzipped), but performance justifies the size for large CSV files

## 🤖 AI Tools Comparison

This repository was built using various AI-powered development tools to demonstrate their capabilities in cross-language development. Fully coded in my **Viture Pro XR Glasses** during two days while I had the flu and stayed in bed. The power of Tech! :)

### Tools Used

#### 1. **ChatGPT App with o3** + Search + "Work with Apps" (Cursor access on macOS)

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
  - 1 crash without explanation (just restart & Apple debug report prompt)
  - Auth error lockout (couldn't log back in, "Sign in" button unresponsive)
  - Line-based diff (vs Cursor's character-level diff)
  - Not possible to select and add to chat context (like Cursor's "Add to chat" button)
  - ChatGPT macOS App doesn't support "Work with Apps" for Zed (it does for Cursor)
  - Less precise Rules targeting (Cursor allows advanced pattern matching in mdc files)
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

- **Cursor**: 500 requests = substantial work (this project used ~50 requests for 80% of the work)
- **Zed**: 500 prompts = less work (150 prompts only completed Rust + partial TS = 20% of the work)
- **Claude Sonnet 4**: Currently uses 0.75 request weight in Cursor

### Key Takeaways

1. **Cursor wins for productivity** - More stable, mature, better diff visualization, efficient request usage
2. **Zed shows promise** - Speed and privacy features are compelling, but needs stability improvements. I love Open Source so will watch it's development and it stays installed on my machine.
3. **AI tool pricing varies significantly** in actual value delivered per dollar (I was expecting to finish full project with Zed trial, but 150 prompts were not enough even for 2 languages, at least not in "Burn Mode")
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

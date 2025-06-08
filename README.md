# Table Rotation CLI - Polyglot Implementation

A high-performance CSV table rotation tool implemented in Rust, TypeScript, and Python to demonstrate cross-language performance characteristics and coding practices.

## Table of Contents

- [Table Rotation CLI - Polyglot Implementation](#table-rotation-cli---polyglot-implementation)
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
    - [TypeScript](#typescript)
    - [Python](#python)
  - [Performance Benchmarks](#performance-benchmarks)
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
git clone git@github.com:LucasMatuszewski/csv-table-rotation-cli.git
cd csv-table-rotation-cli

# Run any implementation
./rust/target/release/rotate_cli input-samples/sample-1k.csv > output.csv
node typescript/dist/cli.js input-samples/sample-1k.csv > output.csv
python -m python.rotate_cli input-samples/sample-1k.csv > output.csv
```

## Repository Structure

```
csv-table-rotation-cli/
├── input-samples/
│   └── sample-1k.csv          # Shared test fixtures
├── benchmarks/
│   └── run_hyperfine.sh       # Cross-language performance testing
├── rust/                      # Rust implementation
│   ├── Cargo.toml
│   ├── src/
│   ├── tests/
│   └── benches/
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
./target/release/rotate_cli ../input-samples/sample-1k.csv
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

### TypeScript

**Build & Run:**

```bash
cd typescript
pnpm install
pnpm build
node dist/cli.js ../input-samples/sample-1k.csv
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
pip install -e .
python -m rotate_cli ../input-samples/sample-1k.csv
```

**Test:**

```bash
pytest
mypy src/  # Type checking
```

**Features:**

- Type hints throughout
- Built-in CSV module for streaming
- pytest with benchmark plugin
- PEP 621 compliant project structure

## Performance Benchmarks

Run cross-language performance comparison:

```bash
./benchmarks/run_hyperfine.sh
```

This uses `hyperfine` to measure execution time across all three implementations with statistical analysis (20 runs, 3 warmups).

**Expected Performance Ranking:**

1. **Rust** - Fastest due to zero-cost abstractions and compiled nature
2. **TypeScript/Node.js** - Good performance with V8 optimizations
3. **Python** - Slower due to interpreted nature but still efficient for I/O bound tasks

## Testing

Each implementation includes:

- **Unit tests** - Pure function testing with edge cases
- **Integration tests** - Full CLI testing with sample data
- **Property tests** - Generative testing (where applicable)
- **Performance regressions** - Benchmarks that fail if significantly slower

## CI/CD

GitHub Actions workflows:

- **`ci.yml`** - Build, test, and lint all three implementations in parallel
- **`bench.yml`** - Performance benchmarking with artifact upload

All implementations must pass:

- Zero compiler/linter warnings
- 100% test success rate
- Performance within acceptable bounds

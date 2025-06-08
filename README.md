# Table Rotation CLI - Polyglot Implementation

A high-performance CSV table rotation tool implemented in Rust, TypeScript, and Python to demonstrate cross-language performance characteristics and coding practices.

## Problem Statement

This tool processes CSV files containing square numerical tables and rotates them 90° clockwise (right rotation). Given an input CSV with columns `id` and `json` (where json contains a stringified array of numbers), the tool:

1. Parses each JSON array
2. Determines if it can form a square table (N×N where N² equals array length)
3. If valid, rotates the table 90° clockwise and outputs the flattened result
4. If invalid, marks it as such and outputs an empty array
5. Writes results to stdout as CSV with columns: `id`, `json`, `is_valid`

## Algorithm Explanation

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

### Clockwise Rotation (90° Right)
Each element moves to its new position according to the rotation formula:
- `new_row = old_col`
- `new_col = (n-1) - old_row`

**2×2 Example:**
```
Original:     After rotation:
40  20   →    90  40
90  10        10  20
```
Reading row-by-row: `[90, 40, 10, 20]`

**3×3 Example:**
```
Original:     After rotation:
1  2  3  →    4  1  2
4  5  6       7  5  3
7  8  9       8  9  6
```
Reading row-by-row: `[4, 1, 2, 7, 5, 3, 8, 9, 6]`

Note: In odd-sized tables (3×3, 5×5, etc.), the center element stays in place.

### Implementation Strategy
- **Memory efficient**: In-place rotation using layer-by-layer swaps
- **Streaming**: Process CSV row-by-row to handle large files
- **Time complexity**: O(N²) where N is the side length
- **Space complexity**: O(1) additional memory for rotation

### Example

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

## Table of Contents

- [Quick Start](#quick-start)
- [Repository Structure](#repository-structure)
- [Language Implementations](#language-implementations)
  - [Rust](#rust)
  - [TypeScript](#typescript)
  - [Python](#python)
- [Performance Benchmarks](#performance-benchmarks)
- [Testing](#testing)
- [CI/CD](#cicd)
- [Algorithm](#algorithm)

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

## Algorithm

**Rotation Logic:**
- Convert flat array to conceptual N×N grid
- For each concentric layer, perform 4-way element swap
- Time: O(N²), Space: O(1) additional memory
- Center element in odd-sized grids remains fixed

**Edge Cases Handled:**
- Empty arrays
- Non-square arrays (invalid)
- Single element (1×1 grid)
- Negative numbers
- Large datasets (streaming processing)
- Malformed JSON

---

**Performance Goals:**
- Handle files with millions of rows
- Memory usage independent of file size (streaming)
- Sub-second processing for typical datasets
- Identical output across all three implementations

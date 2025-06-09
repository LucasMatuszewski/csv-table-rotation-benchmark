// Comprehensive benchmarks for the rotation algorithm
// Mirrors the structure of rust/benches/rotation_bench.rs for cross-language comparison
package rotate_test

import (
	"encoding/json"
	"fmt"
	"hash/fnv"
	"testing"

	"github.com/LucasMatuszewski/csv-table-rotation-benchmark/go/internal/rotate"
)

// generateMatrixData creates test data for different matrix sizes and patterns
func generateMatrixData(n int, pattern string) []int {
	size := n * n
	data := make([]int, size)

	switch pattern {
	case "sequential":
		for i := 0; i < size; i++ {
			data[i] = i + 1
		}
	case "random":
		// Use deterministic "random" based on hash for reproducible benchmarks
		for i := 0; i < size; i++ {
			h := fnv.New32a()
			h.Write([]byte(fmt.Sprintf("%d", i)))
			data[i] = int(h.Sum32() % 10000)
		}
	case "repeated":
		for i := 0; i < size; i++ {
			data[i] = 42
		}
	case "negative":
		for i := 0; i < size; i++ {
			data[i] = -(i + 1)
		}
	case "mixed":
		for i := 0; i < size; i++ {
			if (i+1)%2 == 0 {
				data[i] = i + 1
			} else {
				data[i] = -(i + 1)
			}
		}
	default:
		for i := 0; i < size; i++ {
			data[i] = i + 1
		}
	}
	return data
}

// BenchmarkRotationSizes tests the core rotation algorithm with different matrix sizes
func BenchmarkRotationSizes(b *testing.B) {
	sizes := []int{1, 2, 3, 4, 5, 8, 10, 16, 25, 50, 100}

	for _, n := range sizes {
		data := generateMatrixData(n, "sequential")
		b.Run(fmt.Sprintf("rotate_matrix_%dx%d", n, n), func(b *testing.B) {
			b.ReportAllocs()
			for i := 0; i < b.N; i++ {
				testData := make([]int, len(data))
				copy(testData, data)
				_ = rotate.RotateRight(testData)
			}
		})
	}
}

// BenchmarkRotationPatterns tests rotation with different data patterns
func BenchmarkRotationPatterns(b *testing.B) {
	n := 10 // 10x10 matrix
	patterns := []string{"sequential", "random", "repeated", "negative", "mixed"}

	for _, pattern := range patterns {
		data := generateMatrixData(n, pattern)
		b.Run(fmt.Sprintf("rotate_pattern_%s", pattern), func(b *testing.B) {
			b.ReportAllocs()
			for i := 0; i < b.N; i++ {
				testData := make([]int, len(data))
				copy(testData, data)
				_ = rotate.RotateRight(testData)
			}
		})
	}
}

// BenchmarkSquareLenValidation tests square length validation performance
func BenchmarkSquareLenValidation(b *testing.B) {
	testLengths := []int{
		// Perfect squares
		1, 4, 9, 16, 25, 36, 49, 64, 81, 100,
		// Non-perfect squares
		2, 3, 5, 6, 7, 8, 10, 15, 50, 99,
		// Large numbers
		1000000, 1000001, 999999,
	}

	for _, length := range testLengths {
		b.Run(fmt.Sprintf("validate_length_%d", length), func(b *testing.B) {
			for i := 0; i < b.N; i++ {
				_, _ = rotate.SquareLen(length)
			}
		})
	}
}

// BenchmarkMultipleRotations tests performance consistency across multiple rotations
func BenchmarkMultipleRotations(b *testing.B) {
	n := 10
	data := generateMatrixData(n, "sequential")
	rotationCounts := []int{1, 4, 8, 16, 32}

	for _, count := range rotationCounts {
		b.Run(fmt.Sprintf("rotations_%d", count), func(b *testing.B) {
			b.ReportAllocs()
			for i := 0; i < b.N; i++ {
				testData := make([]int, len(data))
				copy(testData, data)
				for j := 0; j < count; j++ {
					_ = rotate.RotateRight(testData)
				}
			}
		})
	}
}

// BenchmarkCSVProcessing simulates the full CSV processing pipeline
func BenchmarkCSVProcessing(b *testing.B) {
	// Simulate different JSON array sizes commonly found in CSV
	testCases := []struct {
		n        int
		jsonData string
	}{
		{1, "[1]"},
		{2, "[1, 2, 3, 4]"},
		{3, "[1, 2, 3, 4, 5, 6, 7, 8, 9]"},
		{4, "[1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16]"},
		{5, "[1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25]"},
	}

	// Generate large JSON for 10x10
	largeJSON := "["
	for i := 1; i <= 100; i++ {
		if i > 1 {
			largeJSON += ", "
		}
		largeJSON += fmt.Sprintf("%d", i)
	}
	largeJSON += "]"
	testCases = append(testCases, struct {
		n        int
		jsonData string
	}{10, largeJSON})

	for _, tc := range testCases {
		b.Run(fmt.Sprintf("json_parse_rotate_%dx%d", tc.n, tc.n), func(b *testing.B) {
			b.ReportAllocs()
			for i := 0; i < b.N; i++ {
				// Simulate the full processing pipeline
				var numbers []float64
				if err := json.Unmarshal([]byte(tc.jsonData), &numbers); err != nil {
					b.Fatal(err)
				}

				if _, err := rotate.SquareLen(len(numbers)); err == nil && len(numbers) > 0 {
					_ = rotate.RotateRight(numbers)
					if _, err := json.Marshal(numbers); err != nil {
						b.Fatal(err)
					}
				}
			}
		})
	}
}

// BenchmarkMemoryPatterns tests memory allocation patterns
func BenchmarkMemoryPatterns(b *testing.B) {
	n := 20
	data := generateMatrixData(n, "sequential")

	b.Run("in_place_rotation", func(b *testing.B) {
		b.ReportAllocs()
		for i := 0; i < b.N; i++ {
			testData := make([]int, len(data))
			copy(testData, data)
			_ = rotate.RotateRight(testData)
		}
	})

	b.Run("clone_overhead", func(b *testing.B) {
		b.ReportAllocs()
		for i := 0; i < b.N; i++ {
			_ = make([]int, len(data))
			_ = make([]int, len(data))
			_ = make([]int, len(data))
		}
	})
}

// BenchmarkEdgeCases tests edge cases and error handling
func BenchmarkEdgeCases(b *testing.B) {
	testCases := []struct {
		name string
		data []int
	}{
		{"empty_array", []int{}},
		{"single_element", []int{42}},
		{"non_square_small", []int{1, 2, 3}},
		{"non_square_medium", []int{1, 2, 3, 4, 5, 6, 7, 8}},
		{"large_valid", generateMatrixData(50, "sequential")}, // 50x50
	}

	for _, tc := range testCases {
		b.Run(fmt.Sprintf("edge_case_%s", tc.name), func(b *testing.B) {
			b.ReportAllocs()
			for i := 0; i < b.N; i++ {
				testData := make([]int, len(tc.data))
				copy(testData, tc.data)
				_ = rotate.RotateRight(testData)
			}
		})
	}
}

// BenchmarkScaling tests how performance scales with matrix size
func BenchmarkScaling(b *testing.B) {
	sizes := []struct {
		n     int
		label string
	}{
		{4, "4x4"},
		{8, "8x8"},
		{16, "16x16"},
		{32, "32x32"},
		{64, "64x64"},
		{100, "100x100"},
		{128, "128x128"},
	}

	for _, size := range sizes {
		data := generateMatrixData(size.n, "sequential")
		b.Run(fmt.Sprintf("scale_%s", size.label), func(b *testing.B) {
			b.ReportAllocs()
			for i := 0; i < b.N; i++ {
				testData := make([]int, len(data))
				copy(testData, data)
				_ = rotate.RotateRight(testData)
			}
		})
	}
} 
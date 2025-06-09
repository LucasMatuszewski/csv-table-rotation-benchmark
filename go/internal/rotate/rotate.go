// Package rotate provides functions to validate and rotate square numerical tables
// represented as flat arrays. Tables are rotated by shifting each element one position clockwise around its ring.
package rotate

import (
	"errors"
	"math"
)

// Custom error types for rotation operations.
var (
	ErrEmpty     = errors.New("array is empty")
	ErrNotSquare = errors.New("array length is not a perfect square")
)

// SquareLen returns the side length if len is a perfect square (n × n), else returns an error.
//
// Examples:
//
//	SquareLen(4) returns 2, nil
//	SquareLen(9) returns 3, nil
//	SquareLen(5) returns 0, ErrNotSquare
func SquareLen(length int) (int, error) {
	if length == 0 {
		return 0, ErrEmpty
	}

	n := int(math.Sqrt(float64(length)))
	if n*n == length {
		return n, nil
	}
	return 0, ErrNotSquare
}

// RotateRight rotates an N×N matrix by shifting each element one position clockwise around its ring.
//
// This uses the canonical "layer walk" algorithm that processes each concentric ring
// from outside to inside. Each ring is rotated by walking clockwise:
// top row → right column → bottom row → left column
//
// The input slice represents a square table read row-by-row:
// - [40, 20, 90, 10] represents a 2×2 table: [[40, 20], [90, 10]]
// - After one-step clockwise shift: [[90, 40], [10, 20]] → [90, 40, 10, 20]
//
// Complexity:
// - Time: O(N²) - touches each element exactly once
// - Space: O(1) - uses only two temporary variables
//
// Arguments:
//
//	data - Slice containing the table elements (modified in-place)
//
// Returns:
//
//	error - ErrEmpty if slice is empty, ErrNotSquare if not a perfect square
//
// Examples:
//
//	data := []int{40, 20, 90, 10}
//	err := RotateRight(data)
//	// data is now [90, 40, 10, 20]
func RotateRight[T any](data []T) error {
	length := len(data)

	if length == 0 {
		return ErrEmpty
	}

	n, err := SquareLen(length)
	if err != nil {
		return err
	}

	// Handle trivial cases
	if n <= 1 {
		return nil
	}

	// Process each concentric ring from outside to inside
	for layer := 0; layer < n/2; layer++ {
		rotateRingClockwise(data, n, layer)
	}

	return nil
}

// rotateRingClockwise rotates a single ring of the matrix one position clockwise using in-place swaps.
//
// This is the core of the canonical layer-walk algorithm. It walks around the ring
// in clockwise order, swapping elements with a temporary variable.
func rotateRingClockwise[T any](data []T, n int, layer int) {
	first := layer
	last := n - 1 - layer

	// Save the element that will be overwritten first (top-left of the ring)
	prev := data[idx(n, first+1, first)] // Element below top-left

	// Top row: left → right
	for col := first; col <= last; col++ {
		temp := data[idx(n, first, col)]
		data[idx(n, first, col)] = prev
		prev = temp
	}

	// Right column: top+1 → bottom
	for row := first + 1; row <= last; row++ {
		temp := data[idx(n, row, last)]
		data[idx(n, row, last)] = prev
		prev = temp
	}

	// Bottom row: right-1 → left
	for col := last - 1; col >= first; col-- {
		temp := data[idx(n, last, col)]
		data[idx(n, last, col)] = prev
		prev = temp
	}

	// Left column: bottom-1 → top+1
	for row := last - 1; row > first; row-- {
		temp := data[idx(n, row, first)]
		data[idx(n, row, first)] = prev
		prev = temp
	}
}

// idx converts 2D table coordinates (row, col) to 1D array index.
//
// For an N×N table stored row-by-row in a flat array:
// index = row * n + col
func idx(n, row, col int) int {
	return row*n + col
}

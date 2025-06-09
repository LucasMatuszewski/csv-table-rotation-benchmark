package rotate_test

import (
	"reflect"
	"testing"

	"github.com/LucasMatuszewski/csv-table-rotation-benchmark/go/internal/rotate"
)

func TestSquareLen(t *testing.T) {
	tests := []struct {
		input    int
		expected int
		hasError bool
	}{
		{0, 0, true},   // Empty array
		{1, 1, false},  // 1x1
		{4, 2, false},  // 2x2
		{9, 3, false},  // 3x3
		{16, 4, false}, // 4x4
		{25, 5, false}, // 5x5
		// Non-perfect squares
		{2, 0, true},
		{3, 0, true},
		{5, 0, true},
		{8, 0, true},
		{10, 0, true},
	}

	for _, test := range tests {
		result, err := rotate.SquareLen(test.input)
		if test.hasError {
			if err == nil {
				t.Errorf("Expected error for input %d, but got none", test.input)
			}
		} else {
			if err != nil {
				t.Errorf("Unexpected error for input %d: %v", test.input, err)
			}
			if result != test.expected {
				t.Errorf("For input %d: expected %d, got %d", test.input, test.expected, result)
			}
		}
	}
}

func TestRotate1x1StaysSame(t *testing.T) {
	// Original: [42]  →  After: [42]
	// Single element matrices don't change
	// Expected: [42]
	data := []int{42}
	err := rotate.RotateRight(data)
	if err != nil {
		t.Fatalf("Unexpected error: %v", err)
	}
	expected := []int{42}
	if !reflect.DeepEqual(data, expected) {
		t.Errorf("Expected %v, got %v", expected, data)
	}
}

func TestRotate2x2(t *testing.T) {
	// Original:      After 1-step clockwise:
	// [1, 2]     →   [3, 1]
	// [3, 4]         [4, 2]
	//
	// Ring walk: 1→2→4→3 becomes 3→1→2→4
	// Expected: [3, 1, 4, 2]
	data := []int{1, 2, 3, 4}
	err := rotate.RotateRight(data)
	if err != nil {
		t.Fatalf("Unexpected error: %v", err)
	}
	expected := []int{3, 1, 4, 2}
	if !reflect.DeepEqual(data, expected) {
		t.Errorf("Expected %v, got %v", expected, data)
	}
}

func TestRotate3x3(t *testing.T) {
	// Original:        After 1-step clockwise:
	// [1, 2, 3]    →   [4, 1, 2]
	// [4, 5, 6]        [7, 5, 3]
	// [7, 8, 9]        [8, 9, 6]
	//
	// Outer ring: 1→2→3→6→9→8→7→4 becomes 4→1→2→3→6→9→8→7
	// Center: 5 stays 5 (unchanged)
	// Expected: [4, 1, 2, 7, 5, 3, 8, 9, 6]
	data := []int{1, 2, 3, 4, 5, 6, 7, 8, 9}
	err := rotate.RotateRight(data)
	if err != nil {
		t.Fatalf("Unexpected error: %v", err)
	}
	expected := []int{4, 1, 2, 7, 5, 3, 8, 9, 6}
	if !reflect.DeepEqual(data, expected) {
		t.Errorf("Expected %v, got %v", expected, data)
	}
}

func TestRotate4x4(t *testing.T) {
	// Original:              After 1-step clockwise:
	// [ 1,  2,  3,  4]   →   [ 5,  1,  2,  3]
	// [ 5,  6,  7,  8]       [ 9, 10,  6,  4]
	// [ 9, 10, 11, 12]       [13, 11,  7,  8]
	// [13, 14, 15, 16]       [14, 15, 16, 12]
	//
	// Outer ring: 1→2→3→4→8→12→16→15→14→13→9→5 becomes 5→1→2→3→4→8→12→16→15→14→13→9
	// Inner ring: 6→7→11→10 becomes 10→6→7→11
	// Expected: [5, 1, 2, 3, 9, 10, 6, 4, 13, 11, 7, 8, 14, 15, 16, 12]
	data := []int{1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16}
	err := rotate.RotateRight(data)
	if err != nil {
		t.Fatalf("Unexpected error: %v", err)
	}
	expected := []int{5, 1, 2, 3, 9, 10, 6, 4, 13, 11, 7, 8, 14, 15, 16, 12}
	if !reflect.DeepEqual(data, expected) {
		t.Errorf("Expected %v, got %v", expected, data)
	}
}

func TestRotateEmptyArray(t *testing.T) {
	var data []int
	err := rotate.RotateRight(data)
	if err != rotate.ErrEmpty {
		t.Errorf("Expected ErrEmpty, got %v", err)
	}
}

func TestRotateNonSquare(t *testing.T) {
	data := []int{1, 2, 3} // Length 3 is not a perfect square
	err := rotate.RotateRight(data)
	if err != rotate.ErrNotSquare {
		t.Errorf("Expected ErrNotSquare, got %v", err)
	}
}

func TestRotateWithNegatives(t *testing.T) {
	// Original:         After 1-step clockwise:
	// [-1, -2]      →   [-3, -1]
	// [-3, -4]          [-4, -2]
	//
	// Ring: -1→-2→-4→-3 becomes -3→-1→-2→-4
	// Expected: [-3, -1, -4, -2]
	data := []int{-1, -2, -3, -4}
	err := rotate.RotateRight(data)
	if err != nil {
		t.Fatalf("Unexpected error: %v", err)
	}
	expected := []int{-3, -1, -4, -2}
	if !reflect.DeepEqual(data, expected) {
		t.Errorf("Expected %v, got %v", expected, data)
	}
}

func TestRotateWithZeros(t *testing.T) {
	data := []int{0, 0, 0, 0}
	err := rotate.RotateRight(data)
	if err != nil {
		t.Fatalf("Unexpected error: %v", err)
	}
	expected := []int{0, 0, 0, 0}
	if !reflect.DeepEqual(data, expected) {
		t.Errorf("Expected %v, got %v", expected, data)
	}
}

func TestRotateRingSizeTimesIdentity(t *testing.T) {
	// For a 3x3, the outer ring has 8 elements, so rotating 8 times should return to original
	original := []int{1, 2, 3, 4, 5, 6, 7, 8, 9}
	data := make([]int, len(original))
	copy(data, original)

	// Rotate 8 times (size of outer ring) should return to original
	for i := 0; i < 8; i++ {
		err := rotate.RotateRight(data)
		if err != nil {
			t.Fatalf("Unexpected error on iteration %d: %v", i, err)
		}
	}

	if !reflect.DeepEqual(data, original) {
		t.Errorf("After 8 rotations, expected %v, got %v", original, data)
	}
}

func TestRotate5x5(t *testing.T) {
	// Original:                    After 1-step clockwise:
	// [ 1,  2,  3,  4,  5]     →   [ 6,  1,  2,  3,  4]
	// [ 6,  7,  8,  9, 10]         [11, 12,  7,  8,  5]
	// [11, 12, 13, 14, 15]         [16, 17, 13,  9, 10]
	// [16, 17, 18, 19, 20]         [21, 18, 19, 14, 15]
	// [21, 22, 23, 24, 25]         [22, 23, 24, 25, 20]
	//
	// Outer ring: 1→2→3→4→5→10→15→20→25→24→23→22→21→16→11→6 becomes 6→1→2→3→4→5→10→15→20→25→24→23→22→21→16→11
	// Inner ring: 7→8→9→14→19→18→17→12 becomes 12→7→8→9→14→19→18→17
	// Center: 13 stays 13 (unchanged)
	// Expected: [6, 1, 2, 3, 4, 11, 12, 7, 8, 5, 16, 17, 13, 9, 10, 21, 18, 19, 14, 15, 22, 23, 24, 25, 20]
	data := make([]int, 25)
	for i := range data {
		data[i] = i + 1
	}
	err := rotate.RotateRight(data)
	if err != nil {
		t.Fatalf("Unexpected error: %v", err)
	}
	expected := []int{
		6, 1, 2, 3, 4,
		11, 12, 7, 8, 5,
		16, 17, 13, 9, 10,
		21, 18, 19, 14, 15,
		22, 23, 24, 25, 20,
	}
	if !reflect.DeepEqual(data, expected) {
		t.Errorf("Expected %v, got %v", expected, data)
	}
}

func TestRotate10x10(t *testing.T) {
	// Original 10×10 (1-100):           After 1-step clockwise:
	// [ 1  2  3  4  5  6  7  8  9 10]   [11  1  2  3  4  5  6  7  8  9]
	// [11 12 13 14 15 16 17 18 19 20]   [21 22 12 13 14 15 16 17 18 10]
	// [21 22 23 24 25 26 27 28 29 30] → [31 32 33 23 24 25 26 27 19 20]
	// [31 32 33 34 35 36 37 38 39 40]   [41 42 43 44 34 35 36 28 29 30]
	// [41 42 43 44 45 46 47 48 49 50]   [51 52 53 54 55 45 37 38 39 40]
	// [51 52 53 54 55 56 57 58 59 60]   [61 62 63 64 56 46 47 48 49 50]
	// [61 62 63 64 65 66 67 68 69 70]   [71 72 73 65 66 67 57 58 59 60]
	// [71 72 73 74 75 76 77 78 79 80]   [81 82 74 75 76 77 78 68 69 70]
	// [81 82 83 84 85 86 87 88 89 90]   [91 83 84 85 86 87 88 89 79 80]
	// [91 92 93 94 95 96 97 98 99100]   [92 93 94 95 96 97 98 99100 90]
	//
	// Four concentric rings all shift one position clockwise:
	// Ring 0 (outer): 1→2→...→10→20→...→100→99→...→91→81→...→11 becomes 11→1→...→9→10→...→90→100→...→92→91→...→21
	// Ring 1: 12→13→...→19→29→...→99→98→...→92→82→...→22 becomes 22→12→...→18→19→...→89→99→...→93→92→...→32
	// Ring 2: 23→24→...→28→38→...→98→97→...→93→83→...→33 becomes 33→23→...→27→28→...→88→98→...→94→93→...→43
	// Ring 3 (inner): 34→35→36→37→47→57→67→76→75→74→64→54→44→45→46→56→66→65→55 becomes 44→34→35→36→37→47→57→67→76→75→74→64→54→55→56→66→65→45→46
	//
	// Since 10 is even, no center element stays fixed - all elements move
	// Expected: [11,1,2,3,4,5,6,7,8,9, 21,22,12,13,14,15,16,17,18,10, ...]
	data := make([]int, 100)
	for i := range data {
		data[i] = i + 1
	}
	err := rotate.RotateRight(data)
	if err != nil {
		t.Fatalf("Unexpected error: %v", err)
	}
	expected := []int{
		11, 1, 2, 3, 4, 5, 6, 7, 8, 9,
		21, 22, 12, 13, 14, 15, 16, 17, 18, 10,
		31, 32, 33, 23, 24, 25, 26, 27, 19, 20,
		41, 42, 43, 44, 34, 35, 36, 28, 29, 30,
		51, 52, 53, 54, 55, 45, 37, 38, 39, 40,
		61, 62, 63, 64, 56, 46, 47, 48, 49, 50,
		71, 72, 73, 65, 66, 67, 57, 58, 59, 60,
		81, 82, 74, 75, 76, 77, 78, 68, 69, 70,
		91, 83, 84, 85, 86, 87, 88, 89, 79, 80,
		92, 93, 94, 95, 96, 97, 98, 99, 100, 90,
	}
	if !reflect.DeepEqual(data, expected) {
		t.Errorf("Expected %v, got %v", expected, data)
	}
}

 
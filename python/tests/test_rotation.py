"""
Test cases for the rotation algorithm.

These tests mirror the TypeScript test cases to ensure algorithmic consistency
across all three implementations (Rust, TypeScript, Python).
"""

import pytest
from rotate_cli.rotation import (
    square_len,
    rotate_right,
    NotSquareError,
    EmptyArrayError,
    validate_number_array,
    is_valid_number,
)


class TestSquareLen:
    """Test the square_len function."""
    
    def test_returns_correct_side_length_for_perfect_squares(self):
        assert square_len(0) == 0
        assert square_len(1) == 1
        assert square_len(4) == 2
        assert square_len(9) == 3
        assert square_len(16) == 4
        assert square_len(25) == 5
        assert square_len(100) == 10

    def test_returns_none_for_non_perfect_squares(self):
        assert square_len(2) is None
        assert square_len(3) is None
        assert square_len(5) is None
        assert square_len(8) is None
        assert square_len(10) is None
        assert square_len(15) is None
        assert square_len(99) is None


class TestRotateRight:
    """Test the rotate_right function."""
    
    def test_handles_1x1_matrix_stays_unchanged(self):
        # Original: [42]  →  After: [42]
        # Single element matrices don't change
        # Expected: [42]
        data = [42]
        rotate_right(data)
        assert data == [42]

    def test_handles_2x2_matrix_rotation(self):
        # Original:      After 1-step clockwise:
        # [1, 2]     →   [3, 1]
        # [3, 4]         [4, 2]
        #
        # Ring walk: 1→2→4→3 becomes 3→1→2→4
        # Expected: [3, 1, 4, 2]
        data = [1, 2, 3, 4]
        rotate_right(data)
        assert data == [3, 1, 4, 2]

    def test_handles_3x3_matrix_rotation(self):
        # Original:        After 1-step clockwise:
        # [1, 2, 3]    →   [4, 1, 2]
        # [4, 5, 6]        [7, 5, 3]
        # [7, 8, 9]        [8, 9, 6]
        #
        # Outer ring: 1→2→3→6→9→8→7→4 becomes 4→1→2→3→6→9→8→7
        # Center: 5 stays 5 (unchanged)
        # Expected: [4, 1, 2, 7, 5, 3, 8, 9, 6]
        data = [1, 2, 3, 4, 5, 6, 7, 8, 9]
        rotate_right(data)
        assert data == [4, 1, 2, 7, 5, 3, 8, 9, 6]

    def test_handles_4x4_matrix_rotation(self):
        # Original:              After 1-step clockwise:
        # [ 1,  2,  3,  4]   →   [ 5,  1,  2,  3]
        # [ 5,  6,  7,  8]       [ 9, 10,  6,  4]
        # [ 9, 10, 11, 12]       [13, 11,  7,  8]
        # [13, 14, 15, 16]       [14, 15, 16, 12]
        #
        # Outer ring: 1→2→3→4→8→12→16→15→14→13→9→5 becomes 5→1→2→3→4→8→12→16→15→14→13→9
        # Inner ring: 6→7→11→10 becomes 10→6→7→11
        # Expected: [5, 1, 2, 3, 9, 10, 6, 4, 13, 11, 7, 8, 14, 15, 16, 12]
        data = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16]
        rotate_right(data)
        expected = [5, 1, 2, 3, 9, 10, 6, 4, 13, 11, 7, 8, 14, 15, 16, 12]
        assert data == expected

    def test_handles_5x5_matrix_rotation(self):
        # Original:                    After 1-step clockwise:
        # [ 1,  2,  3,  4,  5]     →   [ 6,  1,  2,  3,  4]
        # [ 6,  7,  8,  9, 10]         [11, 12,  7,  8,  5]
        # [11, 12, 13, 14, 15]         [16, 17, 13,  9, 10]
        # [16, 17, 18, 19, 20]         [21, 18, 19, 14, 15]
        # [21, 22, 23, 24, 25]         [22, 23, 24, 25, 20]
        #
        # Outer ring: 1→2→3→4→5→10→15→20→25→24→23→22→21→16→11→6 becomes 
        # 6→1→2→3→4→5→10→15→20→25→24→23→22→21→16→11
        # Inner ring: 7→8→9→14→19→18→17→12 becomes 12→7→8→9→14→19→18→17
        # Center: 13 stays 13 (unchanged)
        data = list(range(1, 26))
        rotate_right(data)
        expected = [
            6, 1, 2, 3, 4, 11, 12, 7, 8, 5, 16, 17, 13, 9, 10, 
            21, 18, 19, 14, 15, 22, 23, 24, 25, 20,
        ]
        assert data == expected

    def test_handles_negative_numbers(self):
        # Original:         After 1-step clockwise:
        # [-1, -2]      →   [-3, -1]
        # [-3, -4]          [-4, -2]
        #
        # Ring: -1→-2→-4→-3 becomes -3→-1→-2→-4
        # Expected: [-3, -1, -4, -2]
        data = [-1, -2, -3, -4]
        rotate_right(data)
        assert data == [-3, -1, -4, -2]

    def test_handles_zeros(self):
        data = [0, 0, 0, 0]
        rotate_right(data)
        assert data == [0, 0, 0, 0]

    def test_throws_empty_array_error_for_empty_array(self):
        data = []
        with pytest.raises(EmptyArrayError):
            rotate_right(data)

    def test_throws_not_square_error_for_non_square_arrays(self):
        data1 = [1, 2, 3]  # Length 3 is not a perfect square
        with pytest.raises(NotSquareError):
            rotate_right(data1)

        data2 = [1, 2, 3, 4, 5]  # Length 5 is not a perfect square
        with pytest.raises(NotSquareError):
            rotate_right(data2)

        data3 = [1, 2, 3, 4, 5, 6, 7, 8]  # Length 8 is not a perfect square
        with pytest.raises(NotSquareError):
            rotate_right(data3)

    def test_multiple_rotations_return_to_original_ring_size_identity(self):
        # For a 3x3, the outer ring has 8 elements, so rotating 8 times should return to original
        original = [1, 2, 3, 4, 5, 6, 7, 8, 9]
        data = original.copy()

        # Rotate 8 times (size of outer ring) should return to original
        for _ in range(8):
            rotate_right(data)

        assert data == original

    def test_handles_large_matrices(self):
        # Test 10x10 matrix to ensure algorithm scales
        data = list(range(1, 101))
        original_data = data.copy()

        # Should not throw and should modify the data
        rotate_right(data)
        assert data != original_data

        # Spot check a few positions
        assert data[0] == 11  # Top-left should get value from left side (was 11)
        assert data[9] == 9   # Top-right should get value from previous position (was 9)


class TestIsValidNumber:
    """Test the is_valid_number function."""
    
    def test_returns_true_for_valid_numbers(self):
        assert is_valid_number(0)
        assert is_valid_number(42)
        assert is_valid_number(-5)
        assert is_valid_number(3.14)
        assert is_valid_number(-0)

    def test_returns_false_for_invalid_values(self):
        assert not is_valid_number(float('nan'))
        assert not is_valid_number(float('inf'))
        assert not is_valid_number(float('-inf'))
        assert not is_valid_number('42')
        assert not is_valid_number(None)
        assert not is_valid_number({})
        assert not is_valid_number([])
        assert not is_valid_number(True)


class TestValidateNumberArray:
    """Test the validate_number_array function."""
    
    def test_returns_number_array_for_valid_input(self):
        assert validate_number_array([1, 2, 3, 4]) == [1, 2, 3, 4]
        assert validate_number_array([-1, 0, 1]) == [-1, 0, 1]
        assert validate_number_array([]) == []
        assert validate_number_array([42]) == [42]

    def test_returns_none_for_non_arrays(self):
        assert validate_number_array(42) is None
        assert validate_number_array('hello') is None
        assert validate_number_array(None) is None
        assert validate_number_array({}) is None

    def test_returns_none_for_arrays_with_non_numbers(self):
        assert validate_number_array([1, 'hello', 3]) is None
        assert validate_number_array([1, None, 3]) is None
        assert validate_number_array([1, {}, 3]) is None
        assert validate_number_array([1, [], 3]) is None
        assert validate_number_array([1, True, 3]) is None
        assert validate_number_array([1, float('nan'), 3]) is None
        assert validate_number_array([1, float('inf'), 3]) is None


class TestAlgorithmConsistency:
    """Test algorithm consistency with other implementations."""
    
    def test_produces_same_results_as_rust_implementation_for_key_test_cases(self):
        # Test case 1: 2x2 matrix
        data1 = [1, 2, 3, 4]
        rotate_right(data1)
        assert data1 == [3, 1, 4, 2]

        # Test case 2: 3x3 matrix (matches recruitment spec)
        data2 = [1, 2, 3, 4, 5, 6, 7, 8, 9]
        rotate_right(data2)
        assert data2 == [4, 1, 2, 7, 5, 3, 8, 9, 6]

        # Test case 3: Negative numbers
        data3 = [-1, -2, -3, -4]
        rotate_right(data3)
        assert data3 == [-3, -1, -4, -2]

    def test_rotation_is_deterministic_and_repeatable(self):
        original = [1, 2, 3, 4, 5, 6, 7, 8, 9]

        data1 = original.copy()
        data2 = original.copy()

        rotate_right(data1)
        rotate_right(data2)

        assert data1 == data2
        assert data1 == [4, 1, 2, 7, 5, 3, 8, 9, 6] 
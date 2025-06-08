//! Library crate for table rotation logic.
//!
//! This crate provides functions to validate and rotate square numerical tables
//! represented as flat arrays. Tables are rotated 90° clockwise (right rotation).

use std::error::Error;
use std::fmt;

/// Custom error type for rotation operations.
#[derive(Debug)]
pub enum RotationError {
    NotSquare,
    Empty,
}

impl fmt::Display for RotationError {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            RotationError::NotSquare => write!(f, "Array length is not a perfect square"),
            RotationError::Empty => write!(f, "Array is empty"),
        }
    }
}

impl Error for RotationError {}

/// Returns `Some(n)` if `len` is a perfect square (n × n), else `None`.
///
/// # Examples
///
/// ```
/// use rotate_cli::square_len;
///
/// assert_eq!(square_len(4), Some(2));
/// assert_eq!(square_len(9), Some(3));
/// assert_eq!(square_len(5), None);
/// ```
pub fn square_len(len: usize) -> Option<usize> {
    if len == 0 {
        return Some(0);
    }

    let n = (len as f64).sqrt() as usize;
    if n * n == len { Some(n) } else { None }
}

/// Rotates an N×N matrix by shifting each element one position clockwise around its ring.
///
/// This uses the canonical "layer walk" algorithm that processes each concentric ring
/// from outside to inside. Each ring is rotated by walking clockwise:
/// top row → right column → bottom row → left column
///
/// The input array represents a square table read row-by-row:
/// - `[40, 20, 90, 10]` represents a 2×2 table: `[[40, 20], [90, 10]]`
/// - After one-step clockwise shift: `[[90, 40], [10, 20]]` → `[90, 40, 10, 20]`
///
/// # Complexity
/// - Time: O(N²) - touches each element exactly once
/// - Space: O(1) - uses only two temporary variables
///
/// # Arguments
///
/// * `data` - Mutable slice containing the table elements
///
/// # Returns
///
/// * `Ok(())` - Success
/// * `Err(RotationError)` - If the array is empty or not a perfect square
///
/// # Examples
///
/// ```
/// use rotate_cli::rotate_right;
///
/// let mut data = vec![40, 20, 90, 10];
/// rotate_right(&mut data).unwrap();
/// assert_eq!(data, vec![90, 40, 10, 20]);
/// ```
pub fn rotate_right<T: Copy>(data: &mut [T]) -> Result<(), RotationError> {
    let len = data.len();

    if len == 0 {
        return Err(RotationError::Empty);
    }

    let n = square_len(len).ok_or(RotationError::NotSquare)?;

    // Handle trivial cases
    if n <= 1 {
        return Ok(());
    }

    // Process each concentric ring from outside to inside
    for layer in 0..n / 2 {
        rotate_ring_clockwise(data, n, layer);
    }

    Ok(())
}

/// Rotates a single ring of the matrix one position clockwise using in-place swaps.
///
/// This is the core of the canonical layer-walk algorithm. It walks around the ring
/// in clockwise order, swapping elements with a temporary variable.
fn rotate_ring_clockwise<T: Copy>(data: &mut [T], n: usize, layer: usize) {
    let first = layer;
    let last = n - 1 - layer;

    // Save the element that will be overwritten first (top-left of the ring)
    let mut prev = data[idx(n, first + 1, first)]; // Element below top-left

    // Top row: left → right
    for col in first..=last {
        let temp = data[idx(n, first, col)];
        data[idx(n, first, col)] = prev;
        prev = temp;
    }

    // Right column: top+1 → bottom
    for row in (first + 1)..=last {
        let temp = data[idx(n, row, last)];
        data[idx(n, row, last)] = prev;
        prev = temp;
    }

    // Bottom row: right-1 → left
    for col in (first..last).rev() {
        let temp = data[idx(n, last, col)];
        data[idx(n, last, col)] = prev;
        prev = temp;
    }

    // Left column: bottom-1 → top+1
    for row in ((first + 1)..last).rev() {
        let temp = data[idx(n, row, first)];
        data[idx(n, row, first)] = prev;
        prev = temp;
    }
}

/// Converts 2D table coordinates (row, col) to 1D array index.
///
/// For an N×N table stored row-by-row in a flat array:
/// `index = row * n + col`
#[inline]
const fn idx(n: usize, row: usize, col: usize) -> usize {
    row * n + col
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_square_len() {
        assert_eq!(square_len(0), Some(0));
        assert_eq!(square_len(1), Some(1));
        assert_eq!(square_len(4), Some(2));
        assert_eq!(square_len(9), Some(3));
        assert_eq!(square_len(16), Some(4));
        assert_eq!(square_len(25), Some(5));

        // Non-perfect squares
        assert_eq!(square_len(2), None);
        assert_eq!(square_len(3), None);
        assert_eq!(square_len(5), None);
        assert_eq!(square_len(8), None);
        assert_eq!(square_len(10), None);
    }

    #[test]
    fn test_rotate_1x1_stays_same() {
        // Original: [42]  →  After: [42]
        // Single element matrices don't change
        // Expected: vec![42]
        let mut data = vec![42];
        rotate_right(&mut data).unwrap();
        assert_eq!(data, vec![42]);
    }

    #[test]
    fn test_rotate_2x2() {
        // Original:      After 1-step clockwise:
        // [1, 2]     →   [3, 1]
        // [3, 4]         [4, 2]
        //
        // Ring walk: 1→2→4→3 becomes 3→1→2→4
        // Expected: vec![3, 1, 4, 2]
        let mut data = vec![1, 2, 3, 4];
        rotate_right(&mut data).unwrap();
        assert_eq!(data, vec![3, 1, 4, 2]);
    }

    #[test]
    fn test_rotate_3x3() {
        // Original:        After 1-step clockwise:
        // [1, 2, 3]    →   [4, 1, 2]
        // [4, 5, 6]        [7, 5, 3]
        // [7, 8, 9]        [8, 9, 6]
        //
        // Outer ring: 1→2→3→6→9→8→7→4 becomes 4→1→2→3→6→9→8→7
        // Center: 5 stays 5 (unchanged)
        // Expected: vec![4, 1, 2, 7, 5, 3, 8, 9, 6]
        let mut data = vec![1, 2, 3, 4, 5, 6, 7, 8, 9];
        rotate_right(&mut data).unwrap();
        assert_eq!(data, vec![4, 1, 2, 7, 5, 3, 8, 9, 6]);
    }

    #[test]
    fn test_rotate_4x4() {
        // Original:              After 1-step clockwise:
        // [ 1,  2,  3,  4]   →   [ 5,  1,  2,  3]
        // [ 5,  6,  7,  8]       [ 9, 10,  6,  4]
        // [ 9, 10, 11, 12]       [13, 11,  7,  8]
        // [13, 14, 15, 16]       [14, 15, 16, 12]
        //
        // Outer ring: 1→2→3→4→8→12→16→15→14→13→9→5 becomes 5→1→2→3→4→8→12→16→15→14→13→9
        // Inner ring: 6→7→11→10 becomes 10→6→7→11
        // Expected: vec![5, 1, 2, 3, 9, 10, 6, 4, 13, 11, 7, 8, 14, 15, 16, 12]
        let mut data = vec![1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16];
        rotate_right(&mut data).unwrap();
        let expected = vec![5, 1, 2, 3, 9, 10, 6, 4, 13, 11, 7, 8, 14, 15, 16, 12];
        assert_eq!(data, expected);
    }

    #[test]
    fn test_rotate_empty_array() {
        let mut data: Vec<i32> = vec![];
        assert!(matches!(rotate_right(&mut data), Err(RotationError::Empty)));
    }

    #[test]
    fn test_rotate_non_square() {
        let mut data = vec![1, 2, 3]; // Length 3 is not a perfect square
        assert!(matches!(
            rotate_right(&mut data),
            Err(RotationError::NotSquare)
        ));
    }

    #[test]
    fn test_rotate_with_negatives() {
        // Original:         After 1-step clockwise:
        // [-1, -2]      →   [-3, -1]
        // [-3, -4]          [-4, -2]
        //
        // Ring: -1→-2→-4→-3 becomes -3→-1→-2→-4
        // Expected: vec![-3, -1, -4, -2]
        let mut data = vec![-1, -2, -3, -4];
        rotate_right(&mut data).unwrap();
        assert_eq!(data, vec![-3, -1, -4, -2]);
    }

    #[test]
    fn test_rotate_with_zeros() {
        let mut data = vec![0, 0, 0, 0];
        rotate_right(&mut data).unwrap();
        assert_eq!(data, vec![0, 0, 0, 0]);
    }

    #[test]
    fn test_rotate_ring_size_times_identity() {
        // For a 3x3, the outer ring has 8 elements, so rotating 8 times should return to original
        let original = vec![1, 2, 3, 4, 5, 6, 7, 8, 9];
        let mut data = original.clone();

        // Rotate 8 times (size of outer ring) should return to original
        for _ in 0..8 {
            rotate_right(&mut data).unwrap();
        }

        assert_eq!(data, original);
    }

    #[test]
    fn test_rotate_5x5() {
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
        // Expected: vec![6, 1, 2, 3, 4, 11, 12, 7, 8, 5, 16, 17, 13, 9, 10, 21, 18, 19, 14, 15, 22, 23, 24, 25, 20]
        let mut data = (1..=25).collect::<Vec<_>>();
        rotate_right(&mut data).unwrap();
        let expected = vec![
            6, 1, 2, 3, 4, 11, 12, 7, 8, 5, 16, 17, 13, 9, 10, 21, 18, 19, 14, 15, 22, 23, 24, 25,
            20,
        ];
        assert_eq!(data, expected);
    }

    #[test]
    fn test_rotate_10x10() {
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
        // Expected: vec![11,1,2,3,4,5,6,7,8,9, 21,22,12,13,14,15,16,17,18,10, ...]
        let mut data = (1..=100).collect::<Vec<u32>>();
        rotate_right(&mut data).unwrap();
        let expected = vec![
            11,1,2,3,4,5,6,7,8,9,
            21,22,12,13,14,15,16,17,18,10,
            31,32,33,23,24,25,26,27,19,20,
            41,42,43,44,34,35,36,28,29,30,
            51,52,53,54,55,45,37,38,39,40,
            61,62,63,64,56,46,47,48,49,50,
            71,72,73,65,66,67,57,58,59,60,
            81,82,74,75,76,77,78,68,69,70,
            91,83,84,85,86,87,88,89,79,80,
            92,93,94,95,96,97,98,99,100,90,
        ];
        assert_eq!(data, expected);
    }
}

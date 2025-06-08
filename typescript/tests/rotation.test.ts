import {
  squareLen,
  rotateRight,
  NotSquareError,
  EmptyArrayError,
  validateNumberArray,
  isValidNumber,
} from '../src/rotation';

describe('squareLen', () => {
  test('returns correct side length for perfect squares', () => {
    expect(squareLen(0)).toBe(0);
    expect(squareLen(1)).toBe(1);
    expect(squareLen(4)).toBe(2);
    expect(squareLen(9)).toBe(3);
    expect(squareLen(16)).toBe(4);
    expect(squareLen(25)).toBe(5);
    expect(squareLen(100)).toBe(10);
  });

  test('returns null for non-perfect squares', () => {
    expect(squareLen(2)).toBeNull();
    expect(squareLen(3)).toBeNull();
    expect(squareLen(5)).toBeNull();
    expect(squareLen(8)).toBeNull();
    expect(squareLen(10)).toBeNull();
    expect(squareLen(15)).toBeNull();
    expect(squareLen(99)).toBeNull();
  });
});

describe('rotateRight', () => {
  test('handles 1x1 matrix (stays unchanged)', () => {
    // Original: [42]  →  After: [42]
    // Single element matrices don't change
    // Expected: [42]
    const data = [42];
    rotateRight(data);
    expect(data).toEqual([42]);
  });

  test('handles 2x2 matrix rotation', () => {
    // Original:      After 1-step clockwise:
    // [1, 2]     →   [3, 1]
    // [3, 4]         [4, 2]
    //
    // Ring walk: 1→2→4→3 becomes 3→1→2→4
    // Expected: [3, 1, 4, 2]
    const data = [1, 2, 3, 4];
    rotateRight(data);
    expect(data).toEqual([3, 1, 4, 2]);
  });

  test('handles 3x3 matrix rotation', () => {
    // Original:        After 1-step clockwise:
    // [1, 2, 3]    →   [4, 1, 2]
    // [4, 5, 6]        [7, 5, 3]
    // [7, 8, 9]        [8, 9, 6]
    //
    // Outer ring: 1→2→3→6→9→8→7→4 becomes 4→1→2→3→6→9→8→7
    // Center: 5 stays 5 (unchanged)
    // Expected: [4, 1, 2, 7, 5, 3, 8, 9, 6]
    const data = [1, 2, 3, 4, 5, 6, 7, 8, 9];
    rotateRight(data);
    expect(data).toEqual([4, 1, 2, 7, 5, 3, 8, 9, 6]);
  });

  test('handles 4x4 matrix rotation', () => {
    // Original:              After 1-step clockwise:
    // [ 1,  2,  3,  4]   →   [ 5,  1,  2,  3]
    // [ 5,  6,  7,  8]       [ 9, 10,  6,  4]
    // [ 9, 10, 11, 12]       [13, 11,  7,  8]
    // [13, 14, 15, 16]       [14, 15, 16, 12]
    //
    // Outer ring: 1→2→3→4→8→12→16→15→14→13→9→5 becomes 5→1→2→3→4→8→12→16→15→14→13→9
    // Inner ring: 6→7→11→10 becomes 10→6→7→11
    // Expected: [5, 1, 2, 3, 9, 10, 6, 4, 13, 11, 7, 8, 14, 15, 16, 12]
    const data = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16];
    rotateRight(data);
    const expected = [5, 1, 2, 3, 9, 10, 6, 4, 13, 11, 7, 8, 14, 15, 16, 12];
    expect(data).toEqual(expected);
  });

  test('handles 5x5 matrix rotation', () => {
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
    const data = Array.from({ length: 25 }, (_, i) => i + 1);
    rotateRight(data);
    const expected = [
      6, 1, 2, 3, 4, 11, 12, 7, 8, 5, 16, 17, 13, 9, 10, 21, 18, 19, 14, 15, 22, 23, 24, 25, 20,
    ];
    expect(data).toEqual(expected);
  });

  test('handles negative numbers', () => {
    // Original:         After 1-step clockwise:
    // [-1, -2]      →   [-3, -1]
    // [-3, -4]          [-4, -2]
    //
    // Ring: -1→-2→-4→-3 becomes -3→-1→-2→-4
    // Expected: [-3, -1, -4, -2]
    const data = [-1, -2, -3, -4];
    rotateRight(data);
    expect(data).toEqual([-3, -1, -4, -2]);
  });

  test('handles zeros', () => {
    const data = [0, 0, 0, 0];
    rotateRight(data);
    expect(data).toEqual([0, 0, 0, 0]);
  });

  test('throws EmptyArrayError for empty array', () => {
    const data: number[] = [];
    expect(() => rotateRight(data)).toThrow(EmptyArrayError);
  });

  test('throws NotSquareError for non-square arrays', () => {
    const data1 = [1, 2, 3]; // Length 3 is not a perfect square
    expect(() => rotateRight(data1)).toThrow(NotSquareError);

    const data2 = [1, 2, 3, 4, 5]; // Length 5 is not a perfect square
    expect(() => rotateRight(data2)).toThrow(NotSquareError);

    const data3 = [1, 2, 3, 4, 5, 6, 7, 8]; // Length 8 is not a perfect square
    expect(() => rotateRight(data3)).toThrow(NotSquareError);
  });

  test('multiple rotations return to original (ring size identity)', () => {
    // For a 3x3, the outer ring has 8 elements, so rotating 8 times should return to original
    const original = [1, 2, 3, 4, 5, 6, 7, 8, 9];
    const data = [...original];

    // Rotate 8 times (size of outer ring) should return to original
    for (let i = 0; i < 8; i++) {
      rotateRight(data);
    }

    expect(data).toEqual(original);
  });

  test('handles large matrices', () => {
    // Test 10x10 matrix to ensure algorithm scales
    const data = Array.from({ length: 100 }, (_, i) => i + 1);
    const originalData = [...data];

    // Should not throw and should modify the data
    expect(() => rotateRight(data)).not.toThrow();
    expect(data).not.toEqual(originalData);

    // Spot check a few positions
    expect(data[0]).toBe(11); // Top-left should get value from left side (was 91)
    expect(data[9]).toBe(9); // Top-right should get value from previous position (was 9)
  });
});

describe('isValidNumber', () => {
  test('returns true for valid numbers', () => {
    expect(isValidNumber(0)).toBe(true);
    expect(isValidNumber(42)).toBe(true);
    expect(isValidNumber(-5)).toBe(true);
    expect(isValidNumber(3.14)).toBe(true);
    expect(isValidNumber(-0)).toBe(true);
  });

  test('returns false for invalid values', () => {
    expect(isValidNumber(NaN)).toBe(false);
    expect(isValidNumber(Infinity)).toBe(false);
    expect(isValidNumber(-Infinity)).toBe(false);
    expect(isValidNumber('42')).toBe(false);
    expect(isValidNumber(null)).toBe(false);
    expect(isValidNumber(undefined)).toBe(false);
    expect(isValidNumber({})).toBe(false);
    expect(isValidNumber([])).toBe(false);
    expect(isValidNumber(true)).toBe(false);
  });
});

describe('validateNumberArray', () => {
  test('returns number array for valid input', () => {
    expect(validateNumberArray([1, 2, 3, 4])).toEqual([1, 2, 3, 4]);
    expect(validateNumberArray([-1, 0, 1])).toEqual([-1, 0, 1]);
    expect(validateNumberArray([])).toEqual([]);
    expect(validateNumberArray([42])).toEqual([42]);
  });

  test('returns null for non-arrays', () => {
    expect(validateNumberArray(42)).toBeNull();
    expect(validateNumberArray('hello')).toBeNull();
    expect(validateNumberArray(null)).toBeNull();
    expect(validateNumberArray(undefined)).toBeNull();
    expect(validateNumberArray({})).toBeNull();
  });

  test('returns null for arrays with non-numbers', () => {
    expect(validateNumberArray([1, 'hello', 3])).toBeNull();
    expect(validateNumberArray([1, null, 3])).toBeNull();
    expect(validateNumberArray([1, undefined, 3])).toBeNull();
    expect(validateNumberArray([1, {}, 3])).toBeNull();
    expect(validateNumberArray([1, [], 3])).toBeNull();
    expect(validateNumberArray([1, true, 3])).toBeNull();
    expect(validateNumberArray([1, NaN, 3])).toBeNull();
    expect(validateNumberArray([1, Infinity, 3])).toBeNull();
  });
});

describe('algorithm consistency', () => {
  test('produces same results as Rust implementation for key test cases', () => {
    // Test case 1: 2x2 matrix
    const data1 = [1, 2, 3, 4];
    rotateRight(data1);
    expect(data1).toEqual([3, 1, 4, 2]);

    // Test case 2: 3x3 matrix (matches recruitment spec)
    const data2 = [1, 2, 3, 4, 5, 6, 7, 8, 9];
    rotateRight(data2);
    expect(data2).toEqual([4, 1, 2, 7, 5, 3, 8, 9, 6]);

    // Test case 3: Negative numbers
    const data3 = [-1, -2, -3, -4];
    rotateRight(data3);
    expect(data3).toEqual([-3, -1, -4, -2]);
  });

  test('rotation is deterministic and repeatable', () => {
    const original = [1, 2, 3, 4, 5, 6, 7, 8, 9];

    const data1 = [...original];
    const data2 = [...original];

    rotateRight(data1);
    rotateRight(data2);

    expect(data1).toEqual(data2);
    expect(data1).toEqual([4, 1, 2, 7, 5, 3, 8, 9, 6]);
  });
});

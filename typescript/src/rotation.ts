/**
 * Core table rotation algorithms for square matrices.
 *
 * This module provides functions to validate and rotate square numerical tables
 * represented as flat arrays. Tables are rotated by shifting each element one
 * position clockwise around its concentric ring.
 */

/**
 * Custom error types for rotation operations.
 */
export class RotationError extends Error {
  constructor(message: string) {
    super(message);
    this.name = 'RotationError';
  }
}

export class NotSquareError extends RotationError {
  constructor() {
    super('Array length is not a perfect square');
    this.name = 'NotSquareError';
  }
}

export class EmptyArrayError extends RotationError {
  constructor() {
    super('Array is empty');
    this.name = 'EmptyArrayError';
  }
}

/**
 * Returns the side length if `length` is a perfect square, else null.
 *
 * @param length - The array length to check
 * @returns The side length n where n² = length, or null if not a perfect square
 *
 * @example
 * ```typescript
 * console.log(squareLen(4));  // 2
 * console.log(squareLen(9));  // 3
 * console.log(squareLen(5));  // null
 * ```
 */
export function squareLen(length: number): number | null {
  if (length === 0) {
    return 0;
  }

  const n = Math.sqrt(length);
  return Number.isInteger(n) ? n : null;
}

/**
 * Rotates an N×N matrix by shifting each element one position clockwise around its ring.
 *
 * This uses the canonical "layer walk" algorithm that processes each concentric ring
 * from outside to inside. Each ring is rotated by walking clockwise:
 * top row → right column → bottom row → left column
 *
 * The input array represents a square table read row-by-row:
 * - `[1, 2, 3, 4]` represents a 2×2 table: `[[1, 2], [3, 4]]`
 * - After one-step clockwise shift: `[[3, 1], [4, 2]]` → `[3, 1, 4, 2]`
 *
 * **Complexity:**
 * - Time: O(N²) - touches each element exactly once
 * - Space: O(1) - uses only two temporary variables
 *
 * @param data - Mutable array containing the table elements
 * @throws {EmptyArrayError} If the array is empty
 * @throws {NotSquareError} If the array length is not a perfect square
 *
 * @example
 * ```typescript
 * const data = [1, 2, 3, 4];
 * rotateRight(data);
 * console.log(data); // [3, 1, 4, 2]
 * ```
 *
 * @example
 * ```typescript
 * const data = [1, 2, 3, 4, 5, 6, 7, 8, 9];
 * rotateRight(data);
 * console.log(data); // [4, 1, 2, 7, 5, 3, 8, 9, 6]
 * ```
 */
export function rotateRight(data: number[]): void {
  const length = data.length;

  if (length === 0) {
    throw new EmptyArrayError();
  }

  const n = squareLen(length);
  if (n === null) {
    throw new NotSquareError();
  }

  // Handle trivial cases
  if (n <= 1) {
    return;
  }

  // Process each concentric ring from outside to inside
  for (let layer = 0; layer < Math.floor(n / 2); layer++) {
    rotateRingClockwise(data, n, layer);
  }
}

/**
 * Rotates a single ring of the matrix one position clockwise using in-place swaps.
 *
 * This is the core of the canonical layer-walk algorithm. It walks around the ring
 * in clockwise order, swapping elements with a temporary variable.
 *
 * @param data - The flat array representing the matrix
 * @param n - The side length of the square matrix
 * @param layer - The ring index (0 = outermost, n/2-1 = innermost)
 */
function rotateRingClockwise(data: number[], n: number, layer: number): void {
  const first = layer;
  const last = n - 1 - layer;

  // Save the element that will be overwritten first (element below top-left)
  let prev = data[idx(n, first + 1, first)]!;

  // Top row: left → right
  for (let col = first; col <= last; col++) {
    const temp = data[idx(n, first, col)]!;
    data[idx(n, first, col)] = prev;
    prev = temp;
  }

  // Right column: top+1 → bottom
  for (let row = first + 1; row <= last; row++) {
    const temp = data[idx(n, row, last)]!;
    data[idx(n, row, last)] = prev;
    prev = temp;
  }

  // Bottom row: right-1 → left
  for (let col = last - 1; col >= first; col--) {
    const temp = data[idx(n, last, col)]!;
    data[idx(n, last, col)] = prev;
    prev = temp;
  }

  // Left column: bottom-1 → top+1
  for (let row = last - 1; row > first; row--) {
    const temp = data[idx(n, row, first)]!;
    data[idx(n, row, first)] = prev;
    prev = temp;
  }
}

/**
 * Converts 2D table coordinates (row, col) to 1D array index.
 *
 * For an N×N table stored row-by-row in a flat array:
 * `index = row * n + col`
 *
 * @param n - The side length of the square matrix
 * @param row - The row coordinate (0-based)
 * @param col - The column coordinate (0-based)
 * @returns The flat array index
 */
function idx(n: number, row: number, col: number): number {
  return row * n + col;
}

/**
 * Type guard to check if a value is a valid number for rotation.
 *
 * @param value - The value to check
 * @returns True if the value is a finite number
 */
export function isValidNumber(value: unknown): value is number {
  return typeof value === 'number' && Number.isFinite(value);
}

/**
 * Validates and converts a JSON array to a number array for rotation.
 *
 * @param jsonValue - The parsed JSON value
 * @returns Array of numbers if valid, null otherwise
 */
export function validateNumberArray(jsonValue: unknown): number[] | null {
  if (!Array.isArray(jsonValue)) {
    return null;
  }

  const numbers: number[] = [];
  for (const item of jsonValue) {
    if (!isValidNumber(item)) {
      return null;
    }
    numbers.push(item);
  }

  return numbers;
}

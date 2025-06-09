"""
Core table rotation algorithms for square matrices.

This module provides functions to validate and rotate square numerical tables
represented as flat arrays. Tables are rotated by shifting each element one
position clockwise around its concentric ring.
"""

import math
from typing import List, Optional, Union


class RotationError(Exception):
    """Base class for rotation operation errors."""
    pass


class NotSquareError(RotationError):
    """Raised when array length is not a perfect square."""
    def __init__(self) -> None:
        super().__init__("Array length is not a perfect square")


class EmptyArrayError(RotationError):
    """Raised when array is empty."""
    def __init__(self) -> None:
        super().__init__("Array is empty")


def square_len(length: int) -> Optional[int]:
    """
    Returns the side length if `length` is a perfect square, else None.
    
    Args:
        length: The array length to check
        
    Returns:
        The side length n where n² = length, or None if not a perfect square
        
    Examples:
        >>> square_len(4)
        2
        >>> square_len(9)
        3
        >>> square_len(5)
        None
    """
    if length == 0:
        return 0
    
    n = int(math.sqrt(length))
    return n if n * n == length else None


def rotate_right(data: List[Union[int, float]]) -> None:
    """
    Rotates an N×N matrix by shifting each element one position clockwise around its ring.
    
    This uses the canonical "layer walk" algorithm that processes each concentric ring
    from outside to inside. Each ring is rotated by walking clockwise:
    top row → right column → bottom row → left column
    
    The input array represents a square table read row-by-row:
    - `[1, 2, 3, 4]` represents a 2×2 table: `[[1, 2], [3, 4]]`
    - After one-step clockwise shift: `[[3, 1], [4, 2]]` → `[3, 1, 4, 2]`
    
    Complexity:
    - Time: O(N²) - touches each element exactly once
    - Space: O(1) - uses only two temporary variables
    
    Args:
        data: Mutable list containing the table elements
        
    Raises:
        EmptyArrayError: If the array is empty
        NotSquareError: If the array length is not a perfect square
        
    Examples:
        >>> data = [1, 2, 3, 4]
        >>> rotate_right(data)
        >>> data
        [3, 1, 4, 2]
        
        >>> data = [1, 2, 3, 4, 5, 6, 7, 8, 9]
        >>> rotate_right(data)
        >>> data  
        [4, 1, 2, 7, 5, 3, 8, 9, 6]
    """
    length = len(data)
    
    if length == 0:
        raise EmptyArrayError()
        
    n = square_len(length)
    if n is None:
        raise NotSquareError()
        
    # Handle trivial cases
    if n <= 1:
        return
        
    # Process each concentric ring from outside to inside
    for layer in range(n // 2):
        _rotate_ring_clockwise(data, n, layer)


def _rotate_ring_clockwise(data: List[Union[int, float]], n: int, layer: int) -> None:
    """
    Rotates a single ring of the matrix one position clockwise using in-place swaps.
    
    This is the core of the canonical layer-walk algorithm. It walks around the ring
    in clockwise order, swapping elements with a temporary variable.
    
    Args:
        data: The flat list representing the matrix
        n: The side length of the square matrix  
        layer: The ring index (0 = outermost, n//2-1 = innermost)
    """
    first = layer
    last = n - 1 - layer
    
    # Save the element that will be overwritten first (element below top-left)
    prev = data[_idx(n, first + 1, first)]
    
    # Top row: left → right
    for col in range(first, last + 1):
        temp = data[_idx(n, first, col)]
        data[_idx(n, first, col)] = prev
        prev = temp
        
    # Right column: top+1 → bottom
    for row in range(first + 1, last + 1):
        temp = data[_idx(n, row, last)]
        data[_idx(n, row, last)] = prev
        prev = temp
        
    # Bottom row: right-1 → left
    for col in range(last - 1, first - 1, -1):
        temp = data[_idx(n, last, col)]
        data[_idx(n, last, col)] = prev
        prev = temp
        
    # Left column: bottom-1 → top+1
    for row in range(last - 1, first, -1):
        temp = data[_idx(n, row, first)]
        data[_idx(n, row, first)] = prev
        prev = temp


def _idx(n: int, row: int, col: int) -> int:
    """
    Converts 2D table coordinates (row, col) to 1D array index.
    
    For an N×N table stored row-by-row in a flat array:
    `index = row * n + col`
    
    Args:
        n: The side length of the square matrix
        row: The row coordinate (0-based)
        col: The column coordinate (0-based)
        
    Returns:
        The flat array index
    """
    return row * n + col


def is_valid_number(value: object) -> bool:
    """
    Type guard to check if a value is a valid number for rotation.
    
    Args:
        value: The value to check
        
    Returns:
        True if the value is a finite number (but not boolean)
    """
    # Exclude booleans even though they're technically numbers in Python
    if isinstance(value, bool):
        return False
    return isinstance(value, (int, float)) and math.isfinite(value)


def validate_number_array(json_value: object) -> Optional[List[Union[int, float]]]:
    """
    Validates and converts a JSON array to a number array for rotation.
    
    Args:
        json_value: The parsed JSON value
        
    Returns:
        List of numbers if valid, None otherwise
    """
    if not isinstance(json_value, list):
        return None
        
    numbers: List[Union[int, float]] = []
    for item in json_value:
        if not is_valid_number(item):
            return None
        numbers.append(item)
        
    return numbers 
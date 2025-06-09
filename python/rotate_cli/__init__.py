"""
CSV table rotation CLI - Python implementation.

A high-performance CSV table rotation tool that rotates square numerical tables
by shifting each element one position clockwise around its concentric ring.
"""

from .rotation import rotate_right, square_len, RotationError, NotSquareError, EmptyArrayError

__version__ = "1.0.0"
__all__ = [
    "rotate_right",
    "square_len", 
    "RotationError",
    "NotSquareError",
    "EmptyArrayError",
] 
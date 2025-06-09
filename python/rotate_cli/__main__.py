"""
Main CLI entry point for the table rotation tool.

Processes CSV files with id,json columns where json contains stringified arrays
of numbers representing square tables. Rotates each valid table one position
clockwise and outputs the results.
"""

import csv
import json
import sys
from typing import Any, Dict, TextIO

from .rotation import rotate_right, validate_number_array, RotationError


def process_csv_row(row: Dict[str, str]) -> Dict[str, Any]:
    """
    Process a single CSV row with id and json columns.
    
    Args:
        row: Dictionary with 'id' and 'json' keys
        
    Returns:
        Dictionary with 'id', 'json', and 'is_valid' keys
    """
    row_id = row['id']
    json_str = row['json']
    
    try:
        # Parse the JSON array
        json_data = json.loads(json_str)
        
        # Validate it's a valid number array
        numbers = validate_number_array(json_data)
        if numbers is None:
            return {
                'id': row_id,
                'json': '[]',
                'is_valid': 'false'  # Lowercase to match Rust/TypeScript
            }
        
        # Try to rotate the array
        rotate_right(numbers)
        
        # Success - return the rotated result
        return {
            'id': row_id,
            'json': json.dumps(numbers, separators=(',', ':')),  # No spaces after commas
            'is_valid': 'true'  # Lowercase to match Rust/TypeScript
        }
        
    except (json.JSONDecodeError, RotationError):
        # Invalid JSON or rotation failed
        return {
            'id': row_id,
            'json': '[]',
            'is_valid': 'false'  # Lowercase to match Rust/TypeScript
        }


def process_csv_stream(input_stream: TextIO, output_stream: TextIO) -> None:
    """
    Process CSV data from input stream and write results to output stream.
    
    Args:
        input_stream: Input CSV stream with id,json columns
        output_stream: Output CSV stream for id,json,is_valid columns
    """
    reader = csv.DictReader(input_stream)
    
    # Validate input format
    if (reader.fieldnames is None or 'id' not in reader.fieldnames 
            or 'json' not in reader.fieldnames):
        print("Error: Input CSV must have 'id' and 'json' columns", file=sys.stderr)
        sys.exit(1)
    
    # Write output header
    fieldnames = ['id', 'json', 'is_valid']
    writer = csv.DictWriter(output_stream, fieldnames=fieldnames, lineterminator='\n')
    writer.writeheader()
    
    # Process each row
    for row in reader:
        result = process_csv_row(row)
        writer.writerow(result)


def main() -> None:
    """
    Main CLI entry point.
    
    Usage:
        python -m rotate_cli [input_file]
        
    If no input file is provided, reads from stdin.
    Output is always written to stdout.
    """
    try:
        if len(sys.argv) > 1:
            # Read from file
            input_file = sys.argv[1]
            with open(input_file, 'r', encoding='utf-8') as f:
                process_csv_stream(f, sys.stdout)
        else:
            # Read from stdin
            process_csv_stream(sys.stdin, sys.stdout)
            
    except FileNotFoundError:
        print(f"Error: File '{sys.argv[1]}' not found", file=sys.stderr)
        sys.exit(1)
    except KeyboardInterrupt:
        print("\nOperation cancelled", file=sys.stderr)
        sys.exit(1)
    except Exception as e:
        print(f"Error: {e}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main() 
"""
CLI integration tests.

Tests the command-line interface and CSV processing functionality.
"""

import csv
import io
from rotate_cli.__main__ import process_csv_row, process_csv_stream


class TestProcessCSVRow:
    """Test CSV row processing."""
    
    def test_processes_valid_2x2_matrix(self):
        row = {'id': '1', 'json': '[1, 2, 3, 4]'}
        result = process_csv_row(row)
        
        assert result['id'] == '1'
        assert result['json'] == '[3, 1, 4, 2]'
        assert result['is_valid'] is True

    def test_processes_valid_3x3_matrix(self):
        row = {'id': '2', 'json': '[1, 2, 3, 4, 5, 6, 7, 8, 9]'}
        result = process_csv_row(row)
        
        assert result['id'] == '2'
        assert result['json'] == '[4, 1, 2, 7, 5, 3, 8, 9, 6]'
        assert result['is_valid'] is True

    def test_processes_valid_1x1_matrix(self):
        row = {'id': '3', 'json': '[-5]'}
        result = process_csv_row(row)
        
        assert result['id'] == '3'
        assert result['json'] == '[-5]'
        assert result['is_valid'] is True

    def test_handles_invalid_non_square_array(self):
        row = {'id': '4', 'json': '[2, -5, -5]'}
        result = process_csv_row(row)
        
        assert result['id'] == '4'
        assert result['json'] == '[]'
        assert result['is_valid'] is False

    def test_handles_invalid_json(self):
        row = {'id': '5', 'json': 'not valid json'}
        result = process_csv_row(row)
        
        assert result['id'] == '5'
        assert result['json'] == '[]'
        assert result['is_valid'] is False

    def test_handles_non_number_array(self):
        row = {'id': '6', 'json': '["hello", "world"]'}
        result = process_csv_row(row)
        
        assert result['id'] == '6'
        assert result['json'] == '[]'
        assert result['is_valid'] is False

    def test_handles_empty_array(self):
        row = {'id': '7', 'json': '[]'}
        result = process_csv_row(row)
        
        assert result['id'] == '7'
        assert result['json'] == '[]'
        assert result['is_valid'] is False


class TestProcessCSVStream:
    """Test CSV stream processing."""
    
    def test_processes_complete_csv_example(self):
        # Input matching the recruitment test example
        input_csv = '''id,json
1,"[1, 2, 3, 4, 5, 6, 7, 8, 9]"
2,"[40, 20, 90, 10]"
3,"[-5]"
4,"[2, -5, -5]"'''

        # Expected output matching the recruitment test
        expected_output = '''id,json,is_valid
1,"[4, 1, 2, 7, 5, 3, 8, 9, 6]",True
2,"[90, 40, 10, 20]",True
3,[-5],True
4,[],False
'''

        input_stream = io.StringIO(input_csv)
        output_stream = io.StringIO()
        
        process_csv_stream(input_stream, output_stream)
        
        actual_output = output_stream.getvalue()
        assert actual_output == expected_output

    def test_handles_mixed_valid_invalid_data(self):
        input_csv = '''id,json
1,"[1, 2, 3, 4]"
2,"[1, 2, 3]"
3,"invalid json"
4,"[5]"'''

        input_stream = io.StringIO(input_csv)
        output_stream = io.StringIO()
        
        process_csv_stream(input_stream, output_stream)
        
        output_lines = output_stream.getvalue().strip().split('\n')
        
        # Check header
        assert output_lines[0] == 'id,json,is_valid'
        
        # Parse results
        reader = csv.DictReader(io.StringIO(output_stream.getvalue()))
        results = list(reader)
        
        assert len(results) == 4
        
        # Valid 2x2 matrix
        assert results[0]['id'] == '1'
        assert results[0]['json'] == '[3, 1, 4, 2]'
        assert results[0]['is_valid'] == 'True'
        
        # Invalid - not square
        assert results[1]['id'] == '2'
        assert results[1]['json'] == '[]'
        assert results[1]['is_valid'] == 'False'
        
        # Invalid - bad JSON
        assert results[2]['id'] == '3'
        assert results[2]['json'] == '[]'
        assert results[2]['is_valid'] == 'False'
        
        # Valid 1x1 matrix
        assert results[3]['id'] == '4'
        assert results[3]['json'] == '[5]'
        assert results[3]['is_valid'] == 'True'

    def test_handles_empty_csv(self):
        input_csv = 'id,json\n'
        
        input_stream = io.StringIO(input_csv)
        output_stream = io.StringIO()
        
        process_csv_stream(input_stream, output_stream)
        
        assert output_stream.getvalue() == 'id,json,is_valid\n'


class TestAlgorithmConsistencyWithOtherImplementations:
    """Test that Python produces same results as Rust/TypeScript implementations."""
    
    def test_recruitment_test_case_exact_match(self):
        """Verify exact match with the recruitment test specification."""
        # Test the exact case from the problem specification
        row = {'id': '1', 'json': '[1, 2, 3, 4, 5, 6, 7, 8, 9]'}
        result = process_csv_row(row)
        
        # This should match Rust and TypeScript exactly
        assert result['json'] == '[4, 1, 2, 7, 5, 3, 8, 9, 6]'
        assert result['is_valid'] is True

    def test_2x2_case_exact_match(self):
        """Verify 2x2 rotation matches other implementations."""
        row = {'id': '2', 'json': '[40, 20, 90, 10]'}
        result = process_csv_row(row)
        
        # This should match Rust and TypeScript exactly
        assert result['json'] == '[90, 40, 10, 20]'
        assert result['is_valid'] is True

    def test_negative_numbers_exact_match(self):
        """Verify negative number handling matches other implementations."""
        row = {'id': '3', 'json': '[-1, -2, -3, -4]'}
        result = process_csv_row(row)
        
        # This should match Rust and TypeScript exactly
        assert result['json'] == '[-3, -1, -4, -2]'
        assert result['is_valid'] is True 
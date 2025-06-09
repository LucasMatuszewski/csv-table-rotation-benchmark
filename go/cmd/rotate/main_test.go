package main

import (
	"encoding/csv"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
	"testing"
)

func TestProcessJSONArray(t *testing.T) {
	tests := []struct {
		name     string
		input    string
		expected string
		valid    bool
	}{
		{
			name:     "1x1 matrix",
			input:    "[42]",
			expected: "[42]",
			valid:    true,
		},
		{
			name:     "2x2 matrix",
			input:    "[1, 2, 3, 4]",
			expected: "[3,1,4,2]",
			valid:    true,
		},
		{
			name:     "3x3 matrix",
			input:    "[1, 2, 3, 4, 5, 6, 7, 8, 9]",
			expected: "[4,1,2,7,5,3,8,9,6]",
			valid:    true,
		},
		{
			name:     "empty array",
			input:    "[]",
			expected: "[]",
			valid:    false,
		},
		{
			name:     "non-square array",
			input:    "[1, 2, 3]",
			expected: "[]",
			valid:    false,
		},
		{
			name:     "invalid JSON",
			input:    "[1, 2, invalid]",
			expected: "[]",
			valid:    false,
		},
		{
			name:     "negative numbers",
			input:    "[-1, -2, -3, -4]",
			expected: "[-3,-1,-4,-2]",
			valid:    true,
		},
	}

	for _, test := range tests {
		t.Run(test.name, func(t *testing.T) {
			result, valid := processJSONArray(test.input)
			if valid != test.valid {
				t.Errorf("Expected valid=%v, got valid=%v", test.valid, valid)
			}
			if result != test.expected {
				t.Errorf("Expected result=%q, got result=%q", test.expected, result)
			}
		})
	}
}

func TestCLIIntegration(t *testing.T) {
	// Build the CLI binary for testing
	binaryPath := filepath.Join(t.TempDir(), "rotate")
	cmd := exec.Command("go", "build", "-o", binaryPath, ".")
	if err := cmd.Run(); err != nil {
		t.Fatalf("Failed to build CLI: %v", err)
	}

	// Create a temporary input CSV file
	tempDir := t.TempDir()
	inputFile := filepath.Join(tempDir, "input.csv")

	// Write test data
	file, err := os.Create(inputFile)
	if err != nil {
		t.Fatalf("Failed to create input file: %v", err)
	}

	writer := csv.NewWriter(file)
	testData := [][]string{
		{"id", "json"},
		{"1", "[1]"},
		{"2", "[1, 2, 3, 4]"},
		{"3", "[1, 2, 3, 4, 5, 6, 7, 8, 9]"},
		{"4", "[]"},
		{"5", "[1, 2, 3]"},
	}

	for _, row := range testData {
		if err := writer.Write(row); err != nil {
			t.Fatalf("Failed to write test data: %v", err)
		}
	}
	writer.Flush()
	file.Close()

	// Run the CLI
	cmd = exec.Command(binaryPath, inputFile)
	output, err := cmd.Output()
	if err != nil {
		t.Fatalf("CLI execution failed: %v", err)
	}

	// Parse and verify output
	lines := strings.Split(strings.TrimSpace(string(output)), "\n")
	if len(lines) != 6 { // header + 5 data rows
		t.Fatalf("Expected 6 lines, got %d", len(lines))
	}

	// Check header
	if lines[0] != "id,json,is_valid" {
		t.Errorf("Wrong header: %s", lines[0])
	}

	expectedOutputs := []string{
		"1,[1],true",
		"2,\"[3,1,4,2]\",true",
		"3,\"[4,1,2,7,5,3,8,9,6]\",true",
		"4,[],false",
		"5,[],false",
	}

	for i, expected := range expectedOutputs {
		if lines[i+1] != expected {
			t.Errorf("Line %d: expected %q, got %q", i+1, expected, lines[i+1])
		}
	}
}

func TestCLIErrorHandling(t *testing.T) {
	// Build the CLI binary for testing
	binaryPath := filepath.Join(t.TempDir(), "rotate")
	cmd := exec.Command("go", "build", "-o", binaryPath, ".")
	if err := cmd.Run(); err != nil {
		t.Fatalf("Failed to build CLI: %v", err)
	}

	// Test with non-existent file
	cmd = exec.Command(binaryPath, "non-existent-file.csv")
	output, err := cmd.CombinedOutput()
	if err == nil {
		t.Error("Expected error for non-existent file")
	}
	if !strings.Contains(string(output), "Error opening file") {
		t.Errorf("Expected 'Error opening file' in output, got: %s", output)
	}

	// Test with no arguments
	cmd = exec.Command(binaryPath)
	output, err = cmd.CombinedOutput()
	if err == nil {
		t.Error("Expected error for no arguments")
	}
	if !strings.Contains(string(output), "Usage:") {
		t.Errorf("Expected usage message, got: %s", output)
	}
}

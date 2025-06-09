// rotate - CSV table rotation CLI tool
//
// This tool processes CSV files containing square numerical tables and rotates them
// by shifting each element one position clockwise around its ring.
package main

import (
	"encoding/csv"
	"encoding/json"
	"flag"
	"fmt"
	"io"
	"log"
	"os"
	"strconv"

	"github.com/LucasMatuszewski/csv-table-rotation-benchmark/go/internal/rotate"
)

func main() {
	log.SetFlags(0) // Remove timestamp from log output

	// Parse command line arguments
	flag.Usage = func() {
		fmt.Fprintf(flag.CommandLine.Output(), "Usage: %s <input.csv>\n\n", os.Args[0])
		fmt.Fprintf(flag.CommandLine.Output(), "Process CSV files containing square numerical tables and rotate them clockwise.\n\n")
		fmt.Fprintf(flag.CommandLine.Output(), "Input format: CSV with columns 'id' and 'json'\n")
		fmt.Fprintf(flag.CommandLine.Output(), "Output format: CSV with columns 'id', 'json', and 'is_valid'\n\n")
	}
	flag.Parse()

	if flag.NArg() != 1 {
		flag.Usage()
		os.Exit(1)
	}

	infile := flag.Arg(0)

	// Open input file
	f, err := os.Open(infile)
	if err != nil {
		log.Fatalf("Error opening file: %v", err)
	}
	defer f.Close()

	// Set up CSV reader and writer
	reader := csv.NewReader(f)
	reader.ReuseRecord = true // Zero allocation per row for better performance
	writer := csv.NewWriter(os.Stdout)
	defer writer.Flush()

	// Read and validate header
	header, err := reader.Read()
	if err != nil {
		log.Fatalf("Error reading header: %v", err)
	}
	if len(header) < 2 || header[0] != "id" || header[1] != "json" {
		log.Fatalf("Invalid header format. Expected: id,json")
	}

	// Write output header
	if err := writer.Write([]string{"id", "json", "is_valid"}); err != nil {
		log.Fatalf("Error writing header: %v", err)
	}

	// Process each row
	for {
		record, err := reader.Read()
		if err == io.EOF {
			break
		}
		if err != nil {
			log.Fatalf("Error reading CSV: %v", err)
		}

		if len(record) < 2 {
			log.Fatalf("Invalid record format. Expected at least 2 columns")
		}

		id := record[0]
		jsonStr := record[1]

		// Process the JSON array
		rotatedJSON, isValid := processJSONArray(jsonStr)

		// Write result
		if err := writer.Write([]string{id, rotatedJSON, strconv.FormatBool(isValid)}); err != nil {
			log.Fatalf("Error writing output: %v", err)
		}
	}

	// Ensure all data is written
	if err := writer.Error(); err != nil {
		log.Fatalf("Error flushing output: %v", err)
	}
}

// processJSONArray parses a JSON array, validates it as a square table, rotates it, and returns the result
func processJSONArray(jsonStr string) (string, bool) {
	// Parse JSON array
	var numbers []float64
	if err := json.Unmarshal([]byte(jsonStr), &numbers); err != nil {
		return "[]", false
	}

	// Check if array is empty
	if len(numbers) == 0 {
		return "[]", false
	}

	// Validate that it's a perfect square
	_, err := rotate.SquareLen(len(numbers))
	if err != nil {
		return "[]", false
	}

	// Rotate the array
	if err := rotate.RotateRight(numbers); err != nil {
		return "[]", false
	}

	// Convert back to JSON
	rotatedJSON, err := json.Marshal(numbers)
	if err != nil {
		return "[]", false
	}

	return string(rotatedJSON), true
}

#!/usr/bin/env node

/**
 * CLI implementation for CSV table rotation.
 *
 * Processes CSV files containing square numerical tables and rotates them by
 * shifting each element one position clockwise around its ring.
 */

import { createReadStream } from 'fs';
import * as fastCsv from 'fast-csv';
import { rotateRight, squareLen, validateNumberArray } from './rotation.js';

/**
 * CLI configuration and argument parsing.
 */
interface CliArgs {
  inputFile: string;
  help: boolean;
}

/**
 * Represents a row in the output CSV.
 */
interface OutputRow {
  id: string;
  json: string;
  is_valid: string;
}

/**
 * Parse command line arguments.
 */
function parseArgs(): CliArgs {
  const args = process.argv.slice(2);

  if (args.length === 0 || args.includes('--help') || args.includes('-h')) {
    return { inputFile: '', help: true };
  }

  if (args.length !== 1) {
    console.error('Error: Expected exactly one argument (input file path)');
    process.exit(1);
  }

  return {
    inputFile: args[0]!,
    help: false,
  };
}

/**
 * Display help message.
 */
function showHelp(): void {
  console.log(`
Table Rotation CLI - TypeScript Implementation

USAGE:
    node cli.js <input.csv>

DESCRIPTION:
    Rotate square tables inside a CSV file by one step clockwise.

    Input CSV must have columns 'id' and 'json'.
    Output CSV will have columns 'id', 'json', and 'is_valid'.

EXAMPLES:
    node cli.js input-samples/sample-1k.csv > output.csv
    node cli.js data.csv

OPTIONS:
    -h, --help    Show this help message
`);
}

/**
 * Process a JSON string containing an array of numbers.
 * Returns the processed result and validity status.
 */
function processJsonArray(jsonText: string): { json: string; isValid: boolean } {
  try {
    // Parse JSON
    const parsedValue = JSON.parse(jsonText);

    // Validate that it's an array of numbers
    const numbers = validateNumberArray(parsedValue);
    if (numbers === null) {
      return { json: '[]', isValid: false };
    }

    // Check if it can form a square table
    if (squareLen(numbers.length) === null) {
      return { json: '[]', isValid: false };
    }

    // If empty array, treat as invalid per spec
    if (numbers.length === 0) {
      return { json: '[]', isValid: false };
    }

    // Rotate the table in-place
    rotateRight(numbers);

    // Convert back to JSON
    const result = JSON.stringify(numbers);
    return { json: result, isValid: true };
  } catch (error) {
    // JSON parsing error or rotation error
    return { json: '[]', isValid: false };
  }
}

/**
 * Main CLI function.
 */
async function main(): Promise<void> {
  const args = parseArgs();

  if (args.help) {
    showHelp();
    return;
  }

  try {
    await processFile(args.inputFile);
  } catch (error) {
    if (error instanceof Error) {
      console.error(`Error: ${error.message}`);
    } else {
      console.error('An unknown error occurred');
    }
    process.exit(1);
  }
}

/**
 * Process the input CSV file and stream results to stdout.
 */
async function processFile(inputFile: string): Promise<void> {
  // Create output stream with fast-csv
  const outputStream = fastCsv.format({
    headers: ['id', 'json', 'is_valid'],
    writeHeaders: true,
    delimiter: ',',
    quote: '"',
    escape: '"',
  });

  // Pipe output to stdout
  outputStream.pipe(process.stdout);

  // Create input stream with fast-csv for parsing
  const inputStream = createReadStream(inputFile).pipe(
    fastCsv.parse({
      headers: true,
      delimiter: ',',
      quote: '"',
      escape: '"',
    })
  );

  // Process each row
  inputStream.on('data', (row: Record<string, string>) => {
    try {
      // Ensure we have both required fields
      if (!row['id'] || row['json'] === undefined) {
        console.error('Warning: Skipping row with missing fields');
        return;
      }

      // Process the JSON and determine validity
      const { json, isValid } = processJsonArray(row['json']);

      // Write output row
      const outputRow: OutputRow = {
        id: row['id'],
        json: json,
        is_valid: isValid ? 'true' : 'false',
      };

      outputStream.write(outputRow);
    } catch (error) {
      console.error(`Warning: Error processing row with id ${row['id'] || 'unknown'}:`, error);
      // Write invalid row
      const outputRow: OutputRow = {
        id: row['id'] || 'unknown',
        json: '[]',
        is_valid: 'false',
      };
      outputStream.write(outputRow);
    }
  });

  inputStream.on('error', (error: Error) => {
    throw new Error(`Failed to read input file: ${error.message}`);
  });

  inputStream.on('end', () => {
    outputStream.end();
  });

  outputStream.on('error', (error: Error) => {
    throw new Error(`Failed to write output: ${error.message}`);
  });

  // Wait for processing to complete
  await new Promise<void>((resolve, reject) => {
    outputStream.on('finish', resolve);
    outputStream.on('error', reject);
    inputStream.on('error', reject);
  });
}

export { main, processJsonArray, parseArgs };

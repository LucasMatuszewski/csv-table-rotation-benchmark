import { processJsonArray, parseArgs } from '../src/cli';
import { writeFileSync, unlinkSync, existsSync, mkdirSync, rmdirSync } from 'fs';
import { execSync } from 'child_process';
import path from 'path';
import { fileURLToPath } from 'url';
import {
  jest,
  describe,
  test,
  expect,
  beforeEach,
  afterEach,
  beforeAll,
  afterAll,
} from '@jest/globals';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const testDir = path.join(__dirname, 'temp');

describe('processJsonArray', () => {
  test('processes valid 1x1 matrix', () => {
    // Original: [42]  →  After: [42] (single element unchanged)
    // Expected JSON: "[42]"
    const result = processJsonArray('[42]');
    expect(result.isValid).toBe(true);
    expect(result.json).toBe('[42]');
  });

  test('processes valid 2x2 matrix', () => {
    // Original:        After 1-step clockwise:
    // [1, 2]       →   [3, 1]
    // [3, 4]           [4, 2]
    // Expected JSON: "[3,1,4,2]"
    const result = processJsonArray('[1, 2, 3, 4]');
    expect(result.isValid).toBe(true);
    expect(result.json).toBe('[3,1,4,2]');
  });

  test('processes valid 3x3 matrix', () => {
    // Original:           After 1-step clockwise:
    // [1, 2, 3]       →   [4, 1, 2]
    // [4, 5, 6]           [7, 5, 3]
    // [7, 8, 9]           [8, 9, 6]
    // Ring: 1→2→3→6→9→8→7→4 becomes 4→1→2→3→6→9→8→7, center 5 unchanged
    // Expected JSON: "[4,1,2,7,5,3,8,9,6]"
    const result = processJsonArray('[1, 2, 3, 4, 5, 6, 7, 8, 9]');
    expect(result.isValid).toBe(true);
    expect(result.json).toBe('[4,1,2,7,5,3,8,9,6]');
  });

  test('processes valid 4x4 matrix', () => {
    // Original:              After 1-step clockwise:
    // [ 1,  2,  3,  4]   →   [ 5,  1,  2,  3]
    // [ 5,  6,  7,  8]       [ 9, 10,  6,  4]
    // [ 9, 10, 11, 12]       [13, 11,  7,  8]
    // [13, 14, 15, 16]       [14, 15, 16, 12]
    const result = processJsonArray('[1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16]');
    expect(result.isValid).toBe(true);
    expect(result.json).toBe('[5,1,2,3,9,10,6,4,13,11,7,8,14,15,16,12]');
  });

  test('processes negative numbers correctly', () => {
    // Original:         After 1-step clockwise:
    // [-1, -2]      →   [-3, -1]
    // [-3, -4]          [-4, -2]
    // Ring: -1→-2→-4→-3 becomes -3→-1→-2→-4
    // Expected JSON: "[-3,-1,-4,-2]"
    const result = processJsonArray('[-1, -2, -3, -4]');
    expect(result.isValid).toBe(true);
    expect(result.json).toBe('[-3,-1,-4,-2]');
  });

  test('handles zeros correctly', () => {
    const result = processJsonArray('[0, 0, 0, 0]');
    expect(result.isValid).toBe(true);
    expect(result.json).toBe('[0,0,0,0]');
  });

  test('rejects invalid non-square arrays', () => {
    const result = processJsonArray('[1, 2, 3]');
    expect(result.isValid).toBe(false);
    expect(result.json).toBe('[]');
  });

  test('rejects empty arrays', () => {
    const result = processJsonArray('[]');
    expect(result.isValid).toBe(false);
    expect(result.json).toBe('[]');
  });

  test('rejects non-array JSON', () => {
    const result = processJsonArray('42');
    expect(result.isValid).toBe(false);
    expect(result.json).toBe('[]');
  });

  test('rejects arrays with non-numeric values', () => {
    const result = processJsonArray('[1, "hello", 3]');
    expect(result.isValid).toBe(false);
    expect(result.json).toBe('[]');
  });

  test('rejects malformed JSON', () => {
    const result = processJsonArray('[1, 2,');
    expect(result.isValid).toBe(false);
    expect(result.json).toBe('[]');
  });

  test('rejects arrays with null values', () => {
    const result = processJsonArray('[1, null, 3, 4]');
    expect(result.isValid).toBe(false);
    expect(result.json).toBe('[]');
  });

  test('rejects arrays with NaN values', () => {
    const result = processJsonArray('[1, NaN, 3, 4]');
    expect(result.isValid).toBe(false);
    expect(result.json).toBe('[]');
  });

  test('rejects arrays with Infinity values', () => {
    const result = processJsonArray('[1, Infinity, 3, 4]');
    expect(result.isValid).toBe(false);
    expect(result.json).toBe('[]');
  });
});

describe('parseArgs', () => {
  let originalArgv: string[];

  beforeEach(() => {
    originalArgv = process.argv;
  });

  afterEach(() => {
    process.argv = originalArgv;
  });

  test('parses input file correctly', () => {
    process.argv = ['node', 'cli.js', 'input.csv'];
    const args = parseArgs();
    expect(args.inputFile).toBe('input.csv');
    expect(args.help).toBe(false);
  });

  test('shows help when no arguments provided', () => {
    process.argv = ['node', 'cli.js'];
    const args = parseArgs();
    expect(args.help).toBe(true);
  });

  test('shows help when --help flag provided', () => {
    process.argv = ['node', 'cli.js', '--help'];
    const args = parseArgs();
    expect(args.help).toBe(true);
  });

  test('shows help when -h flag provided', () => {
    process.argv = ['node', 'cli.js', '-h'];
    const args = parseArgs();
    expect(args.help).toBe(true);
  });

  test('exits with error for multiple arguments', () => {
    process.argv = ['node', 'cli.js', 'file1.csv', 'file2.csv'];

    const exitSpy = jest
      .spyOn(process, 'exit')
      .mockImplementation((code?: string | number | null | undefined) => {
        throw new Error(`process.exit(${code})`);
      });
    const consoleErrorSpy = jest.spyOn(console, 'error').mockImplementation(() => {});

    expect(() => parseArgs()).toThrow('process.exit(1)');
    expect(consoleErrorSpy).toHaveBeenCalledWith(
      'Error: Expected exactly one argument (input file path)'
    );

    exitSpy.mockRestore();
    consoleErrorSpy.mockRestore();
  });
});

describe('CLI Integration Tests', () => {
  const testInputFile = path.join(testDir, 'test-input.csv');
  const cliPath = path.join(__dirname, '../dist/index.js');

  beforeAll(() => {
    // Ensure the CLI is built
    try {
      execSync('npm run build', {
        cwd: path.join(__dirname, '..'),
        stdio: 'pipe',
      });
    } catch (error) {
      console.warn('Build failed, CLI tests may not work properly');
    }

    // Create test directory
    if (!existsSync(testDir)) {
      mkdirSync(testDir, { recursive: true });
    }
  });

  afterAll(() => {
    // Clean up test files
    if (existsSync(testInputFile)) {
      unlinkSync(testInputFile);
    }
    try {
      rmdirSync(testDir);
    } catch (error) {
      // Directory might not be empty or might not exist
    }
  });

  test('processes sample CSV file correctly', () => {
    // Create test CSV file with known data
    const testCsv = `id,json
1,"[1]"
2,"[1, 2, 3, 4]"
3,"[1, 2, 3, 4, 5, 6, 7, 8, 9]"
4,"[40, 20, 90, 10]"
5,"[-5]"
6,"[2, -0]"
7,"[2, -5, -5]"
8,"[]"
9,"[1, 2, 3]"`;

    writeFileSync(testInputFile, testCsv);

    try {
      const output = execSync(`node "${cliPath}" "${testInputFile}"`, {
        encoding: 'utf8',
      });

      const lines = output.trim().split('\n');

      // Check header
      expect(lines[0]).toBe('id,json,is_valid');

      // Check specific results
      expect(lines[1]).toBe('1,[1],true');
      expect(lines[2]).toBe('2,"[3,1,4,2]",true');
      expect(lines[3]).toBe('3,"[4,1,2,7,5,3,8,9,6]",true');
      expect(lines[4]).toBe('4,"[90,40,10,20]",true');
      expect(lines[5]).toBe('5,[-5],true');
      expect(lines[6]).toBe('6,[],false'); // [2, -0] has length 2, not square
      expect(lines[7]).toBe('7,[],false'); // [2, -5, -5] has length 3, not square
      expect(lines[8]).toBe('8,[],false'); // empty array
      expect(lines[9]).toBe('9,[],false'); // [1, 2, 3] has length 3, not square
    } catch (error) {
      throw new Error(`CLI execution failed: ${error}`);
    }
  });

  test('handles missing file gracefully', () => {
    const nonExistentFile = path.join(testDir, 'does-not-exist.csv');

    try {
      execSync(`node "${cliPath}" "${nonExistentFile}"`, {
        encoding: 'utf8',
        stdio: 'pipe',
      });
      expect(true).toBe(false); // Expected CLI to fail with missing file
    } catch (error: any) {
      expect(error.status).toBe(1);
      expect(error.stderr).toContain('Error:');
    }
  });

  test('shows help message', () => {
    try {
      const output = execSync(`node "${cliPath}" --help`, {
        encoding: 'utf8',
      });

      expect(output).toContain('Table Rotation CLI - TypeScript Implementation');
      expect(output).toContain('USAGE:');
      expect(output).toContain('node cli.js');
      expect(output).toContain('EXAMPLES:');
    } catch (error) {
      throw new Error(`Help command failed: ${error}`);
    }
  });

  test('produces identical output to Rust implementation for key cases', () => {
    // Test with the exact same cases that should match Rust output
    const testCsv = `id,json
1,"[1, 2, 3, 4, 5, 6, 7, 8, 9]"
2,"[40, 20, 90, 10]"
3,"[-5]"
4,"[2, -5, -5]"`;

    writeFileSync(testInputFile, testCsv);

    try {
      const output = execSync(`node "${cliPath}" "${testInputFile}"`, {
        encoding: 'utf8',
      });

      const lines = output.trim().split('\n');

      // These should match the expected output from the recruitment spec
      expect(lines[1]).toBe('1,"[4,1,2,7,5,3,8,9,6]",true');
      expect(lines[2]).toBe('2,"[90,40,10,20]",true');
      expect(lines[3]).toBe('3,[-5],true');
      expect(lines[4]).toBe('4,[],false');
    } catch (error) {
      throw new Error(`CLI execution failed: ${error}`);
    }
  });
});

describe('algorithm consistency with Rust implementation', () => {
  test('produces same results for all test cases', () => {
    const testCases = [
      { input: '[1]', expected: '[1]', valid: true },
      { input: '[1, 2, 3, 4]', expected: '[3,1,4,2]', valid: true },
      { input: '[1, 2, 3, 4, 5, 6, 7, 8, 9]', expected: '[4,1,2,7,5,3,8,9,6]', valid: true },
      { input: '[-1, -2, -3, -4]', expected: '[-3,-1,-4,-2]', valid: true },
      { input: '[0, 0, 0, 0]', expected: '[0,0,0,0]', valid: true },
      { input: '[1, 2, 3]', expected: '[]', valid: false },
      { input: '[]', expected: '[]', valid: false },
      { input: '[1, "hello", 3]', expected: '[]', valid: false },
      { input: '42', expected: '[]', valid: false },
      { input: '[1, 2,', expected: '[]', valid: false },
    ];

    testCases.forEach(({ input, expected, valid }) => {
      const result = processJsonArray(input);
      expect(result.json).toBe(expected);
      expect(result.isValid).toBe(valid);
    });
  });
});

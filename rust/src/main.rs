use clap::Parser;
use csv::{ReaderBuilder, WriterBuilder};
use env_logger::Env;
use rotate_cli::{rotate_right, square_len};
use serde_json::Value;
use std::{fs::File, io, process};

/// Rotate square tables inside a CSV file shifting each element one position clockwise around its ring.
#[derive(Parser)]
#[command(name = "rotate_cli")]
#[command(about = "A CLI tool to rotate square numerical tables in CSV files")]
#[command(version = "0.1.0")]
struct Cli {
    /// Path to input CSV file with columns 'id' and 'json'
    input: String,
}

fn main() {
    env_logger::Builder::from_env(Env::default().default_filter_or("warn")).init();

    if let Err(e) = run() {
        eprintln!("Error: {}", e);
        process::exit(1);
    }
}

fn run() -> Result<(), Box<dyn std::error::Error>> {
    let cli = Cli::parse();

    // Open input CSV file
    let file = File::open(&cli.input)?;
    let mut rdr = ReaderBuilder::new()
        .has_headers(true)
        .flexible(true)
        .from_reader(file);

    // Create CSV writer to stdout
    let mut wtr = WriterBuilder::new()
        .has_headers(true)
        .from_writer(io::stdout());

    // Write output headers
    wtr.write_record(["id", "json", "is_valid"])?;

    // Process each record
    for result in rdr.records() {
        let record = result?;

        // Ensure we have at least 2 fields (id and json)
        if record.len() < 2 {
            eprintln!("Warning: Skipping record with insufficient fields");
            continue;
        }

        let id = &record[0];
        let json_text = &record[1];

        // Process the JSON and determine validity
        let (rotated_json, is_valid) = process_json_array(json_text);

        // Write output record
        wtr.write_record([id, &rotated_json, if is_valid { "true" } else { "false" }])?;
    }

    wtr.flush()?;
    Ok(())
}

/// Process a JSON string containing an array of numbers.
/// Returns (json_string, is_valid) where json_string is either the rotated array or empty array.
fn process_json_array(json_text: &str) -> (String, bool) {
    // Try to parse JSON
    let parsed_value = match serde_json::from_str::<Value>(json_text) {
        Ok(value) => value,
        Err(_) => return ("[]".to_string(), false),
    };

    // Ensure it's an array
    let array = match parsed_value {
        Value::Array(arr) => arr,
        _ => return ("[]".to_string(), false),
    };

    // Convert to numbers
    let mut numbers: Vec<i64> = Vec::with_capacity(array.len());
    for value in array {
        match value {
            Value::Number(num) => {
                if let Some(int_val) = num.as_i64() {
                    numbers.push(int_val);
                } else if let Some(float_val) = num.as_f64() {
                    // Handle float numbers by converting to int if they're whole numbers
                    if float_val.fract() == 0.0 {
                        numbers.push(float_val as i64);
                    } else {
                        return ("[]".to_string(), false);
                    }
                } else {
                    return ("[]".to_string(), false);
                }
            }
            _ => return ("[]".to_string(), false),
        }
    }

    // Check if it can form a square table
    if square_len(numbers.len()).is_none() {
        return ("[]".to_string(), false);
    }

    // If empty array, it's technically a 0x0 square but we treat as invalid per spec
    if numbers.is_empty() {
        return ("[]".to_string(), false);
    }

    // Rotate the table
    match rotate_right(&mut numbers) {
        Ok(()) => {
            // Convert back to JSON
            let json_result = serde_json::to_string(&numbers).unwrap_or_else(|_| "[]".to_string());
            (json_result, true)
        }
        Err(_) => ("[]".to_string(), false),
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_process_valid_2x2() {
        // Original:        After 1-step clockwise:
        // [1, 2]       →   [3, 1]
        // [3, 4]           [4, 2]
        // Ring: 1→2→4→3 becomes 3→1→2→4
        // Expected JSON: "[3,1,4,2]"
        let (result, valid) = process_json_array("[1, 2, 3, 4]");
        assert!(valid);
        assert_eq!(result, "[3,1,4,2]");
    }

    #[test]
    fn test_process_valid_3x3() {
        // Original:           After 1-step clockwise:
        // [1, 2, 3]       →   [4, 1, 2]
        // [4, 5, 6]           [7, 5, 3]
        // [7, 8, 9]           [8, 9, 6]
        // Ring: 1→2→3→6→9→8→7→4 becomes 4→1→2→3→6→9→8→7, center 5 unchanged
        // Expected JSON: "[4,1,2,7,5,3,8,9,6]"
        let (result, valid) = process_json_array("[1, 2, 3, 4, 5, 6, 7, 8, 9]");
        assert!(valid);
        assert_eq!(result, "[4,1,2,7,5,3,8,9,6]");
    }

    #[test]
    fn test_process_valid_1x1() {
        // Original: [42]  →  After: [42] (single element unchanged)
        // Expected JSON: "[42]"
        let (result, valid) = process_json_array("[42]");
        assert!(valid);
        assert_eq!(result, "[42]");
    }

    #[test]
    fn test_process_invalid_non_square() {
        let (result, valid) = process_json_array("[1, 2, 3]");
        assert!(!valid);
        assert_eq!(result, "[]");
    }

    #[test]
    fn test_process_invalid_empty() {
        let (result, valid) = process_json_array("[]");
        assert!(!valid);
        assert_eq!(result, "[]");
    }

    #[test]
    fn test_process_invalid_non_array() {
        let (result, valid) = process_json_array("42");
        assert!(!valid);
        assert_eq!(result, "[]");
    }

    #[test]
    fn test_process_invalid_non_numeric() {
        let (result, valid) = process_json_array("[1, \"hello\", 3]");
        assert!(!valid);
        assert_eq!(result, "[]");
    }

    #[test]
    fn test_process_malformed_json() {
        let (result, valid) = process_json_array("[1, 2,");
        assert!(!valid);
        assert_eq!(result, "[]");
    }

    #[test]
    fn test_process_with_negative_numbers() {
        // Original:         After 1-step clockwise:
        // [-1, -2]      →   [-3, -1]
        // [-3, -4]          [-4, -2]
        // Ring: -1→-2→-4→-3 becomes -3→-1→-2→-4
        // Expected JSON: "[-3,-1,-4,-2]"
        let (result, valid) = process_json_array("[-1, -2, -3, -4]");
        assert!(valid);
        assert_eq!(result, "[-3,-1,-4,-2]");
    }
}

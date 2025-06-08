use criterion::{black_box, criterion_group, criterion_main, BenchmarkId, Criterion, Throughput};
use rotate_cli::{rotate_right, square_len};
use std::hint::black_box as std_black_box;

/// Generate test data for different matrix sizes and patterns
fn generate_matrix_data(n: usize, pattern: &str) -> Vec<i32> {
    let size = n * n;
    match pattern {
        "sequential" => (1..=size as i32).collect(),
        "random" => {
            use std::collections::hash_map::DefaultHasher;
            use std::hash::{Hash, Hasher};
            (0..size)
                .map(|i| {
                    let mut hasher = DefaultHasher::new();
                    i.hash(&mut hasher);
                    (hasher.finish() % 10000) as i32
                })
                .collect()
        }
        "repeated" => vec![42; size],
        "negative" => (1..=size as i32).map(|x| -x).collect(),
        "mixed" => (1..=size as i32)
            .map(|x| if x % 2 == 0 { x } else { -x })
            .collect(),
        _ => (1..=size as i32).collect(),
    }
}

/// Benchmark core rotation algorithm with different matrix sizes
fn bench_rotation_sizes(c: &mut Criterion) {
    let mut group = c.benchmark_group("rotation_by_size");
    
    // Test different matrix sizes
    for &n in &[1, 2, 3, 4, 5, 8, 10, 16, 25, 50, 100] {
        let size = n * n;
        let data = generate_matrix_data(n, "sequential");
        
        group.throughput(Throughput::Elements(size as u64));
        group.bench_with_input(
            BenchmarkId::new("rotate_matrix", format!("{}x{}", n, n)),
            &data,
            |b, input| {
                b.iter(|| {
                    let mut data = input.clone();
                    rotate_right(black_box(&mut data)).unwrap();
                    std_black_box(data);
                });
            },
        );
    }
    group.finish();
}

/// Benchmark rotation with different data patterns
fn bench_rotation_patterns(c: &mut Criterion) {
    let mut group = c.benchmark_group("rotation_by_pattern");
    let n = 10; // 10x10 matrix
    let size = n * n;
    
    for pattern in &["sequential", "random", "repeated", "negative", "mixed"] {
        let data = generate_matrix_data(n, pattern);
        
        group.throughput(Throughput::Elements(size as u64));
        group.bench_with_input(
            BenchmarkId::new("rotate_pattern", pattern),
            &data,
            |b, input| {
                b.iter(|| {
                    let mut data = input.clone();
                    rotate_right(black_box(&mut data)).unwrap();
                    std_black_box(data);
                });
            },
        );
    }
    group.finish();
}

/// Benchmark square length validation
fn bench_square_len(c: &mut Criterion) {
    let mut group = c.benchmark_group("square_len_validation");
    
    // Test various lengths including perfect squares and non-squares
    let test_lengths = vec![
        1, 4, 9, 16, 25, 36, 49, 64, 81, 100, // Perfect squares
        2, 3, 5, 6, 7, 8, 10, 15, 50, 99,     // Non-perfect squares
        1000000, 1000001, 999999,             // Large numbers
    ];
    
    for &len in &test_lengths {
        group.bench_with_input(
            BenchmarkId::new("validate_length", len),
            &len,
            |b, &input| {
                b.iter(|| {
                    std_black_box(square_len(black_box(input)));
                });
            },
        );
    }
    group.finish();
}

/// Benchmark multiple rotations (testing performance consistency)
fn bench_multiple_rotations(c: &mut Criterion) {
    let mut group = c.benchmark_group("multiple_rotations");
    let n = 10;
    let data = generate_matrix_data(n, "sequential");
    
    for &rotations in &[1, 4, 8, 16, 32] {
        group.bench_with_input(
            BenchmarkId::new("rotations", rotations),
            &(data.clone(), rotations),
            |b, (input, count)| {
                b.iter(|| {
                    let mut data = input.clone();
                    for _ in 0..*count {
                        rotate_right(black_box(&mut data)).unwrap();
                    }
                    std_black_box(data);
                });
            },
        );
    }
    group.finish();
}

/// Benchmark CSV processing pipeline simulation
fn bench_csv_processing(c: &mut Criterion) {
    use serde_json::Value;
    
    let mut group = c.benchmark_group("csv_processing");
    
    // Create the 10x10 JSON string beforehand to avoid temporary value issues
    let large_json = format!("[{}]", (1..=100).map(|x| x.to_string()).collect::<Vec<_>>().join(", "));
    
    // Simulate different JSON array sizes commonly found in CSV
    let test_cases = vec![
        (1, "[1]"),
        (2, "[1, 2, 3, 4]"),
        (3, "[1, 2, 3, 4, 5, 6, 7, 8, 9]"),
        (4, "[1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16]"),
        (5, "[1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25]"),
        (10, large_json.as_str()),
    ];
    
    for (n, json_str) in test_cases {
        group.bench_with_input(
            BenchmarkId::new("json_parse_rotate", format!("{}x{}", n, n)),
            &json_str,
            |b, &input| {
                b.iter(|| {
                    // Simulate the full processing pipeline
                    let parsed_value: Value = serde_json::from_str(black_box(input)).unwrap();
                    
                    if let Value::Array(arr) = parsed_value {
                        let mut numbers: Vec<i64> = arr
                            .into_iter()
                            .map(|v| v.as_i64().unwrap())
                            .collect();
                        
                        if square_len(numbers.len()).is_some() && !numbers.is_empty() {
                            rotate_right(black_box(&mut numbers)).unwrap();
                            let result = serde_json::to_string(&numbers).unwrap();
                            std_black_box(result);
                        }
                    }
                });
            },
        );
    }
    group.finish();
}

/// Benchmark memory allocation patterns
fn bench_memory_patterns(c: &mut Criterion) {
    let mut group = c.benchmark_group("memory_allocation");
    
    // Test in-place vs cloning approaches
    let n = 20;
    let data = generate_matrix_data(n, "sequential");
    
    group.bench_function("in_place_rotation", |b| {
        b.iter(|| {
            let mut data = data.clone();
            rotate_right(black_box(&mut data)).unwrap();
            std_black_box(data);
        });
    });
    
    group.bench_function("clone_overhead", |b| {
        b.iter(|| {
            let _data1 = data.clone();
            let _data2 = data.clone();
            let _data3 = data.clone();
            std_black_box(());
        });
    });
    
    group.finish();
}

/// Benchmark edge cases and error handling
fn bench_edge_cases(c: &mut Criterion) {
    let mut group = c.benchmark_group("edge_cases");
    
    // Test various edge cases
    let test_cases = vec![
        ("empty_array", vec![]),
        ("single_element", vec![42]),
        ("non_square_small", vec![1, 2, 3]),
        ("non_square_medium", vec![1, 2, 3, 4, 5, 6, 7, 8]),
        ("large_valid", (1..=2500).collect::<Vec<i32>>()), // 50x50
    ];
    
    for (name, data) in test_cases {
        group.bench_with_input(
            BenchmarkId::new("edge_case", name),
            &data,
            |b, input| {
                b.iter(|| {
                    let mut data = input.clone();
                    let _ = rotate_right(black_box(&mut data));
                    std_black_box(data);
                });
            },
        );
    }
    group.finish();
}

/// Benchmark scaling characteristics
fn bench_scaling(c: &mut Criterion) {
    let mut group = c.benchmark_group("scaling_analysis");
    
    // Test how performance scales with matrix size
    // Focus on powers of 2 and some irregular sizes
    let sizes = vec![
        (4, "4x4"),
        (8, "8x8"), 
        (16, "16x16"),
        (32, "32x32"),
        (64, "64x64"),
        (100, "100x100"),
        (128, "128x128"),
    ];
    
    for (n, label) in sizes {
        let data = generate_matrix_data(n, "sequential");
        let elements = (n * n) as u64;
        
        group.throughput(Throughput::Elements(elements));
        group.bench_with_input(
            BenchmarkId::new("scale", label),
            &data,
            |b, input| {
                b.iter(|| {
                    let mut data = input.clone();
                    rotate_right(black_box(&mut data)).unwrap();
                    std_black_box(data);
                });
            },
        );
    }
    group.finish();
}

criterion_group!(
    rotation_benches,
    bench_rotation_sizes,
    bench_rotation_patterns,
    bench_square_len,
    bench_multiple_rotations,
    bench_csv_processing,
    bench_memory_patterns,
    bench_edge_cases,
    bench_scaling
);

criterion_main!(rotation_benches);
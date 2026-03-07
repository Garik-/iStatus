use criterion::{Criterion, criterion_group, criterion_main};
use std::hint::black_box;

fn parse_std(line: &[u8]) {
    // assert!(bytes.is_ascii());
    let s: &str = std::str::from_utf8(&line[4..]).unwrap();
    let mut v = vec![];

    for part in s.split_whitespace() {
        v.push(part.parse::<u64>().unwrap());
    }
}

fn parse_std_fix(line: &[u8]) {
    // assert!(bytes.is_ascii());
    let s: &str = std::str::from_utf8(&line[4..]).unwrap();
    let mut v: Vec<u64> = Vec::with_capacity(10);

    for part in s.split_ascii_whitespace() {
        v.push(part.parse::<u64>().unwrap());
    }
}

fn parse_line(line: &[u8]) -> [u64; 10] {
    let mut out = [0u64; 10];
    let mut num = 0u64;
    let mut idx = 0;
    let mut in_number = false;

    for &b in &line[4..] {
        match b {
            b'0'..=b'9' => {
                num = num * 10 + (b - b'0') as u64;
                in_number = true;
            }
            b' ' | b'\n' => {
                if in_number {
                    if idx >= 10 {
                        break;
                    }
                    out[idx] = num;
                    idx += 1;
                    num = 0;
                    in_number = false;
                }
            }
            _ => {}
        }
    }

    if in_number && idx < 10 {
        out[idx] = num;
    }

    out
}

fn criterion_benchmark(c: &mut Criterion) {
    let data = b"cpu  90225 233 76982 307459634 3841 0 366 0 0 0";

    /*
    c.bench_function("parse_std", |b| b.iter(|| parse_std(black_box(data))));
    c.bench_function("parse_std_fix", |b| {
        b.iter(|| parse_std_fix(black_box(data)))
    });
    */

    c.bench_function("parse_line", |b| {
        b.iter(|| black_box(parse_line(black_box(data))))
    });
}

criterion_group!(benches, criterion_benchmark);
criterion_main!(benches);

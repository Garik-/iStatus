use std::fs::File;
use std::io::{self, BufRead, BufReader};

const CPU_FIELDS: usize = 10;
const BUF_CAP: usize = 256;

#[inline(always)]
fn parse_line(line: &[u8]) -> [u64; CPU_FIELDS] {
    let mut out = [0u64; CPU_FIELDS];
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
                    if idx >= CPU_FIELDS {
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

    if in_number && idx < CPU_FIELDS {
        out[idx] = num;
    }

    out
}

fn get_cpu_times(path: &str, buf: &mut Vec<u8>) -> std::io::Result<[u64; CPU_FIELDS]> {
    let file = File::open(path)?;
    let mut reader = BufReader::with_capacity(BUF_CAP, file);
    buf.clear();
    if reader.read_until(b'\n', buf)? == 0 {
        return Err(io::Error::new(
            io::ErrorKind::UnexpectedEof,
            "empty /proc/stat",
        ));
    }
    if !buf.starts_with(b"cpu ") {
        return Err(io::Error::new(
            io::ErrorKind::InvalidData,
            "first line is not aggregate cpu stats",
        ));
    }
    Ok(parse_line(buf))
}

pub struct CPUState {
    times: [u64; CPU_FIELDS],
    buf: Vec<u8>,
    path: String,
}

impl CPUState {
    pub fn new(path: &str) -> std::io::Result<Self> {
        let mut buf = Vec::with_capacity(BUF_CAP);
        let times = get_cpu_times(path, &mut buf)?;
        Ok(Self {
            times,
            buf,
            path: path.to_owned(),
        })
    }

    pub fn usage(&mut self) -> std::io::Result<f64> {
        let current = get_cpu_times(self.path.as_str(), &mut self.buf)?;
        let mut total_delta: u64 = 0;
        let mut idle_delta: u64 = 0;

        for i in 0..self.times.len() {
            let delta = current[i].saturating_sub(self.times[i]);
            total_delta += delta;
            if i == 3 || i == 4 {
                // idle + iowait
                idle_delta += delta;
            }
        }

        self.times = current;

        if total_delta == 0 {
            Ok(0.0)
        } else {
            Ok(100.0 * (total_delta - idle_delta) as f64 / total_delta as f64)
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_parse_line() {
        let data = b"cpu  90225 233 76982 307459634 3841 0 366 0 0 0";

        assert_eq!(
            parse_line(data),
            [90225, 233, 76982, 307459634, 3841, 0, 366, 0, 0, 0]
        );
    }

    #[test]
    fn test_get_cpu_times() -> io::Result<()> {
        let mut buf = Vec::with_capacity(BUF_CAP);

        let times = get_cpu_times("test_data/proc", &mut buf)?;
        assert_eq!(times, [90225, 233, 76982, 307459634, 3841, 0, 366, 0, 0, 0]);

        let times = get_cpu_times("test_data/proc2", &mut buf)?;
        assert_eq!(times, [90320, 233, 77025, 307537725, 3845, 0, 367, 0, 0, 0]);

        Ok(())
    }
}

const REQUIRED_FIELDS_MASK: u8 = 0b1_1111;

#[derive(Debug, Default, PartialEq)]
pub struct MemInfo {
    pub total: u64,
    free: u64,
    pub available: u64,
    buffers: u64,
    cached: u64,
}

impl MemInfo {
    pub fn used(&self) -> u64 {
        self.total
            .saturating_sub(self.free)
            .saturating_sub(self.buffers)
            .saturating_sub(self.cached)
    }

    pub fn usage(&self) -> f64 {
        if self.total == 0 {
            0.0
        } else {
            self.used() as f64 * 100.0 / self.total as f64
        }
    }
}

#[inline(always)]
fn parse_num_and_unit(mut s: &[u8]) -> Option<u64> {
    while let Some(b' ' | b'\t') = s.first().copied() {
        s = &s[1..];
    }

    let mut n = 0u64;
    let mut has_digit = false;
    while let Some(c @ b'0'..=b'9') = s.first().copied() {
        n = n * 10 + (c - b'0') as u64;
        s = &s[1..];
        has_digit = true;
    }
    if !has_digit {
        return None;
    }

    while let Some(b' ' | b'\t') = s.first().copied() {
        s = &s[1..];
    }

    let value_kb = if s.starts_with(b"B") {
        n / 1024
    } else if s.starts_with(b"kB") || s.starts_with(b"KB") || s.starts_with(b"KiB") {
        n
    } else if s.starts_with(b"MB") || s.starts_with(b"MiB") {
        n * 1024
    } else if s.starts_with(b"GB") || s.starts_with(b"GiB") {
        n * 1024 * 1024
    } else {
        n
    };

    Some(value_kb)
}

fn parse_meminfo_bytes(data: &[u8]) -> MemInfo {
    let mut out = MemInfo::default();
    let mut found_mask = 0u8;

    for line in data.split(|&b| b == b'\n') {
        let Some(colon) = line.iter().position(|&b| b == b':') else {
            continue;
        };

        let field_bit = match &line[..colon] {
            b"MemTotal" => 0b00001,
            b"MemFree" => 0b00010,
            b"MemAvailable" => 0b00100,
            b"Buffers" => 0b01000,
            b"Cached" => 0b10000,
            _ => continue,
        };

        if (found_mask & field_bit) != 0 {
            continue;
        }

        if let Some(val) = parse_num_and_unit(&line[colon + 1..]) {
            match field_bit {
                0b00001 => out.total = val,
                0b00010 => out.free = val,
                0b00100 => out.available = val,
                0b01000 => out.buffers = val,
                0b10000 => out.cached = val,
                _ => {}
            }

            found_mask |= field_bit;
            if found_mask == REQUIRED_FIELDS_MASK {
                break;
            }
        }
    }

    out
}

pub fn get_meminfo(path: &str) -> std::io::Result<MemInfo> {
    let data: Vec<u8> = std::fs::read(path)?;
    Ok(parse_meminfo_bytes(&data))
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_get_meminfo() -> std::io::Result<()> {
        assert_eq!(
            get_meminfo("test_data/meminfo")?,
            MemInfo {
                total: 3887800,
                free: 2703176,
                available: 3615152,
                buffers: 71476,
                cached: 884620
            }
        );

        Ok(())
    }

    #[test]
    fn test_parse_num_and_unit_variants() {
        assert_eq!(parse_num_and_unit(b"2048 B"), Some(2));
        assert_eq!(parse_num_and_unit(b"123 kB"), Some(123));
        assert_eq!(parse_num_and_unit(b"123 MB"), Some(123 * 1024));
        assert_eq!(parse_num_and_unit(b"123"), Some(123));
    }
}

use serde::Serialize;
use serde_json::to_string;
use std::time::Duration;

mod cpu;
mod mem;

#[derive(Serialize)]
struct Mem {
    total: u64,
    used: u64,
    available: u64,
    usage: String,
}

#[derive(Serialize)]
struct Packet {
    //  temp: String,
    cpu: String,
    mem: Mem,
}

fn main() -> std::io::Result<()> {
    let mut cpu = cpu::CPUState::new("test_data/proc")?;

    loop {
        std::thread::sleep(Duration::from_millis(500));
        let usage = cpu.usage()?;

        let meminfo = mem::get_meminfo("test_data/meminfo")?;

        let packet = Packet {
            cpu: format!("{:.2}%", usage),
            mem: Mem {
                total: meminfo.total,
                used: meminfo.used(),
                available: meminfo.available,
                usage: format!("{:.2}%", meminfo.usage()),
            },
        };

        let json = to_string(&packet)?;

        println!("{}", json);
    }
}

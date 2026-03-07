mod cpu;
mod mem;

fn main() -> std::io::Result<()> {
    println!("Hello world!");

    let mut cpu = cpu::CPUState::new()?;

    loop {
        std::thread::sleep(std::time::Duration::from_millis(500));
        let usage = cpu.usage()?;
    }
}

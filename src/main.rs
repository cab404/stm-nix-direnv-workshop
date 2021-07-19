#![deny(unsafe_code)]
#![no_std]
#![no_main]

use panic_halt as _;

use cortex_m_rt::entry;
use stm32f0xx_hal::pac::Peripherals;

use embedded_hal::digital::v2::OutputPin;
use stm32f0xx_hal::{delay::Delay, pac, prelude::*};

#[entry]
fn main() -> ! {
    let mut p = Peripherals::take().unwrap();
    let mut cp = cortex_m::Peripherals::take().unwrap();
    let mut rcc = p.RCC.configure().sysclk(48.mhz()).freeze(&mut p.FLASH);
    let gpioa = p.GPIOB.split(&mut rcc);
    let mut delay = Delay::new(cp.SYST, &rcc);

    let mut led = cortex_m::interrupt::free(move |cs| {
        gpioa.pb3.into_push_pull_output(cs)
    });

    loop {

        fn fib_timer<T: OutputPin>(delay: &mut Delay, led: &mut T, a: u16, b: u16, left: usize) {
            if left == 0 {return;};
            delay.delay_ms(a);
            led.set_low().ok();
            delay.delay_ms(b);
            led.set_high().ok();
            fib_timer(delay, led,b, a + b, left - 1);
        }
        fib_timer(&mut delay, &mut led, 1, 1, 15)

    }
}

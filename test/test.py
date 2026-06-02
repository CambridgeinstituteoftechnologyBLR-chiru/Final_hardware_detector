import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, FallingEdge


async def stream_packet(dut, payload):

    for bit_idx in range(64):

        bit_in = (payload >> bit_idx) & 1

        dut.ui_in.value = (
            bit_in |
            (1 << 1)
        )

        await ClockCycles(dut.clk, 1)

    dut.ui_in.value = 0

    await ClockCycles(dut.clk, 10)


async def wait_done(dut):

    for _ in range(300):

        await FallingEdge(dut.clk)

        if int(dut.uio_out.value) & 1:
            return

    raise TimeoutError("Done pulse timeout")


@cocotb.test()
async def test_project(dut):

    cocotb.start_soon(
        Clock(dut.clk, 20, units="ns").start()
    )

    dut.ena.value = 1
    dut.ui_in.value = 0
    dut.uio_in.value = 0

    dut.rst_n.value = 0
    await ClockCycles(dut.clk, 10)

    dut.rst_n.value = 1
    await ClockCycles(dut.clk, 10)

    # Safe packet
    await stream_packet(
        dut,
        0xAA00123400001122
    )

    await wait_done(dut)

    irq = (int(dut.uio_out.value) >> 1) & 1

    assert irq == 0

    # Attack packet
    await stream_packet(
        dut,
        0x00000000FEFE0000
    )

    await wait_done(dut)

    irq = (int(dut.uio_out.value) >> 1) & 1

    assert irq == 1

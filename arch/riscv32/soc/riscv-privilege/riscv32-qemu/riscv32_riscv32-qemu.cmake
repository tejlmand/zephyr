zephyr_list(SOURCES
            OUTPUT PRIVATE_SOURCES
            qemu_irq.S
            vector.S
)

target_sources(arch_riscv32 PRIVATE ${PRIVATE_SOURCES})

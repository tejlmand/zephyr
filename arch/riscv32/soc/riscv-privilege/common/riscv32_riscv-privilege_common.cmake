zephyr_include_directories(.)

zephyr_list(SOURCES
            OUTPUT PRIVATE_SOURCES
            idle.c
            soc_irq.S
            soc_common_irq.c
            IFNDEF:${CONFIG_SOC_SERIES_RISCV32_QEMU} vector.S
)

target_sources(arch_riscv32 PRIVATE ${PRIVATE_SOURCES})

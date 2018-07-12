zephyr_compile_definitions_ifdef(CONFIG_SOC_NRF52810 NRF52810_XXAA)
zephyr_compile_definitions_ifdef(CONFIG_SOC_NRF52832 NRF52832_XXAA)
zephyr_compile_definitions_ifdef(CONFIG_SOC_NRF52840 NRF52840_XXAA)

zephyr_list(SOURCES
            OUTPUT PRIVATE_SOURCES
            power.c
            soc.c
            IFDEF:${CONFIG_ARM_MPU_NRF52X} mpu_regions.c
)

target_sources(arch_arm PRIVATE ${PRIVATE_SOURCES})

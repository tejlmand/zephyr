zephyr_list(SOURCES
            OUTPUT PRIVATE_SOURCES
            soc.c
            wdog.S
            IFDEF:${CONFIG_HAS_SYSMPU} nxp_mpu_regions.c
)

target_sources(arch_arm PRIVATE ${PRIVATE_SOURCES})

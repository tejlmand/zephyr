zephyr_list(SOURCES
            OUTPUT PRIVATE_SOURCES
            soc.c
            power.c
            IFDEF:${CONFIG_ARM_MPU_ENABLE} arm_mpu_regions.c
)

target_sources(arch_arm PRIVATE ${PRIVATE_SOURCES})

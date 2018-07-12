zephyr_list(SOURCES
            OUTPUT PRIVATE_SOURCES
            IFDEF:${CONFIG_ARM_CORE_MPU} arm_core_mpu.c
            IF_KCONFIG                   arm_mpu.c
            IF_KCONFIG                   nxp_mpu.c
)

target_sources(arch_arm PRIVATE ${PRIVATE_SOURCES})

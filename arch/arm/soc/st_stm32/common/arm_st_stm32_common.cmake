zephyr_list(SOURCES
            OUTPUT PRIVATE_SOURCES
            stm32cube_hal.c
            IFDEF:${CONFIG_STM32_ARM_MPU_ENABLE} arm_mpu_regions.c
)

target_sources(arch_arm PRIVATE ${PRIVATE_SOURCES})

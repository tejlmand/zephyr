#
# Copyright (c) 2017, NXP
#
# SPDX-License-Identifier: Apache-2.0
#
zephyr_list(SOURCES
            OUTPUT PRIVATE_SOURCES
            soc.c
            IFDEF:${CONFIG_ARM_MPU_IMX_RT} arm_mpu_regions.c
)

target_sources(arch_arm PRIVATE ${PRIVATE_SOURCES})

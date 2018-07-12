# Makefile - Atmel SAM MCU family
#
# Copyright (c) 2016 Piotr Mienkowski
# SPDX-License-Identifier: Apache-2.0
#

include_relative(${SOC_SERIES}/arm_${SOC_SERIES}.cmake)
include_relative_ifdef(CONFIG_ASF common/arm_atmel_sam_common.cmake)

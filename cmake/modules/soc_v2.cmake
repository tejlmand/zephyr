# SPDX-License-Identifier: Apache-2.0
#
# Copyright (c) 2021, Nordic Semiconductor ASA

# Configure SoC settings based on Kconfig settings and SoC root.
#
# This CMake module will set the following variables in the build system based
# on Kconfig settings and selected SoC.
#
# If no implementation is available for the selected SoC an error will be raised.
#
# Outcome:
# The following variables will be defined when this CMake module completes:
#
# - SOC_NAME:   Name of the SoC in use, identical to CONFIG_SOC
# - SOC_SERIES: Name of the SoC series in use, identical to CONFIG_SOC_SERIES
# - SOC_FAMILY: Name of the SoC family, identical to CONFIG_SOC_FAMILY
# - SOC_PATH:   Path fragment defined by either SOC_NAME or SOC_FAMILY/SOC_SERIES.
# - SOC_DIR:    Directory containing the SoC implementation
# - SOC_ROOT:   SOC_ROOT with ZEPHYR_BASE appended
#
# Variable dependencies:
# - SOC_ROOT: CMake list of SoC roots containing SoC implementations
#
# Variables set by this module and not mentioned above are considered internal
# use only and may be removed, renamed, or re-purposed without prior notice.

include_guard(GLOBAL)

include(kconfig)

if(HWMv2)
  # 'SOC_ROOT' is a prioritized list of directories where socs may be
  # found. It always includes ${ZEPHYR_BASE}/soc at the lowest priority.
  list(APPEND SOC_ROOT ${ZEPHYR_BASE})

  set(SOC_NAME   ${CONFIG_SOC})
  set(SOC_SERIES ${CONFIG_SOC_SERIES})
  set(SOC_TOOLCHAIN_NAME ${CONFIG_SOC_TOOLCHAIN_NAME})
  set(SOC_FAMILY ${CONFIG_SOC_FAMILY})
endif()

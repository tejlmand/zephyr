# Copyright (c) 2019 Nordic Semiconductor ASA.
# Copyright (c) 2021-2023 Laird Connectivity.
# SPDX-License-Identifier: Apache-2.0

if(("${BOARD_IDENTIFIER}" STREQUAL "/nrf5340/cpuapp" OR "${BOARD_IDENTIFIER}" STREQUAL "/nrf5340/cpuapp/ns")
   AND CONFIG_BOARD_ENABLE_CPUNET)
  zephyr_library()
  zephyr_library_sources(bl5340_dvk_cpunet_reset.c)

  if(CONFIG_BUILD_WITH_TFM)
    zephyr_library_include_directories(
      $<TARGET_PROPERTY:tfm,TFM_BINARY_DIR>/install/interface/include
    )
  endif()
endif()

# SPDX-License-Identifier: Apache-2.0

if(("${BOARD_IDENTIFIER}" STREQUAL "/nrf5340/cpuapp" OR "${BOARD_IDENTIFIER}" STREQUAL "/nrf5340/cpuapp/ns")
   AND CONFIG_BOARD_ENABLE_CPUNET)
  zephyr_library()
  zephyr_library_sources(raytac_mdbt53_db_40_nrf5340_cpunet_reset.c)
endif()

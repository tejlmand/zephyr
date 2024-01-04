# Copyright (c) 2021 Nordic Semiconductor ASA
# SPDX-License-Identifier: Apache-2.0

if("${BOARD_IDENTIFIER}" STREQUAL "/nrf5340/cpuapp" OR "${BOARD_IDENTIFIER}" STREQUAL "/nrf5340/cpuapp/ns")
  zephyr_library()
  zephyr_library_sources(board.c)
endif()

# Copyright (c) 2019 Nordic Semiconductor ASA.
# SPDX-License-Identifier: Apache-2.0

if("${BOARD_IDENTIFIER}" STREQUAL "/nrf9160")
  zephyr_library()
  zephyr_library_sources(nrf52840_reset.c)
elseif("${BOARD_IDENTIFIER}" STREQUAL "/nrf52840")
  zephyr_library()
  zephyr_library_sources(board.c)
endif()

# SPDX-License-Identifier: Apache-2.0

if("${BOARD_IDENTIFIER}" STREQUAL "/nrf5340/cpuapp/ns")
  set(TFM_PUBLIC_KEY_FORMAT "full")
endif()

if("${BOARD_IDENTIFIER}" STREQUAL "/nrf5340/cpuapp" OR "${BOARD_IDENTIFIER}" STREQUAL "/nrf5340/cpuapp/ns")
  board_runner_args(jlink "--device=nrf5340_xxaa_app" "--speed=4000")
elseif("${BOARD_IDENTIFIER}" STREQUAL "/nrf5340/cpunet")
  board_runner_args(jlink "--device=nrf5340_xxaa_net" "--speed=4000")
endif()

include(${ZEPHYR_BASE}/boards/common/nrfjprog.board.cmake)
include(${ZEPHYR_BASE}/boards/common/nrfutil.board.cmake)
include(${ZEPHYR_BASE}/boards/common/jlink.board.cmake)

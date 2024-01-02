# SPDX-License-Identifier: Apache-2.0

if("${BOARD_IDENTIFIER}" STREQUAL "/nrf9160" OR "${BOARD_IDENTIFIER}" STREQUAL "/nrf9160/ns")
  if("${BOARD_IDENTIFIER}" STREQUAL "/nrf9160/ns")
    set(TFM_PUBLIC_KEY_FORMAT "full")
  endif()

  if(CONFIG_TFM_FLASH_MERGED_BINARY)
    set_property(TARGET runners_yaml_props_target PROPERTY hex_file tfm_merged.hex)
  endif()

  board_runner_args(jlink "--device=nRF9160_xxAA" "--speed=4000")
  include(${ZEPHYR_BASE}/boards/common/nrfjprog.board.cmake)
  include(${ZEPHYR_BASE}/boards/common/nrfutil.board.cmake)
  include(${ZEPHYR_BASE}/boards/common/jlink.board.cmake)
elseif("${BOARD_IDENTIFIER}" STREQUAL "/nrf52840")
  board_runner_args(jlink "--device=nRF52840_xxAA" "--speed=4000")
  include(${ZEPHYR_BASE}/boards/common/nrfjprog.board.cmake)
  include(${ZEPHYR_BASE}/boards/common/nrfutil.board.cmake)
  include(${ZEPHYR_BASE}/boards/common/jlink.board.cmake)
  include(${ZEPHYR_BASE}/boards/common/openocd-nrf5.board.cmake)
endif()

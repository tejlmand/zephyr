# Copyright (c) 2021 Nordic Semiconductor
#
# SPDX-License-Identifier: Apache-2.0

if(CONFIG_SB_MPS2_AN521_EMPTY_CPU0)
  ExternalZephyrProject_Add(
    APPLICATION empty_cpu0
    BOARD mps2_an521
    SOURCE_DIR ${CMAKE_CURRENT_LIST_DIR}/empty_cpu0
  )
  list(APPEND IMAGES "empty_cpu0")
  set(empty_cpu0_BINARY_DIR "${CMAKE_BINARY_DIR}/empty_cpu0")
endif()

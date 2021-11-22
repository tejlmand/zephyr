# Copyright (c) 2021 Nordic Semiconductor
#
# SPDX-License-Identifier: Apache-2.0

# code copied from cmake/app/boilerplate.cmake directly

# 77-78
set(APPLICATION_SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR} CACHE PATH "Application Source Directory")
set(APPLICATION_BINARY_DIR ${CMAKE_CURRENT_BINARY_DIR} CACHE PATH "Application Binary Directory")

# 82
set(PROJECT_BINARY_DIR ${CMAKE_CURRENT_BINARY_DIR})

# 151
include(cmake/extensions.cmake)
include(${ZEPHYR_BASE}/cmake/extensions.cmake)

# 207
list(APPEND BOARD_ROOT ${ZEPHYR_BASE})

# 212
list(APPEND SOC_ROOT ${ZEPHYR_BASE})

# 217
list(APPEND ARCH_ROOT ${ZEPHYR_BASE})

# 248-278
foreach(root ${BOARD_ROOT})
  # Check that the board root looks reasonable.
  if(NOT IS_DIRECTORY "${root}/boards")
    message(WARNING "BOARD_ROOT element without a 'boards' subdirectory:
${root}
Hints:
  - if your board directory is '/foo/bar/boards/<ARCH>/my_board' then add '/foo/bar' to BOARD_ROOT, not the entire board directory
  - if in doubt, use absolute paths")
  endif()

  # NB: find_path will return immediately if the output variable is
  # already set
  if (BOARD_ALIAS)
    find_path(BOARD_HIDDEN_DIR
      NAMES ${BOARD_ALIAS}_defconfig
      PATHS ${root}/boards/*/*
      NO_DEFAULT_PATH
      )
    if(BOARD_HIDDEN_DIR)
      message("Board alias ${BOARD_ALIAS} is hiding the real board of same name")
    endif()
  endif()
  find_path(BOARD_DIR
    NAMES ${BOARD}_defconfig
    PATHS ${root}/boards/*/*
    NO_DEFAULT_PATH
    )
  if(BOARD_DIR AND NOT (${root} STREQUAL ${ZEPHYR_BASE}))
    set(USING_OUT_OF_TREE_BOARD 1)
  endif()
endforeach()

# 419-427
get_filename_component(BOARD_ARCH_DIR ${BOARD_DIR}      DIRECTORY)
get_filename_component(ARCH           ${BOARD_ARCH_DIR} NAME)

foreach(root ${ARCH_ROOT})
  if(EXISTS ${root}/arch/${ARCH}/CMakeLists.txt)
    set(ARCH_DIR ${root}/arch)
    break()
  endif()
endforeach()

# 554
include(cmake/kconfig.cmake)

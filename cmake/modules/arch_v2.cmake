# SPDX-License-Identifier: Apache-2.0
#
# Copyright (c) 2023, Nordic Semiconductor ASA

#
# Configure ARCH settings based on KConfig settings and arch root.
#
# This CMake module will set the following variables in the build system based
# on board directory and arch root.
#
# If no implementation is available for the current arch an error will be raised.
#
# Outcome:
# The following variables will be defined when this CMake module completes:
#
# - ARCH:      Name of the arch in use.
# - ARCH_DIR:  Directory containing the arch implementation.
# - ARCH_ROOT: ARCH_ROOT with ZEPHYR_BASE appended
#
# Variable dependencies:
# - ARCH_ROOT: CMake list of arch roots containing arch implementations
#
# Variables set by this module and not mentioned above are considered internal
# use only and may be removed, renamed, or re-purposed without prior notice.

include_guard(GLOBAL)

if(HWMv2)
  # HWMv2 obtains arch from Kconfig for the given Board / SoC cpuset because
  # the Board / SoC path is no longer sufficient for determine the arch
  # (read: multi-core and multi-arch SoC).
  set(ARCH ${CONFIG_ARCH})

  # 'ARCH_ROOT' is a prioritized list of directories where archs may be
  # found. It always includes ${ZEPHYR_BASE} at the lowest priority (except for unittesting).
  if(NOT unittest IN_LIST Zephyr_FIND_COMPONENTS)
    list(APPEND ARCH_ROOT ${ZEPHYR_BASE})
  endif()

  foreach(root ${ARCH_ROOT})
    if(EXISTS ${root}/arch/${ARCH}/CMakeLists.txt)
      set(ARCH_DIR ${root}/arch)
      break()
    endif()
  endforeach()

  if(NOT ARCH_DIR)
    message(FATAL_ERROR "Could not find ARCH=${ARCH} for BOARD=${BOARD}, \
please check your installation. ARCH roots searched: \n\
${ARCH_ROOT}")
  endif()
endif()

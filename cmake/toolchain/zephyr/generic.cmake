# SPDX-License-Identifier: Apache-2.0

include(${ZEPHYR_SDK_INSTALL_DIR}/cmake/zephyr/generic.cmake)

set(TOOLCHAIN_KCONFIG_DIR ${ZEPHYR_SDK_INSTALL_DIR}/cmake/zephyr)

if(SDK_VERSION VERSION_GREATER_EQUAL 0.16)
  set(TOOLCHAIN_HAS_PICOLIBC ON CACHE BOOL "True if toolchain supports picolibc")
endif()

message(STATUS "Found toolchain: zephyr ${SDK_VERSION} (${ZEPHYR_SDK_INSTALL_DIR})")

# SPDX-License-Identifier: Apache-2.0

cmake_minimum_required(VERSION 3.13.1)

set(QEMU_KERNEL_OPTION "-device;loader,file=${CMAKE_BINARY_DIR}/tfm_qemu.hex")

find_package(Zephyr HINTS $ENV{ZEPHYR_BASE})

trusted_firmware_build(BINARY_DIR ${CMAKE_BINARY_DIR}/tfm
                       BOARD ${TFMBOARD}
		       OUT_VENEERS_FILE VENEERS_FILE
		       OUT_INCLUDE_PATH TFM_INCLUDE_PATH)

project(tfm_ipc)

add_dependencies(app tfm)

target_sources(app PRIVATE src/main.c)

target_include_directories(app PRIVATE
  ${TFM_INCLUDE_PATH}
  )


target_link_libraries(${ZEPHYR_CURRENT_LIBRARY} PRIVATE
  ${VENEERS_FILE}
  )

target_compile_definitions(app PRIVATE
  -DTFM_PSA_API
  )
target_compile_definitions(app PRIVATE
  -DTFM_PARTITION_TEST_CORE_IPC
  )

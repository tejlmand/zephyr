# SPDX-License-Identifier: Apache-2.0

cmake_minimum_required(VERSION 3.13.1)

set(QEMU_KERNEL_OPTION "-device;loader,file=${CMAKE_BINARY_DIR}/tfm_qemu.hex")

include($ENV{ZEPHYR_BASE}/cmake/app/boilerplate.cmake NO_POLICY_SCOPE)

include(${CMAKE_CURRENT_SOURCE_DIR}/../CMakeLists.inc)

include(ExternalProject)

set(BINARY_DIR ${CMAKE_BINARY_DIR}/tfm)
set(TFM_EXPORT_PATH ${BINARY_DIR}/install/export)

set(TFMCONFIG "ConfigRegressionIPC")
ExternalProject_Add(
  tfm
  SOURCE_DIR ${TFM_BASE_DIR}
  BINARY_DIR ${BINARY_DIR}
  BUILD_BYPRODUCTS ${TFM_EXPORT_PATH}/tfm/veneers/s_veneers.o
  CMAKE_ARGS -DPROJ_CONFIG=${TFM_BASE_DIR}/configs/${TFMCONFIG}.cmake
             -DTARGET_PLATFORM=${TFMBOARD} -DBL2=True -DCOMPILER=GNUARM
	     -DGNUARM_PREFIX=arm-zephyr-eabi
	     -DGNUARM_PATH=${ZEPHYR_SDK_INSTALL_DIR}/arm-zephyr-eabi
)
project(tfm_ipc)

add_dependencies(app tfm)

target_sources(app PRIVATE src/main.c)

target_include_directories(app PRIVATE
  ${TFM_EXPORT_PATH}/tfm/include
  )

target_link_libraries(${ZEPHYR_CURRENT_LIBRARY} PRIVATE
  ${TFM_EXPORT_PATH}/tfm/veneers/s_veneers.o
  )

target_compile_definitions(app PRIVATE
  -DTFM_PSA_API
  )
target_compile_definitions(app PRIVATE
  -DTFM_PARTITION_TEST_CORE_IPC
  )

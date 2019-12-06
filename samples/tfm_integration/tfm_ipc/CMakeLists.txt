# SPDX-License-Identifier: Apache-2.0

cmake_minimum_required(VERSION 3.13.1)

set(QEMU_KERNEL_OPTION "-device;loader,file=${CMAKE_BINARY_DIR}/tfm_qemu.hex")

include($ENV{ZEPHYR_BASE}/cmake/app/boilerplate.cmake NO_POLICY_SCOPE)
include(ExternalProject)

set(TFMCONFIG "ConfigRegressionIPC")
set(TFM_BASE "$ENV{ZEPHYR_BASE}/../modules/tee/tfm/trusted-firmware-m")
ExternalProject_Add(
  tfm
  SOURCE_DIR ${TFM_BASE}
  CMAKE_ARGS -DPROJ_CONFIG=${TFM_BASE}/configs/${TFMCONFIG}.cmake
             -DTARGET_PLATFORM=${TFMBOARD} -DBL2=True -DCOMPILER=GNUARM
	     -DGNUARM_PREFIX=arm-zephyr-eabi
	     -DGNUARM_PATH=${ZEPHYR_SDK_INSTALL_DIR}/arm-zephyr-eabi
  BUILD_BYPRODUCTS ${BINARY_DIR}/tfm/veneers/s_veneers.o
)

project(tfm_ipc)

add_dependencies(app tfm)

ExternalProject_Get_property(tfm BINARY_DIR)
set (TFM_EXPORT_PATH ${BINARY_DIR}/install/export)

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

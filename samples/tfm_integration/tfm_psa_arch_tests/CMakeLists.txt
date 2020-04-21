# SPDX-License-Identifier: Apache-2.0

cmake_minimum_required(VERSION 3.13.1)

include($ENV{ZEPHYR_BASE}/cmake/app/boilerplate.cmake NO_POLICY_SCOPE)

include(${CMAKE_CURRENT_SOURCE_DIR}/../CMakeLists.inc)

project(tfm_ipc)

set (TFM_ROOT_PATH $ENV{ZEPHYR_BASE}/../modules/tfm/trusted-firmware-m)

target_sources(app PRIVATE src/main.c)

if(${CONFIG_PSA_ARCH_API_TEST})
  set(PSA_API_TEST_BUILD_PATH ${TFM_ROOT_PATH}/../psa-arch-tests/api-tests/BUILD)
  target_include_directories(app PRIVATE $ENV{ZEPHYR_BASE}/include/cmsis_rtos_v2)
  target_include_directories(app PRIVATE ${TFM_ROOT_PATH}/lib/ext/qcbor/inc)

  target_sources(app PRIVATE ${TFM_ROOT_PATH}/app/os_wrapper_cmsis_rtos_v2.c)

  target_sources(app PRIVATE ${TFM_ROOT_PATH}/interface/src/tfm_psa_ns_api.c)
  target_sources(app PRIVATE ${TFM_ROOT_PATH}/interface/src/tfm_ns_interface.c)
  target_sources(app PRIVATE ${TFM_ROOT_PATH}/interface/src/tfm_crypto_ipc_api.c)
  target_sources(app PRIVATE ${TFM_ROOT_PATH}/interface/src/tfm_sst_ipc_api.c)
  target_sources(app PRIVATE ${TFM_ROOT_PATH}/interface/src/tfm_initial_attestation_ipc_api.c)

  target_sources(app PRIVATE ${TFM_ROOT_PATH}/lib/ext/qcbor/src/ieee754.c)
  target_sources(app PRIVATE ${TFM_ROOT_PATH}/lib/ext/qcbor/src/qcbor_decode.c)
  target_sources(app PRIVATE ${TFM_ROOT_PATH}/lib/ext/qcbor/src/qcbor_encode.c)
  target_sources(app PRIVATE ${TFM_ROOT_PATH}/lib/ext/qcbor/src/UsefulBuf.c)

  target_link_libraries(${ZEPHYR_CURRENT_LIBRARY} PRIVATE
    "${PSA_API_TEST_BUILD_PATH}/val/val_nspe.a"
  )
  target_link_libraries(${ZEPHYR_CURRENT_LIBRARY} PRIVATE
    "${PSA_API_TEST_BUILD_PATH}/platform/pal_nspe.a"
  )

  target_link_libraries(${ZEPHYR_CURRENT_LIBRARY} PRIVATE
    "${PSA_API_TEST_BUILD_PATH}/dev_apis/${CONFIG_PSA_API_TEST_SUITE}/test_combine.a"
  )
endif()

target_include_directories(app PRIVATE
  ${TFM_ROOT_PATH}/interface/include
  )

target_link_libraries(${ZEPHYR_CURRENT_LIBRARY} PRIVATE
  ${TFM_ROOT_PATH}/build/install/export/tfm/veneers/s_veneers.o
  )

target_compile_definitions(app PRIVATE
  -DTFM_PSA_API
  )
target_compile_definitions(app PRIVATE
  -DTFM_PARTITION_TEST_CORE_IPC
  )

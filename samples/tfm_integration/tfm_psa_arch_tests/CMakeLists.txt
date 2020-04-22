# SPDX-License-Identifier: Apache-2.0

cmake_minimum_required(VERSION 3.13.1)

include($ENV{ZEPHYR_BASE}/cmake/app/boilerplate.cmake NO_POLICY_SCOPE)

# Include common TF-M paths and values
include(${CMAKE_CURRENT_SOURCE_DIR}/../CMakeLists.inc)

include(ExternalProject)

# Make sure we are using a compatible board target, and set key values
if((${BOARD} STREQUAL "mps2_an521_nonsecure"))
	set(PSA_ARCH_TESTS_BOARD "tgt_dev_apis_tfm_an521")
	set(PSA_ARCH_CPU "armv8m_ml")
	set(PSA_ARCH_LVL "2")
elseif((${BOARD} STREQUAL "v2m_musca_b1_nonsecure"))
	set(PSA_ARCH_TESTS_BOARD "tgt_dev_apis_tfm_musca_b1")
	set(PSA_ARCH_CPU "armv8m_ml")
	set(PSA_ARCH_LVL "2")
else()
        message(FATAL_ERROR "${BOARD} unsupported. Please use \'${ZEPHYRBOARD}\'.")
endif()

# Build psa-arch-tests before TF-M
ExternalProject_Add(
  tfm_psa
  SOURCE_DIR ${TFM_REMOTE_DIR}/psa-arch-tests/api-tests
  CMAKE_ARGS -G "Unix Makefiles"
             -DTARGET=${PSA_ARCH_TESTS_BOARD}
	     -DCPU_ARCH=${PSA_ARCH_CPU}
	     -DCOMPILER=GNUARM
	     -DSUITE=${CONFIG_PSA_ARCH_TEST_SUITE}
	     -DPLATFORM_PSA_ISOLATION_LEVEL=${PSA_ARCH_LVL}
	     -DSP_HEAP_MEM_SUPP=0
	     -DPSA_INCLUDE_PATHS=${TFM_BASE_DIR}/interface/include
  BUILD_BYPRODUCTS ${BINARY_DIR}/tfm/veneers/s_veneers.o
)

# Build TF-M
ExternalProject_Add(
  tfm
  SOURCE_DIR ${TFM_BASE_DIR}
  CMAKE_ARGS -DPROJ_CONFIG=${TFM_BASE_DIR}/configs/ConfigPsaApiTestIPC.cmake
             -DTARGET_PLATFORM=${TFMBOARD} -DBL2=True -DCOMPILER=GNUARM
	     #-DGNUARM_PREFIX=arm-zephyr-eabi
	     #-DGNUARM_PATH=${ZEPHYR_SDK_INSTALL_DIR}/arm-zephyr-eabi
	     -DGNUARM_PREFIX=arm-none-eabi
	     -DGNUARM_PATH=/usr/local/prog/gcc-arm-none-eabi-7-2018-q2-update
  BUILD_BYPRODUCTS ${BINARY_DIR}/tfm/veneers/s_veneers.o
)

project(tfm_psa_arch_tests)

set(PSA_API_TEST_BUILD_PATH ${TFM_REMOTE_DIR}/psa-arch-tests/api-tests/BUILD)

target_include_directories(app PRIVATE $ENV{ZEPHYR_BASE}/include/cmsis_rtos_v2)
target_include_directories(app PRIVATE ${TFM_BASE_DIR}/lib/ext/qcbor/inc)

target_sources(app PRIVATE src/main.c)
target_sources(app PRIVATE ${TFM_BASE_DIR}/app/os_wrapper_cmsis_rtos_v2.c)
target_sources(app PRIVATE ${TFM_BASE_DIR}/interface/src/tfm_psa_ns_api.c)
target_sources(app PRIVATE ${TFM_BASE_DIR}/interface/src/tfm_ns_interface.c)
target_sources(app PRIVATE ${TFM_BASE_DIR}/interface/src/tfm_crypto_ipc_api.c)
target_sources(app PRIVATE ${TFM_BASE_DIR}/interface/src/tfm_sst_ipc_api.c)
target_sources(app PRIVATE ${TFM_BASE_DIR}/interface/src/tfm_initial_attestation_ipc_api.c)
target_sources(app PRIVATE ${TFM_BASE_DIR}/lib/ext/qcbor/src/ieee754.c)
target_sources(app PRIVATE ${TFM_BASE_DIR}/lib/ext/qcbor/src/qcbor_decode.c)
target_sources(app PRIVATE ${TFM_BASE_DIR}/lib/ext/qcbor/src/qcbor_encode.c)
target_sources(app PRIVATE ${TFM_BASE_DIR}/lib/ext/qcbor/src/UsefulBuf.c)

target_link_libraries(${ZEPHYR_CURRENT_LIBRARY} PRIVATE
  "${PSA_API_TEST_BUILD_PATH}/val/val_nspe.a"
)

target_link_libraries(${ZEPHYR_CURRENT_LIBRARY} PRIVATE
  "${PSA_API_TEST_BUILD_PATH}/platform/pal_nspe.a"
)

target_link_libraries(${ZEPHYR_CURRENT_LIBRARY} PRIVATE
  "${PSA_API_TEST_BUILD_PATH}/dev_apis/${CONFIG_PSA_ARCH_TEST_SUITE}/test_combine.a"
)

target_include_directories(app PRIVATE
  ${TFM_BASE_DIR}/interface/include
)

target_link_libraries(${ZEPHYR_CURRENT_LIBRARY} PRIVATE
  ${TFM_BASE_DIR}/build/install/export/tfm/veneers/s_veneers.o
)

target_compile_definitions(app PRIVATE -DTFM_PSA_API)
target_compile_definitions(app PRIVATE -DTFM_PARTITION_TEST_CORE_IPC)

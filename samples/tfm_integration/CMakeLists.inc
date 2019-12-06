# Copyright (c) 2019 Linaro
#
# SPDX-License-Identifier: Apache-2.0

cmake_minimum_required(VERSION 3.13.1)
project(NONE)

# Make sure we are using a compatible board target.
if((${BOARD} STREQUAL "mps2_an521_nonsecure"))
else()
        message(FATAL_ERROR "${BOARD} unsupported. Please use \'${ZEPHYRBOARD}\'.")
endif()

if(NOT DEFINED TFMCONFIG)
	set(TFMCONFIG "ConfigRegressionIPC")
endif()

# Set the TF-M output folders. This is placed here and not in the build folder
# since you will generally only want to do the clone and build operations
# once for trusted-firmware-m and dependencies.
set(TFM_REMOTE_DIR "$ENV{ZEPHYR_BASE}/../modules/tee/tfm")
set(TFM_BASE "${TFM_REMOTE_DIR}/trusted-firmware-m")
set(TFM_PSA_API_DIR "${TFM_BASE}/build/install/export/tee/tfm")

# Assign the full git path to ${GIT_EXECUTABLE}.
find_package(Git)

# Set an ARM toolchain path for the CI docker image
set(TFM_CI_ARM "export PATH=$PATH:/opt/toolchain/arm-none-eabi/bin")

# Run the specified bash command string from ${TFM_BASE}/build.
function(tfmbuild_exec cmd)
        message(STATUS "Executing \'${cmd}\'")
        # TODO: Fix this since it will only work with bash!
        execute_process(
                # TODO: Only prepend path in CI environment
                COMMAND bash -c "${TFM_CI_ARM}; ${cmd}"
                WORKING_DIRECTORY ${TFM_BASE}/build
                OUTPUT_VARIABLE PROCESS_OUTPUT
                OUTPUT_STRIP_TRAILING_WHITESPACE)
        message("${PROCESS_OUTPUT}")
endfunction()

# Check if trusted-firmware-m build folder already exists.
if(EXISTS ${TFM_BASE}/build/install)
        set(TFM_BUILD_EXISTS "TRUE")
        message(STATUS "TF-M build/install folder already exists: \'${TFM_BASE}/build/install/\'")
endif()

# Clone TF-M repo and dependencies if necessary
if(NOT TFM_BUILD_EXISTS)
        # Start TF-M build process:
        message(STATUS "Building trusted-firmware-m secure library")
        set(READLINK readlink)
        find_program(GREADLINK greadlink)
        if(GREADLINK)
                # Check for 'greadlink' on OS X ('brew install coreutils').
                set(READLINK greadlink)
        endif()
        file(MAKE_DIRECTORY ${TFM_BASE}/build)
        tfmbuild_exec("cd .. && ${GIT_EXECUTABLE} reset --hard ${TFM_COMMIT_HASH}")
        tfmbuild_exec("${CMAKE_COMMAND} -G\"Unix Makefiles\" -DPROJ_CONFIG=`${READLINK} -f ../configs/${TFMCONFIG}.cmake` -DTFM_PSA_API=True -DTARGET_PLATFORM=${TFMBOARD} -DBL2=True -DCMAKE_BUILD_TYPE=${BUILD_TYPE} -DCOMPILER=GNUARM ../")
        tfmbuild_exec("cmake --build . -- install")
endif()

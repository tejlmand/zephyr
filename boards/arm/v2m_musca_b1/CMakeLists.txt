#
# Copyright (c) 2019 Linaro Limited
#
# SPDX-License-Identifier: Apache-2.0
#

zephyr_library()
zephyr_library_sources(pinmux.c)
zephyr_library_include_directories(${ZEPHYR_BASE}/drivers)

if (CONFIG_BUILD_WITH_TFM)
	set (TFM_ROOT_PATH $ENV{ZEPHYR_BASE}/../modules/tee/tfm/trusted-firmware-m)
	set (MCUBOOT_DIR "${TFM_ROOT_PATH}/bl2/ext/mcuboot")
	set (PREPROCESSED_FILE "${TFM_ROOT_PATH}/build/image_macros_preprocessed.c")

	if (NOT DEFINED IMAGE_VERSION)
		set(IMAGE_VERSION 0.0.0+0)
	endif()

	#Find Python3 interpreter
	find_package(PythonInterp 3)
	if (NOT PYTHONINTERP_FOUND)
		message(FATAL_ERROR "Failed to find Python3 interpreter. Pyhton3 must be installed and available on the PATH.")
	endif()

	set(KEY_FILE    "${MCUBOOT_DIR}/root-rsa-3072.pem")

	#Configure in which format (full or hash) include the public key to the image manifest
	set(PUBLIC_KEY_FORMAT "full")

	#Create and sign for concatenated binary image should align with the TF-M BL2
	set_property(GLOBAL APPEND PROPERTY extra_post_build_commands
		#Create concatenated binary image from the two binary file
		COMMAND ${PYTHON_EXECUTABLE} ${MCUBOOT_DIR}/scripts/assemble.py
		ARGS --layout ${PREPROCESSED_FILE}
			-s ${TFM_ROOT_PATH}/build/install/outputs/MUSCA_B1/tfm_s.bin
			-n ${CMAKE_BINARY_DIR}/zephyr/zephyr.bin
			-o ${CMAKE_BINARY_DIR}/tfm_full.bin

		#Sign concatenated binary image with default public key in mcuboot folder
		COMMAND ${PYTHON_EXECUTABLE} ${MCUBOOT_DIR}/scripts/imgtool.py
		ARGS sign
			--layout ${PREPROCESSED_FILE}
			-k ${KEY_FILE}
			--public-key-format ${PUBLIC_KEY_FORMAT}
			--align 1
			-v ${IMAGE_VERSION}
			${ADD_SECURITY_COUNTER}
			-H 0x400
			${CMAKE_BINARY_DIR}/tfm_full.bin
			${CMAKE_BINARY_DIR}/tfm_sign.bin

		#srec_cat to combine images into hex for drag and drop
		COMMAND srec_cat ${TFM_ROOT_PATH}/build/bl2/ext/mcuboot/mcuboot.bin -Binary -offset 0xA000000 ${CMAKE_BINARY_DIR}/tfm_sign.bin -Binary -offset 0xA020000 -o ${CMAKE_BINARY_DIR}/tfm_zephyr.hex -Intel)
endif()

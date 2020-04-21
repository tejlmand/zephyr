#
# Copyright (c) 2019 Linaro Limited
#
# SPDX-License-Identifier: Apache-2.0
#

zephyr_library()
zephyr_library_sources(pinmux.c)
zephyr_library_include_directories(${ZEPHYR_BASE}/drivers)

if (CONFIG_BUILD_WITH_TFM)
	# TODO: Relocate to TF-M module
	include(${ZEPHYR_BASE}/samples/tfm_integration/CMakeLists.inc)

	set (PREPROCESSED_FILE "${APPLICATION_SOURCE_DIR}/build/tfm-prefix/src/tfm-build/image_macros_preprocessed")

	# Configure which format (full or hash) to include the public key in
	# the image manifest
	set(TFM_PUBLIC_KEY_FORMAT "full")

	#Set srec_cat binary name
	set(SREC_CAT "srec_cat")

	#Create and sign for concatenated binary image should align with the TF-M BL2
	set_property(GLOBAL APPEND PROPERTY extra_post_build_commands
		#Create concatenated binary image from the two binary file
		COMMAND ${PYTHON_EXECUTABLE} ${TFM_MCUBOOT_DIR}/scripts/assemble.py
		ARGS --layout ${PREPROCESSED_FILE}.c
			-s ${APPLICATION_SOURCE_DIR}/build/tfm-prefix/src/tfm-build/install/outputs/MUSCA_B1/tfm_s.bin
			-n ${CMAKE_BINARY_DIR}/zephyr/zephyr.bin
			-o ${CMAKE_BINARY_DIR}/tfm_full.bin

		#Sign concatenated binary image with default public key in mcuboot folder
		COMMAND ${PYTHON_EXECUTABLE} ${TFM_MCUBOOT_DIR}/scripts/imgtool.py
		ARGS sign
			--layout ${PREPROCESSED_FILE}.c
			-k ${TFM_KEY_FILE_S}
			--public-key-format ${TFM_PUBLIC_KEY_FORMAT}
			--align 1
			-v ${TFM_IMAGE_VERSION_S}
			${ADD_SECURITY_COUNTER}
			-H 0x400
			${CMAKE_BINARY_DIR}/tfm_full.bin
			${CMAKE_BINARY_DIR}/tfm_sign.bin

		#srec_cat to combine images into hex for drag and drop
		COMMAND ${SREC_CAT}
		ARGS ${APPLICATION_SOURCE_DIR}/build/tfm-prefix/src/tfm-build/bl2/ext/mcuboot/mcuboot.bin -binary
			-offset 0xA000000
			${CMAKE_BINARY_DIR}/tfm_sign.bin -binary
			-offset 0xA020000
			-o ${CMAKE_BINARY_DIR}/tfm_zephyr.hex -Intel --line-length=44
	)
endif()

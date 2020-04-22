# Copyright (c) 2019 Linaro
#
# SPDX-License-Identifier: Apache-2.0

cmake_minimum_required(VERSION 3.13.1)
project(NONE)

# Set TF-M folders
set(TFM_REMOTE_DIR "$ENV{ZEPHYR_BASE}/../modules/tee/tfm")
set(TFM_BASE_DIR "${TFM_REMOTE_DIR}/trusted-firmware-m")
set(TFM_PSA_API_DIR "${TFM_BASE_DIR}/build/install/export/tee/tfm")
set(TFM_MCUBOOT_DIR "${TFM_BASE_DIR}/bl2/ext/mcuboot")

# Set default image versions if not defined elsewhere
if (NOT DEFINED TFM_IMAGE_VERSION_S)
	set(TFM_IMAGE_VERSION_S 0.0.0+0)
endif()
if (NOT DEFINED TFM_IMAGE_VERSION_NS)
	set(TFM_IMAGE_VERSION_NS 0.0.0+0)
endif()

# Use default signing keys if not defined elsewhere
if (NOT DEFINED TFM_KEY_FILE_S)
	set(TFM_KEY_FILE_S  "${TFM_MCUBOOT_DIR}/root-rsa-3072.pem")
endif()
if (NOT DEFINED TFM_KEY_FILE_NS)
	set(TFM_KEY_FILE_NS "${TFM_MCUBOOT_DIR}/root-rsa-3072_1.pem")
endif()

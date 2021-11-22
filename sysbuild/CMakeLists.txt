# Copyright (c) 2021 Nordic Semiconductor
#
# SPDX-License-Identifier: Apache-2.0

cmake_minimum_required(VERSION 3.20)

if(NOT DEFINED APP_DIR)
  message(FATAL_ERROR "No main application specified")
endif()

# This ensures we can find the right Zephyr for loading of additional tools
# without loading the boilerplate code.
set(NO_BOILERPLATE TRUE)
find_package(Zephyr REQUIRED HINTS $ENV{ZEPHYR_BASE})

include(cmake/boilerplate.cmake)

project(west_build LANGUAGES)

# Global list of images enabled in this multi image build system.
set(IMAGES)

get_filename_component(APP_DIR  ${APP_DIR} ABSOLUTE)
get_filename_component(app_name ${APP_DIR} NAME)

# This adds the primary application to the build.
ExternalZephyrProject_Add(
  APPLICATION ${app_name}
  SOURCE_DIR ${APP_DIR}
  MAIN_APP
)
list(APPEND IMAGES "${app_name}")

# Include MCUboot if enabled.
if(CONFIG_SB_BOOTLOADER_MCUBOOT)
  ExternalZephyrProject_Add(
    APPLICATION mcuboot
    # TODO: Temphack for prototype, need support for Zephyr modules to be able
    #       to refer to as: ZEPHYR_MCUBOOT_MODULE_DIR/boot/zephyr
    SOURCE_DIR ${ZEPHYR_BASE}/../bootloader/mcuboot/boot/zephyr/
  )
  # MCUBoot should be first in list, as it is a bootloader.
  list(PREPEND IMAGES "mcuboot")
endif()

# This allows for board and app specific images to be included.
include(${BOARD_DIR}/sysbuild.cmake OPTIONAL)
include(${APP_DIR}/sysbuild.cmake OPTIONAL)

add_subdirectory(cmake/flash)

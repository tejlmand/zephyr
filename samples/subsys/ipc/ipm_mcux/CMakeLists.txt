# Copyright (c) 2017, NXP
#
# SPDX-License-Identifier: Apache-2.0
#
set(BOARD lpcxpresso54114_m4)


include($ENV{ZEPHYR_BASE}/cmake/app/boilerplate.cmake NO_POLICY_SCOPE)
include(ExternalProject)
string(CONFIGURE ${CONFIG_SLAVE_IMAGE_MCUX} output_image)

ExternalProject_Add(
  ipm_mcux_remote
  SOURCE_DIR ${APPLICATION_SOURCE_DIR}/remote
  INSTALL_COMMAND ""      # This particular build system has no install command
  BUILD_BYPRODUCTS ${output_image}
)

project(NONE)

target_sources(app PRIVATE src/main_master.c)
add_dependencies(core_m0_inc_target ipm_mcux_remote)

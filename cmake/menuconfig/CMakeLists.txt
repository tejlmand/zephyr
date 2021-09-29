# SPDX-License-Identifier: Apache-2.0

# Folders needed for conf/mconf files (kconfig has no method of redirecting all output files).
# conf/mconf needs to be run from a different directory because of: GH-3408
cmake_minimum_required(VERSION 3.20.0)

project(menuconfig)
enable_language(NONE)

# A list of common environment settings used when invoking Kconfig during CMake
# configure time or menuconfig and related build target.
string(REPLACE ";" "\\\;" SHIELD_AS_LIST_ESCAPED "${SHIELD_AS_LIST}")

file(READ ${MENUCONFIG_ENV_FILE} MENUCONFIG_ENV)

# Allow out-of-tree users to add their own Kconfig python frontend
# targets by appending targets to the CMake list
# 'EXTRA_KCONFIG_TARGETS' and setting variables named
# 'EXTRA_KCONFIG_TARGET_COMMAND_FOR_<target>'
#
# e.g.
# cmake -DEXTRA_KCONFIG_TARGETS=cli
# -DEXTRA_KCONFIG_TARGET_COMMAND_FOR_cli=cli_kconfig_frontend.py

set(EXTRA_KCONFIG_TARGET_COMMAND_FOR_menuconfig
  ${ZEPHYR_BASE}/scripts/kconfig/menuconfig.py
  )

set(EXTRA_KCONFIG_TARGET_COMMAND_FOR_guiconfig
  ${ZEPHYR_BASE}/scripts/kconfig/guiconfig.py
  )

set(EXTRA_KCONFIG_TARGET_COMMAND_FOR_hardenconfig
  ${ZEPHYR_BASE}/scripts/kconfig/hardenconfig.py
  )

foreach(target ${KCONFIG_TARGETS})
  add_custom_target(
    ${target}
    ${CMAKE_COMMAND} -E env
    ZEPHYR_BASE=${ZEPHYR_BASE}
    ZEPHYR_TOOLCHAIN_VARIANT=${ZEPHYR_TOOLCHAIN_VARIANT}
    ${MENUCONFIG_ENV}
    "SHIELD_AS_LIST=${SHIELD_AS_LIST_ESCAPED}"
    DTS_POST_CPP=${DTS_POST_CPP}
    DTS_ROOT_BINDINGS=${DTS_ROOT_BINDINGS}
    ${PYTHON_EXECUTABLE}
    ${EXTRA_KCONFIG_TARGET_COMMAND_FOR_${target}}
    ${KCONFIG_ROOT}
    USES_TERMINAL
    COMMAND_EXPAND_LISTS
    )
endforeach()


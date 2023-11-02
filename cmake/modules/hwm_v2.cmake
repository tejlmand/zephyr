# SPDX-License-Identifier: Apache-2.0
#
# Copyright (c) 2023, Nordic Semiconductor ASA

# The HWMv2 CMake module works together with the list_hardware.py script to
# obtain all archs and SoC implementations defined in the Zephyr build system.
#
# The result from list_hwm.py is then used to generate Kconfig HWMv2 and CMake
# HWMv2 files for the build system.
#
# The following files are generated in '<kconfig-binary-dir>/'
# - Kconfig.defconfig: Contains references to SoC v2 defconfig files for Zephyr integration.
# - Kconfig: Contains references to regular SoC v2 Kconfig files for Zephyr integration.
# - Kconfig.soc: Contains references to generic SoC v2 Kconfig files.

include_guard(GLOBAL)

if(NOT HWMv2)
  return()
endif()

# Internal helper function for creation of Kconfig files.
function(kconfig_soc_gen file dirs)
  set(kconfig_file ${KCONFIG_BINARY_DIR}/${file})
  foreach(dir ${dirs})
    file(APPEND ${kconfig_file} "osource \"${dir}/${file}\"\n")
  endforeach()
endfunction()

# 'SOC_ROOT' and 'ARCH_ROOT' are prioritized lists of directories where their
# implementations may be found. It always includes ${ZEPHYR_BASE}/[arch|soc]
# at the lowest priority.
list(APPEND SOC_ROOT ${ZEPHYR_BASE})
list(APPEND ARCH_ROOT ${ZEPHYR_BASE})

list(TRANSFORM ARCH_ROOT PREPEND "--arch-root=" OUTPUT_VARIABLE arch_root_args)
list(TRANSFORM SOC_ROOT PREPEND "--soc-root=" OUTPUT_VARIABLE soc_root_args)

execute_process(COMMAND ${PYTHON_EXECUTABLE} ${ZEPHYR_BASE}/scripts/list_hardware.py
                ${arch_root_args} ${soc_root_args}
                --archs --socs
                --cmakeformat={TYPE}\;{NAME}\;{DIR}\;{HWM}
                OUTPUT_VARIABLE ret_hwm
                ERROR_VARIABLE err_hwm
                RESULT_VARIABLE ret_val
)
if(ret_val)
  message(FATAL_ERROR "Error processing HWMv2.\nError message: ${err_board}")
endif()

set(kconfig_soc_source_dir)

while(TRUE)
  string(FIND "${ret_hwm}" "\n" idx REVERSE)
  math(EXPR start "${idx} + 1")
  string(SUBSTRING "${ret_hwm}" ${start} -1 line)
  string(SUBSTRING "${ret_hwm}" 0 ${idx} ret_hwm)

  cmake_parse_arguments(HWM "" "TYPE" "" ${line})
  if(HWM_TYPE STREQUAL "arch")
    cmake_parse_arguments(ARCH_V2 "" "NAME;DIR" "" ${line})
    list(APPEND ARCH_V2_NAME_LIST ${ARCH_V2_NAME})
    string(TOUPPER "${ARCH_V2_NAME}" ARCH_V2_NAME_UPPER)
    set(ARCH_V2_${ARCH_V2_NAME_UPPER}_DIR ${ARCH_V2_DIR})
  elseif(HWM_TYPE MATCHES "^soc|^series|^family")
    cmake_parse_arguments(SOC_V2 "" "NAME;DIR;HWM" "" ${line})

    # 1. list of all dirs, then remove duplicate for Kconfig osource'ing
    # 2. Create CMAKE vars for each entry.
    list(APPEND kconfig_soc_source_dir "${SOC_V2_DIR}")

    if(HWM_TYPE STREQUAL "soc")
      set(setting_name SOC_${SOC_V2_NAME}_DIR)
    else()
      set(setting_name SOC_${HWM_TYPE}_${SOC_V2_NAME}_DIR)
    endif()
    string(TOUPPER ${setting_name} setting_name)
    set(${setting_name} ${SOC_V2_DIR})
  endif()

  if(idx EQUAL -1)
    break()
  endif()
endwhile()
list(REMOVE_DUPLICATES kconfig_soc_source_dir)

# Support multiple SOC_ROOT
set(soc_defconfig_file Kconfig.defconfig)
set(soc_zephyr_file    Kconfig)
set(soc_kconfig_file   Kconfig.soc)
set(def_conf_header    "# Load Zephyr SoC Kconfig defonfig for hw model v2.\n")
set(soc_zephyr_header  "# Load Zephyr SoC Kconfig descriptions for hw model v2.\n")
set(soc_kconfig_header "# Load SoC Kconfig descriptions for hw model v2.\n")
set(soc_cmake_header   "# Load SoC CMake implementations for hw model v2.\n")
file(WRITE ${KCONFIG_BINARY_DIR}/${soc_defconfig_file} "${defconfig_header}")
file(WRITE ${KCONFIG_BINARY_DIR}/${soc_zephyr_file}    "${soc_zephyr_header}")
file(WRITE ${KCONFIG_BINARY_DIR}/${soc_kconfig_file}   "${soc_kconfig_header}")

kconfig_soc_gen("${soc_defconfig_file}" "${kconfig_soc_source_dir}")
kconfig_soc_gen("${soc_zephyr_file}" "${kconfig_soc_source_dir}")
kconfig_soc_gen("${soc_kconfig_file}" "${kconfig_soc_source_dir}")

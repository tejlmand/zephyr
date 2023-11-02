# SPDX-License-Identifier: Apache-2.0
#
# Copyright (c) 2023, Nordic Semiconductor ASA

# To be filled.
#
# This CMake module will set the following variables in the build system.
#
# Outcome:
# The following variables will be defined when this CMake module completes:
#
#
# Variable dependencies:
# - SOC_ROOT:  CMake list of SoC roots containing SoC implementations
# - ARCH_ROOT: CMake list of arch roots containing arch implementations
#
# Variables set by this module and not mentioned above are considered internal
# use only and may be removed, renamed, or re-purposed without prior notice.

include_guard(GLOBAL)

if(NOT HWMv2)
  return()
endif()

# Internal helper function for creation of Kconfig files.
function(kconfig_soc_gen file names var_prefix)
  set(kconfig_file ${KCONFIG_BINARY_DIR}/${file})
  foreach(name ${names})
    string(TOUPPER "${name}" name_upper)
    file(APPEND ${kconfig_file} "osource \"${${var_prefix}_${name_upper}_DIR}/${file}\"\n")
  endforeach()
endfunction()

# Internal helper function for creation of CMake include file.
function(cmake_soc_gen file names var_prefix config_prefix)
  set(cmake_file ${CMAKE_BINARY_DIR}/${file})
  foreach(name ${names})
    string(TOUPPER "${name}" name_upper)
    set(config  "${config_prefix}_${name_upper}")
    set(src_dir "${${var_prefix}_${name_upper}_DIR}")
    set(bin_dir "soc/${name}")
    file(APPEND ${cmake_file} "add_subdirectory_ifdef(${config} ${src_dir} ${bin_dir})")
  endforeach()
endfunction()

# 'SOC_ROOT' and 'ARCH_ROOT' are prioritized lists of directories where their
# implementations may be found. It always includes ${ZEPHYR_BASE}/[arch|soc]
# at the lowest priority.
list(APPEND SOC_ROOT ${ZEPHYR_BASE})
list(APPEND ARCH_ROOT ${ZEPHYR_BASE})

list(TRANSFORM ARCH_ROOT PREPEND "--arch-root=" OUTPUT_VARIABLE arch_root_args)
list(TRANSFORM SOC_ROOT PREPEND "--soc-root=" OUTPUT_VARIABLE soc_root_args)

set(list_hwm_command
)
execute_process(COMMAND ${PYTHON_EXECUTABLE} ${ZEPHYR_BASE}/scripts/list_hwm.py
                ${arch_root_args} ${soc_root_args}
                --archs --socs
                --cmakeformat={TYPE}\;{NAME}\;{SERIES}\;{FAMILY}\;{DIR}\;{HWM}
                OUTPUT_VARIABLE ret_hwm
                ERROR_VARIABLE err_hwm
                RESULT_VARIABLE ret_val
)
if(ret_val)
  message(FATAL_ERROR "Error processing HWMv2.\nError message: ${err_board}")
endif()

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
  elseif(HWM_TYPE STREQUAL "soc")
    cmake_parse_arguments(SOC_V2 "" "NAME;SERIES;FAMILY;DIR" "" ${line})

    if(SOC_V2_NAME)
      list(APPEND SOC_V2_NAME_LIST ${SOC_V2_NAME})
      string(TOUPPER "${SOC_V2_NAME}" SOC_V2_NAME_UPPER)
      set(SOC_V2_${SOC_V2_NAME_UPPER}_DIR ${SOC_V2_DIR})
    endif()

    if(SOC_V2_SERIES)
      list(APPEND SOC_V2_SERIES_LIST ${SOC_V2_SERIES})
      string(TOUPPER "${SOC_V2_SERIES}" SOC_V2_SERIES_UPPER)
      set(SOC_V2_SERIES_${SOC_V2_SERIES_UPPER}_DIR ${SOC_V2_DIR})
    endif()

    if(SOC_V2_FAMILY)
      list(APPEND SOC_V2_FAMILY_LIST ${SOC_V2_FAMILY})
      string(TOUPPER "${SOC_V2_FAMILY}" SOC_V2_FAMILY_UPPER)
      set(SOC_V2_FAMILY_${SOC_V2_FAMILY_UPPER}_DIR ${SOC_V2_DIR})
    endif()
  endif()

  if(idx EQUAL -1)
    break()
  endif()
endwhile()


# Support multiple SOC_ROOT
set(soc_defconfig_file Kconfig.zephyr.defconfig)
set(soc_zephyr_file    Kconfig.zephyr)
set(soc_kconfig_file   Kconfig.soc)
set(soc_cmake_file     soc.v2.cmake)
set(def_conf_header    "# Load Zephyr SoC Kconfig defonfig for hw model v2.\n")
set(soc_zephyr_header  "# Load Zephyr SoC Kconfig descriptions for hw model v2.\n")
set(soc_kconfig_header "# Load SoC Kconfig descriptions for hw model v2.\n")
set(soc_cmake_header   "# Load SoC CMake implementations for hw model v2.\n")
file(WRITE ${KCONFIG_BINARY_DIR}/${soc_defconfig_file} "${defconfig_header}")
file(WRITE ${KCONFIG_BINARY_DIR}/${soc_zephyr_file}    "${soc_zephyr_header}")
file(WRITE ${KCONFIG_BINARY_DIR}/${soc_kconfig_file}   "${soc_kconfig_header}")
file(WRITE ${CMAKE_BINARY_DIR}/${soc_cmake_file}       "${soc_cmake_header}")

kconfig_soc_gen("${soc_defconfig_file}" "${SOC_V2_NAME_LIST}"   "SOC_V2")
kconfig_soc_gen("${soc_defconfig_file}" "${SOC_V2_SERIES_LIST}" "SOC_V2_SERIES")
kconfig_soc_gen("${soc_defconfig_file}" "${SOC_V2_FAMILY_LIST}" "SOC_V2_FAMILY")

kconfig_soc_gen("${soc_zephyr_file}" "${SOC_V2_NAME_LIST}"   "SOC_V2")
kconfig_soc_gen("${soc_zephyr_file}" "${SOC_V2_SERIES_LIST}" "SOC_V2_SERIES")
kconfig_soc_gen("${soc_zephyr_file}" "${SOC_V2_FAMILY_LIST}" "SOC_V2_FAMILY")

kconfig_soc_gen("${soc_kconfig_file}" "${SOC_V2_NAME_LIST}"   "SOC_V2")
kconfig_soc_gen("${soc_kconfig_file}" "${SOC_V2_SERIES_LIST}" "SOC_V2_SERIES")
kconfig_soc_gen("${soc_kconfig_file}" "${SOC_V2_FAMILY_LIST}" "SOC_V2_FAMILY")

cmake_soc_gen("${soc_cmake_file}" "${SOC_V2_NAME_LIST}"   "SOC_V2"        "CONFIG_SOC")
cmake_soc_gen("${soc_cmake_file}" "${SOC_V2_SERIES_LIST}" "SOC_V2_SERIES" "CONFIG_SOC_SERIES")
cmake_soc_gen("${soc_cmake_file}" "${SOC_V2_FAMILY_LIST}" "SOC_V2_FAMILY" "CONFIG_SOC_FAMILY")

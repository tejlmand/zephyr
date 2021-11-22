# Copyright (c) 2021 Nordic Semiconductor
#
# SPDX-License-Identifier: Apache-2.0

# Usage:
#   ExternalZephyrProject_Add(...)
#
# This function includes a Zephyr based build system into the multiimage
# build system
#
# APPLICATION: <name>: Name of the application, name will also be used for build
#                      folder of the application
# SOURCE_DIR <dir>:    Source directory of the application
# BOARD <board>:       Use <board> for application build instead user defined BOARD.
# MAIN_APP:            Flag indicating this application is the main application
#                      and where user defined settings should be passed on as-is
#                      except for multi image build flags.
#                      For example, -DCONF_FILES=<files> will be passed on to the
#                      MAIN_APP unmodified.
#
function(ExternalZephyrProject_Add)
  cmake_parse_arguments(ZBUILD "MAIN_APP" "APPLICATION;BOARD;SOURCE_DIR" "" ${ARGN})

  # TODO: Argument verification. Not required for the prototype but important later.
  #       If this comment is still present when PR is not in draft state, please make a review comment here.

  set(west_build_vars
      "APP_DIR"
      "SB_CONF_FILE"
  )

  # General cache vars specified by the user propagate to all Zephyr build, for example:
  # - ZEPHYR_MODULES / ZEPHYR_EXTRA_MODULES
  # - ZEPHYR_TOOLCHAIN_VARIANT (when specified using -D)
  # etc.
  # except for the app specific configuration options below, and `-DCONFIG_*`
  # Note: such vars can be passed using `<image>_CONF_FILE`, like `mcuboot_CONF_FILE`
  set(app_only_cache_vars
      "CONF_FILE"
      "OVERLAY_CONFIG"
      "DTC_OVERLAY_FILE"
  )

  set(app_cache_file ${CMAKE_BINARY_DIR}/CMake${ZBUILD_APPLICATION}PreloadCache.txt)

  if(EXISTS ${app_cache_file})
    file(STRINGS ${app_cache_file} app_cache_strings)
    set(app_cache_strings_current ${app_cache_strings})
  endif()

  get_cmake_property(variables_cached CACHE_VARIABLES)
  foreach(var_name ${variables_cached})
    # Any var of the form `<app>_<var>` should be propagated.
    # For example mcuboot_<VAR>=<val> ==> -D<VAR>=<val> for mcuboot build.
    if("${var_name}" MATCHES "^${ZBUILD_APPLICATION}_.*")
      list(APPEND application_vars ${var_name})
    endif()

    # This means there is a match to another image than current one, ignore.
    if("${var_name}" MATCHES "^.*_CONFIG_.*")
      continue()
    endif()

    # West build reserved namespace.
    if(var_name IN_LIST west_build_vars OR "${var_name}" MATCHES "^CONFIG_SB_.*")
      continue()
    endif()

    if((var_name IN_LIST app_only_cache_vars) AND NOT ZBUILD_MAIN_APP)
      continue()
    endif()

    if("${var_name}" MATCHES "^CONFIG_.*")
      if(ZBUILD_MAIN_APP)
        list(APPEND application_vars ${var_name})
      else()
        continue()
      endif()
    endif()

    get_property(var_help CACHE ${var_name} PROPERTY HELPSTRING)
    if("${var_help}" STREQUAL "No help, variable specified on the command line.")
      list(APPEND application_vars ${var_name})
    endif()
  endforeach()

  foreach(app_var_name ${application_vars})
    string(REGEX REPLACE "^${ZBUILD_APPLICATION}_" "" var_name "${app_var_name}")
    get_property(var_type  CACHE ${app_var_name} PROPERTY TYPE)
    set(new_cache_entry "${var_name}:${var_type}=${${app_var_name}}")
    if(NOT new_cache_entry IN_LIST app_cache_strings)
      # This entry does not exists, let's see if it has been updated.
      foreach(entry ${app_cache_strings})
        if("${entry}" MATCHES "^${var_name}:.*")
          list(REMOVE_ITEM app_cache_strings "${entry}")
          break()
        endif()
      endforeach()
      list(APPEND app_cache_strings "${var_name}:${var_type}=${${app_var_name}}")
      list(APPEND app_cache_entries "-D${var_name}:${var_type}=${${app_var_name}}")
    endif()
  endforeach()

  if(NOT "${app_cache_strings_current}" STREQUAL "${app_cache_strings}")
    string(REPLACE ";" "\n" app_cache_strings "${app_cache_strings}")
    file(WRITE ${app_cache_file} ${app_cache_strings})
  endif()

  if(DEFINED ZBUILD_BOARD)
    list(APPEND app_cache_entries "-DBOARD=${ZBUILD_BOARD}")
  elseif(NOT ZBUILD_MAIN_APP)
    list(APPEND app_cache_entries "-DBOARD=${BOARD}")
  endif()

  set(image_banner "* Running CMake for ${ZBUILD_APPLICATION} *")
  string(LENGTH "${image_banner}" image_banner_width)
  string(REPEAT "*" ${image_banner_width} image_banner_header)
  message(STATUS "\n   ${image_banner_header}\n"
                 "   ${image_banner}\n"
                 "   ${image_banner_header}\n"
  )

  execute_process(
    COMMAND ${CMAKE_COMMAND}
      -G${CMAKE_GENERATOR}
      ${app_cache_entries}
      -B${CMAKE_BINARY_DIR}/${ZBUILD_APPLICATION}
      -S${ZBUILD_SOURCE_DIR}
    RESULT_VARIABLE   return_val
    WORKING_DIRECTORY ${CMAKE_BINARY_DIR}
  )

  if(return_val)
    message(FATAL_ERROR
            "CMake configure failed for Zephyr project: ${ZBUILD_APPLICATION}\n"
            "Location: ${ZBUILD_SOURCE_DIR}"
    )
  endif()

  foreach(kconfig_target
      menuconfig
      hardenconfig
      guiconfig
      ${EXTRA_KCONFIG_TARGETS}
      )

    if(NOT ZBUILD_MAIN_APP)
      set(image_prefix "${ZBUILD_APPLICATION}_")
    endif()

    add_custom_target(${image_prefix}${kconfig_target}
      ${CMAKE_MAKE_PROGRAM} ${kconfig_target}
      WORKING_DIRECTORY ${CMAKE_BINARY_DIR}/${ZBUILD_APPLICATION}
      USES_TERMINAL
      )
  endforeach()
  include(ExternalProject)
  ExternalProject_Add(
    ${ZBUILD_APPLICATION}
    SOURCE_DIR ${ZBUILD_SOURCE_DIR}
    BINARY_DIR ${CMAKE_BINARY_DIR}/${ZBUILD_APPLICATION}
    CONFIGURE_COMMAND ""
    BUILD_COMMAND ${CMAKE_COMMAND} --build .
    INSTALL_COMMAND ""
    BUILD_ALWAYS True
    USES_TERMINAL_BUILD True
  )
endfunction()

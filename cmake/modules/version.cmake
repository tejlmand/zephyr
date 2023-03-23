# SPDX-License-Identifier: Apache-2.0

#.rst:
# version.cmake
# -------------
#
# Inputs:
#
#   ``*VERSION*`` and other constants set by
#   maintainers in ``${ZEPHYR_BASE}/VERSION``
#
# Outputs with examples::
#
#   PROJECT_VERSION           1.14.99.07
#   KERNEL_VERSION_STRING    "1.14.99-extraver"
#
#   KERNEL_VERSION_MAJOR       1
#   KERNEL_VERSION_MINOR        14
#   KERNEL_PATCHLEVEL             99
#   KERNELVERSION            0x10E6307
#   KERNEL_VERSION_NUMBER    0x10E63
#   ZEPHYR_VERSION_CODE        69219
#
# Most outputs are converted to C macros, see ``version.h.in``
#
# See also: independent and more dynamic ``BUILD_VERSION`` in
# ``git.cmake``.

# Note: version.cmake is loaded multiple times by ZephyrConfigVersion.cmake to
# determine this Zephyr package version and thus the correct Zephyr CMake
# package to load.
# Therefore `version.cmake` should not use include_guard(GLOBAL).
# The final load of `version.cmake` will setup correct build version values.

include(${ZEPHYR_BASE}/cmake/hex.cmake)

if(NOT DEFINED VERSION_FILE AND NOT DEFINED VERSION_TYPE)
#  set(VERSION_FILE ${ZEPHYR_BASE}/VERSION ${APPLICATION_SOURCE_DIR}/VERSION)
#  set(VERSION_TYPE KERNEL                 APP)
  set(VERSION_FILE ${ZEPHYR_BASE}/VERSION)
  set(VERSION_TYPE KERNEL)
endif()
set(type ${VERSION_TYPE})

if(NOT DEFINED VERSION_TYPE)
  set(VERSION_TYPE KERNEL)
  set(proj_type PROJECT)
else()
  set(proj_type ${VERSION_TYPE})
endif()

file(READ ${VERSION_FILE} ver)

string(REGEX MATCH "VERSION_MAJOR = ([0-9]*)" _ ${ver})
set(${VERSION_TYPE}_VERSION_MAJOR ${CMAKE_MATCH_1})

string(REGEX MATCH "VERSION_MINOR = ([0-9]*)" _ ${ver})
set(${VERSION_TYPE}_VERSION_MINOR ${CMAKE_MATCH_1})

string(REGEX MATCH "PATCHLEVEL = ([0-9]*)" _ ${ver})
set(${VERSION_TYPE}_PATCHLEVEL ${CMAKE_MATCH_1})

string(REGEX MATCH "VERSION_TWEAK = ([0-9]*)" _ ${ver})
set(${VERSION_TYPE}_VERSION_TWEAK ${CMAKE_MATCH_1})

string(REGEX MATCH "EXTRAVERSION = ([a-z0-9]*)" _ ${ver})
set(${VERSION_TYPE}_VERSION_EXTRA ${CMAKE_MATCH_1})

# Temporary convenience variable
set(${VERSION_TYPE}_VERSION_WITHOUT_TWEAK ${${VERSION_TYPE}_VERSION_MAJOR}.${${VERSION_TYPE}_VERSION_MINOR}.${${VERSION_TYPE}_PATCHLEVEL})


set(MAJOR ${${VERSION_TYPE}_VERSION_MAJOR}) # Temporary convenience variable
set(MINOR ${${VERSION_TYPE}_VERSION_MINOR}) # Temporary convenience variable
set(PATCH ${${VERSION_TYPE}_PATCHLEVEL})    # Temporary convenience variable
set(TWEAK ${${VERSION_TYPE}_VERSION_TWEAK}) # Temporary convenience variable

math(EXPR ${VERSION_TYPE}_VERSION_NUMBER_INT "(${MAJOR} << 16) + (${MINOR} << 8)  + (${PATCH})")
math(EXPR ${VERSION_TYPE}VERSION_INT         "(${MAJOR} << 24) + (${MINOR} << 16) + (${PATCH} << 8) + (${TWEAK})")

to_hex(${${VERSION_TYPE}_VERSION_NUMBER_INT} ${VERSION_TYPE}_VERSION_NUMBER)
to_hex(${${VERSION_TYPE}VERSION_INT}         ${VERSION_TYPE}VERSION)

if(${VERSION_TYPE}_VERSION_EXTRA)
  set(${VERSION_TYPE}_VERSION_STRING     "\"${${VERSION_TYPE}_VERSION_WITHOUT_TWEAK}-${${VERSION_TYPE}_VERSION_EXTRA}\"")
else()
  set(${VERSION_TYPE}_VERSION_STRING     "\"${${VERSION_TYPE}_VERSION_WITHOUT_TWEAK}\"")
endif()

if(type STREQUAL KERNEL)
  set(PROJECT_VERSION_MAJOR      ${${VERSION_TYPE}_VERSION_MAJOR})
  set(PROJECT_VERSION_MINOR      ${${VERSION_TYPE}_VERSION_MINOR})
  set(PROJECT_VERSION_PATCH      ${${VERSION_TYPE}_PATCHLEVEL})
  set(PROJECT_VERSION_TWEAK      ${${VERSION_TYPE}_VERSION_TWEAK})
  set(PROJECT_VERSION_EXTRA      ${${VERSION_TYPE}_VERSION_EXTRA})

  if(PROJECT_VERSION_EXTRA)
    set(PROJECT_VERSION_EXTRA_STR "-${PROJECT_VERSION_EXTRA}")
  endif()

  if(${VERSION_TYPE}_VERSION_TWEAK)
    set(PROJECT_VERSION ${${VERSION_TYPE}_VERSION_WITHOUT_TWEAK}.${${VERSION_TYPE}_VERSION_TWEAK})
  else()
    set(PROJECT_VERSION ${${VERSION_TYPE}_VERSION_WITHOUT_TWEAK})
  endif()

  set(PROJECT_VERSION_STR ${PROJECT_VERSION}${PROJECT_VERSION_EXTRA_STR})

  set(ZEPHYR_VERSION_CODE ${${VERSION_TYPE}_VERSION_NUMBER_INT})
  set(ZEPHYR_VERSION TRUE)

  if(DEFINED BUILD_VERSION)
    set(BUILD_VERSION_STR ", build: ${BUILD_VERSION}")
  endif()

  if (NOT NO_PRINT_VERSION)
      message(STATUS "Zephyr version: ${PROJECT_VERSION_STR} (${ZEPHYR_BASE})${BUILD_VERSION_STR}")
  endif()
endif()

# Cleanup convenience variables
unset(MAJOR)
unset(MINOR)
unset(PATCH)
unset(${proj_type}_VERSION_WITHOUT_TWEAK)

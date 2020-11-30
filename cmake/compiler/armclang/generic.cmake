# SPDX-License-Identifier: Apache-2.0

# Configures CMake for using ccac

find_program(CMAKE_C_COMPILER ${CROSS_COMPILE}armclang PATH ${TOOLCHAIN_HOME}/bin NO_DEFAULT_PATH)

#if("${ARCH}" STREQUAL "arm")
  set(triple arm-arm-none-eabi)
#endif()

set(CMAKE_SYSTEM_PROCESSOR cortex-m4)

set(CMAKE_C_FLAGS "-mcpu=cortex-m4")
set(CMAKE_CXX_FLAGS "-mcpu=cortex-m4")
set(CMAKE_C_LINK_FLAGS "--cpu=cortex-m4")
set(CMAKE_ASM_LINK_FLAGS "--cpu=cortex-m4")
set(CMAKE_C_COMPILER_TARGET   ${triple})
set(CMAKE_ASM_COMPILER_TARGET ${triple})
set(CMAKE_CXX_COMPILER_TARGET ${triple})


if(CMAKE_C_COMPILER STREQUAL CMAKE_C_COMPILER-NOTFOUND)
  message(FATAL_ERROR "Zephyr was unable to find the armclang compiler")
endif()

execute_process(
  COMMAND ${CMAKE_C_COMPILER} --version
  RESULT_VARIABLE ret
  OUTPUT_QUIET
  ERROR_QUIET
  )

if(ret)
  message(FATAL_ERROR "Executing the below command failed. Are permissions set correctly?
  '${CMAKE_C_COMPILER} --version'"
  )
endif()

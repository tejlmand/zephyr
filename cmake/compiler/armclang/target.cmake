# find the compilers for C, CPP, assembly
find_program(CMAKE_C_COMPILER ${CROSS_COMPILE}armclang PATH ${TOOLCHAIN_HOME} NO_DEFAULT_PATH)
find_program(CMAKE_CXX_COMPILER ${CROSS_COMPILE}armclang PATH ${TOOLCHAIN_HOME} NO_DEFAULT_PATH)
find_program(CMAKE_ASM_COMPILER ${CROSS_COMPILE}armclang PATH ${TOOLCHAIN_HOME} NO_DEFAULT_PATH)

# The CMAKE_REQUIRED_FLAGS variable is used by check_c_compiler_flag()
# (and other commands which end up calling check_c_source_compiles())
# to add additional compiler flags used during checking. These flags
# are unused during "real" builds of Zephyr source files linked into
# the final executable.
#
include(${ZEPHYR_BASE}/cmake/gcc-m-cpu.cmake)

list(APPEND TOOLCHAIN_C_FLAGS
  -fshort-enums
  )
list(APPEND TOOLCHAIN_LD_FLAGS
  -fshort-enums
  )

include(${ZEPHYR_BASE}/cmake/compiler/gcc/target_arm.cmake)

foreach(file_name include/stddef.h)
  execute_process(
    COMMAND ${CMAKE_C_COMPILER} --print-file-name=${file_name}
    OUTPUT_VARIABLE _OUTPUT
    )
  get_filename_component(_OUTPUT "${_OUTPUT}" DIRECTORY)
  string(REGEX REPLACE "\n" "" _OUTPUT ${_OUTPUT})

  list(APPEND NOSTDINC ${_OUTPUT})
endforeach()

foreach(isystem_include_dir ${NOSTDINC})
  list(APPEND isystem_include_flags -isystem ${isystem_include_dir})
endforeach()

# This libgcc code is partially duplicated in compiler/*/target.cmake
execute_process(
  COMMAND ${CMAKE_C_COMPILER} ${TOOLCHAIN_C_FLAGS} --print-libgcc-file-name
  OUTPUT_VARIABLE LIBGCC_FILE_NAME
  OUTPUT_STRIP_TRAILING_WHITESPACE
  )

get_filename_component(LIBGCC_DIR ${LIBGCC_FILE_NAME} DIRECTORY)

list(APPEND LIB_INCLUDE_DIR "-L\"${LIBGCC_DIR}\"")
if(LIBGCC_DIR)
  list(APPEND TOOLCHAIN_LIBS gcc)
endif()

set(CMAKE_REQUIRED_FLAGS -nostartfiles -nostdlib ${isystem_include_flags})
string(REPLACE ";" " " CMAKE_REQUIRED_FLAGS "${CMAKE_REQUIRED_FLAGS}")

# Load toolchain_cc-family macros

macro(toolchain_cc_nostdinc)
  if(NOT "${ARCH}" STREQUAL "posix")
    zephyr_compile_options( -nostdinc)
  endif()
endmacro()

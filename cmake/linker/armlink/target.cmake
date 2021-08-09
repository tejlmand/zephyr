# SPDX-License-Identifier: Apache-2.0

# In order to ensure that the armlink symbol name is correctly passed to
# gen_handles.py, we must first ensure that it is properly escaped.
# For Python to work, the `$` must be passed as `\$` on command line.
# In order to pass a single `\` to command line it must first be escaped, that is `\\`.
# In ninja build files, a `$` is not accepted but must be passed as `$$`.
# CMake, Python and Ninja combined results in `\\$$` in order to pass a sing `\$` to Python,
# so `$$` thus becomes: `\\$$\\$$`.
set_property(TARGET linker PROPERTY devices_start_symbol "Image\\$$\\$$device\\$$\\$$Base")

find_program(CMAKE_LINKER ${CROSS_COMPILE}armlink PATH ${TOOLCHAIN_HOME} NO_DEFAULT_PATH)

add_custom_target(armlink)

macro(toolchain_ld_base)
endmacro()

function(toolchain_ld_force_undefined_symbols)
  foreach(symbol ${ARGN})
    zephyr_link_libraries(--undefined=${symbol})
  endforeach()
endfunction()

macro(toolchain_ld_baremetal)
endmacro()

macro(configure_linker_script linker_script_gen linker_pass_define)
  if("${linker_pass_define}" STREQUAL "-DLINKER_ZEPHYR_PREBUILT")
    set(PASS 1)
  elseif("${linker_pass_define}" STREQUAL "-DLINKER_ZEPHYR_FINAL;-DLINKER_PASS2")
    set(PASS 2)
  endif()

  add_custom_command(
    OUTPUT ${linker_script_gen}
    COMMAND ${CMAKE_COMMAND}
      -DPASS=${PASS}
      -DMEMORY_REGIONS="$<TARGET_PROPERTY:linker,MEMORY_REGIONS>"
      -DGROUPS="$<TARGET_PROPERTY:linker,GROUPS>"
      -DSECTIONS="$<TARGET_PROPERTY:linker,SECTIONS>"
      -DSECTION_SETTINGS="$<TARGET_PROPERTY:linker,SECTION_SETTINGS>"
      -DSYMBOLS="$<TARGET_PROPERTY:linker,SYMBOLS>"
      ${STEERING_FILE_ARG}
      ${STEERING_C_ARG}
      -DOUT_FILE=${CMAKE_CURRENT_BINARY_DIR}/${linker_script_gen}
      -P ${ZEPHYR_BASE}/cmake/linker/armlink/scatter_script.cmake
  )
endmacro()

function(toolchain_ld_link_elf)
  cmake_parse_arguments(
    TOOLCHAIN_LD_LINK_ELF                                     # prefix of output variables
    ""                                                        # list of names of the boolean arguments
    "TARGET_ELF;OUTPUT_MAP;LINKER_SCRIPT"                     # list of names of scalar arguments
    "LIBRARIES_PRE_SCRIPT;LIBRARIES_POST_SCRIPT;DEPENDENCIES" # list of names of list arguments
    ${ARGN}                                                   # input args to parse
  )

  foreach(lib ${ZEPHYR_LIBS_PROPERTY})
    if(NOT ${lib} STREQUAL arch__arm__core__aarch32__cortex_m)
    list(APPEND ZEPHYR_LIBS_OBJECTS $<TARGET_OBJECTS:${lib}>)
    list(APPEND ZEPHYR_LIBS_OBJECTS $<TARGET_PROPERTY:${lib},LINK_LIBRARIES>)
    endif()
  endforeach()

  target_link_libraries(
    ${TOOLCHAIN_LD_LINK_ELF_TARGET_ELF}
    ${TOOLCHAIN_LD_LINK_ELF_LIBRARIES_PRE_SCRIPT}
    --scatter=${TOOLCHAIN_LD_LINK_ELF_LINKER_SCRIPT}
    ${TOOLCHAIN_LD_LINK_ELF_LIBRARIES_POST_SCRIPT}
    $<TARGET_OBJECTS:arch__arm__core__aarch32__cortex_m>
    --map --list=${TOOLCHAIN_LD_LINK_ELF_OUTPUT_MAP}
    ${ZEPHYR_LIBS_OBJECTS}
    kernel
    $<TARGET_OBJECTS:${OFFSETS_LIB}>
    --library_type=microlib
    --entry=__start
    "--keep=\"*.o(.init_*)\""
    "--keep=\"*.o(.device_*)\""
    ${TOOLCHAIN_LIBS_OBJECTS}

    ${TOOLCHAIN_LD_LINK_ELF_DEPENDENCIES}
  )
endfunction(toolchain_ld_link_elf)

include(${ZEPHYR_BASE}/cmake/linker/ld/target_base.cmake)
#include(${ZEPHYR_BASE}/cmake/linker/ld/target_baremetal.cmake)
include(${ZEPHYR_BASE}/cmake/linker/ld/target_cpp.cmake)
include(${ZEPHYR_BASE}/cmake/linker/ld/target_relocation.cmake)
include(${ZEPHYR_BASE}/cmake/linker/ld/target_configure.cmake)

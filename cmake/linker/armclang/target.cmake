# SPDX-License-Identifier: Apache-2.0

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
  set(STEERING_FILE)
  set(STEERING_C)
  set(STEERING_FILE_ARG)
  set(STEERING_C_ARG)
  if("${linker_pass_define}" STREQUAL "")
    set(PASS 1)
  elseif("${linker_pass_define}" STREQUAL "-DLINKER_PASS2")
    set(PASS 2)
    set(STEERING_FILE ${CMAKE_CURRENT_BINARY_DIR}/armlink_symbol_steering.steer)
    set(STEERING_C ${CMAKE_CURRENT_BINARY_DIR}/armlink_symbol_steering.c)
    set(STEERING_FILE_ARG "-DSTEERING_FILE=${STEERING_FILE}")
    set(STEERING_C_ARG "-DSTEERING_C=${STEERING_C}")
    message("=========== PASS 2 =============")
  endif()

  add_custom_command(
    OUTPUT ${linker_script_gen}
           ${STEERING_FILE}
           ${STEERING_C}
    COMMAND ${CMAKE_COMMAND}
      -DPASS=${PASS}
      -DMEMORY_REGIONS="$<TARGET_PROPERTY:linker_target,MEMORY_REGIONS>"
      -DSECTIONS="$<TARGET_PROPERTY:linker_target,SECTIONS>"
      -DSECTION_SETTINGS="$<TARGET_PROPERTY:linker_target,SECTION_SETTINGS>"
      -DSYMBOLS="$<TARGET_PROPERTY:linker_target,SYMBOLS>"
      ${STEERING_FILE_ARG}
      ${STEERING_C_ARG}
      -DOUT_FILE=${CMAKE_CURRENT_BINARY_DIR}/${linker_script_gen}
      -P ${ZEPHYR_BASE}/cmake/linker/template/scatter_script.cmake
  )

  if("${PASS}" EQUAL 1)
    add_library(armlink_steering OBJECT ${CMAKE_CURRENT_BINARY_DIR}/armlink_symbol_steering.c)
    target_link_libraries(armlink_steering PRIVATE zephyr_interface)
  endif()
#  add_custom_command(
#    OUTPUT ${linker_script_gen}
#    DEPENDS
#    ${LINKER_SCRIPT}
#    ${extra_dependencies}
#    # NB: 'linker_script_dep' will use a keyword that ends 'DEPENDS'
#    ${linker_script_dep}
#    COMMAND ${CMAKE_C_COMPILER}
#    --target=arm-arm-none-eabi
#    -x assembler-with-cpp
#    ${NOSYSDEF_CFLAG}
#    -MD -MF ${linker_script_gen}.dep -MT ${base_name}/${linker_script_gen}
#    -D_LINKER
#    -D_ASMLANGUAGE
#    ${current_includes}
#    ${current_defines}
#    ${linker_pass_define}
#    -E ${LINKER_SCRIPT}
#    -P # Prevent generation of debug `#line' directives.
#    -o ${linker_script_gen}
#    VERBATIM
#    WORKING_DIRECTORY ${PROJECT_BINARY_DIR}
#    COMMAND_EXPAND_LISTS
#  )
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
#    ${TOPT}
    --scatter=${TOOLCHAIN_LD_LINK_ELF_LINKER_SCRIPT}
    ${TOOLCHAIN_LD_LINK_ELF_LIBRARIES_POST_SCRIPT}
    $<TARGET_OBJECTS:arch__arm__core__aarch32__cortex_m>
#    ${LINKERFLAGPREFIX},-Map=${TOOLCHAIN_LD_LINK_ELF_OUTPUT_MAP}
    --map --list=${TOOLCHAIN_LD_LINK_ELF_OUTPUT_MAP}
#    ${LINKERFLAGPREFIX},--whole-archive
    ${ZEPHYR_LIBS_OBJECTS}
#    ${LINKERFLAGPREFIX},--no-whole-archive
    kernel
    $<TARGET_OBJECTS:${OFFSETS_LIB}>
    $<TARGET_OBJECTS:armlink_steering>
    --edit=${CMAKE_CURRENT_BINARY_DIR}/armlink_symbol_steering.steer
    --library_type=microlib
    --entry=__start
    "--keep=\"*.o(.init_*)\""
    "--keep=\"*.o(.device_*)\""
    # Resolving symbols using generated steering files will emit the warnings 6331 and 6332.
    # Steering files are used because we want to be able to use `__device_end` instead of `Image$$device$$Limit`.
    # Thus silence those two warnings.
    --diag_suppress=6331,6332,6314
#  ${LIB_INCLUDE_DIR}
  #  -L${PROJECT_BINARY_DIR}
    ${TOOLCHAIN_LIBS_OBJECTS}

    ${TOOLCHAIN_LD_LINK_ELF_DEPENDENCIES}
  )
endfunction(toolchain_ld_link_elf)

include(${ZEPHYR_BASE}/cmake/linker/ld/target_base.cmake)
#include(${ZEPHYR_BASE}/cmake/linker/ld/target_baremetal.cmake)
include(${ZEPHYR_BASE}/cmake/linker/ld/target_cpp.cmake)
include(${ZEPHYR_BASE}/cmake/linker/ld/target_relocation.cmake)
include(${ZEPHYR_BASE}/cmake/linker/ld/target_configure.cmake)

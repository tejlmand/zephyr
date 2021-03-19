# SPDX-License-Identifier: Apache-2.0

find_program(CMAKE_LINKER ${CROSS_COMPILE}armlink PATH ${TOOLCHAIN_HOME} NO_DEFAULT_PATH)

macro(toolchain_ld_base)
endmacro()

function(toolchain_ld_force_undefined_symbols)
  foreach(symbol ${ARGN})
    zephyr_link_libraries(${LINKERFLAGPREFIX},-u,${symbol})
  endforeach()
endfunction()

macro(toolchain_ld_baremetal)
endmacro()

macro(configure_linker_script linker_script_gen linker_pass_define)
  set(extra_dependencies ${ARGN})
  zephyr_get_include_directories_for_lang(C current_includes)
  get_filename_component(base_name ${CMAKE_CURRENT_BINARY_DIR} NAME)
  get_property(current_defines GLOBAL PROPERTY PROPERTY_LINKER_SCRIPT_DEFINES)

  add_custom_command(
    OUTPUT ${linker_script_gen}
    DEPENDS
    ${LINKER_SCRIPT}
    ${extra_dependencies}
    # NB: 'linker_script_dep' will use a keyword that ends 'DEPENDS'
    ${linker_script_dep}
    COMMAND ${CMAKE_C_COMPILER}
    --target=arm-arm-none-eabi
    -x assembler-with-cpp
    ${NOSYSDEF_CFLAG}
    -MD -MF ${linker_script_gen}.dep -MT ${base_name}/${linker_script_gen}
    -D_LINKER
    -D_ASMLANGUAGE
    ${current_includes}
    ${current_defines}
    ${linker_pass_define}
    -E ${LINKER_SCRIPT}
    -P # Prevent generation of debug `#line' directives.
    -o ${linker_script_gen}
    VERBATIM
    WORKING_DIRECTORY ${PROJECT_BINARY_DIR}
    COMMAND_EXPAND_LISTS
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

  target_link_libraries(
    ${TOOLCHAIN_LD_LINK_ELF_TARGET_ELF}
    ${TOOLCHAIN_LD_LINK_ELF_LIBRARIES_PRE_SCRIPT}
#    ${TOPT}
    ${TOOLCHAIN_LD_LINK_ELF_LINKER_SCRIPT}
    ${TOOLCHAIN_LD_LINK_ELF_LIBRARIES_POST_SCRIPT}

    ${LINKERFLAGPREFIX},-Map=${TOOLCHAIN_LD_LINK_ELF_OUTPUT_MAP}
    ${LINKERFLAGPREFIX},--whole-archive
    ${ZEPHYR_LIBS_PROPERTY}
    ${LINKERFLAGPREFIX},--no-whole-archive
    kernel
    $<TARGET_OBJECTS:${OFFSETS_LIB}>
    ${LIB_INCLUDE_DIR}
    -L${PROJECT_BINARY_DIR}
    ${TOOLCHAIN_LIBS}

    ${TOOLCHAIN_LD_LINK_ELF_DEPENDENCIES}
  )
endfunction(toolchain_ld_link_elf)

include(${ZEPHYR_BASE}/cmake/linker/ld/target_base.cmake)
include(${ZEPHYR_BASE}/cmake/linker/ld/target_baremetal.cmake)
include(${ZEPHYR_BASE}/cmake/linker/ld/target_cpp.cmake)
include(${ZEPHYR_BASE}/cmake/linker/ld/target_relocation.cmake)
include(${ZEPHYR_BASE}/cmake/linker/ld/target_configure.cmake)

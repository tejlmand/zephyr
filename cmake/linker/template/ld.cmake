
add_custom_target(linker_target
  COMMAND ${CMAKE_COMMAND}
    -DMEMORY_REGIONS="$<TARGET_PROPERTY:linker_target,MEMORY_REGIONS>"
    -DSECTIONS="$<TARGET_PROPERTY:linker_target,SECTIONS>"
    -DSECTION_SETTINGS="$<TARGET_PROPERTY:linker_target,SECTION_SETTINGS>"
    -P ${CMAKE_CURRENT_LIST_DIR}/ld_script.cmake
)

add_custom_target(scatter_target
  COMMAND ${CMAKE_COMMAND} -E echo
    -DMEMORY_REGIONS="$<TARGET_PROPERTY:linker_target,MEMORY_REGIONS>"
    -DSECTIONS="$<TARGET_PROPERTY:linker_target,SECTIONS>"
    -DSECTION_SETTINGS="$<TARGET_PROPERTY:linker_target,SECTION_SETTINGS>"
    -DSYMBOLS="$<TARGET_PROPERTY:linker_target,SYMBOLS>"
    -P ${CMAKE_CURRENT_LIST_DIR}/scatter_script.cmake
  COMMAND ${CMAKE_COMMAND}
    -DMEMORY_REGIONS="$<TARGET_PROPERTY:linker_target,MEMORY_REGIONS>"
    -DSECTIONS="$<TARGET_PROPERTY:linker_target,SECTIONS>"
    -DSECTION_SETTINGS="$<TARGET_PROPERTY:linker_target,SECTION_SETTINGS>"
    -DSYMBOLS="$<TARGET_PROPERTY:linker_target,SYMBOLS>"
    -P ${CMAKE_CURRENT_LIST_DIR}/scatter_script.cmake
)




macro(zephyr_linker_memory_ifdef feature_toggle)
  if(${${feature_toggle}})
    zephyr_linker_memory(${ARGN})
  endif()
endmacro()

macro(zephyr_linker_section_ifdef feature_toggle)
  if(${${feature_toggle}})
    zephyr_linker_section(${ARGN})
  endif()
endmacro()

macro(zephyr_linker_property_append list arguments)
  foreach(arg ${arguments})
    if(DEFINED ${list}_${arg})
      list(APPEND ${list} ${arg} "${${list}_${arg}}")
    endif()
  endforeach()
endmacro()

#
# Funtion to round number to next power of two.
#
# Example:
# set(test 2)
# pow2round(test)
# # test is still 2
#
# set(test 5)
# pow2round(test)
# # test is now 8
#
# Arguments:
# n   = Variable containing the number to round
function(pow2round n)
  math(EXPR x "${${n}} & (${${n}} - 1)")
  if(${x} EQUAL 0)
    return()
  endif()

  math(EXPR ${n} "${${n}} | (${${n}} >> 1)")
  math(EXPR ${n} "${${n}} | (${${n}} >> 2)")
  math(EXPR ${n} "${${n}} | (${${n}} >> 4)")
  math(EXPR ${n} "${${n}} | (${${n}} >> 8)")
  math(EXPR ${n} "${${n}} | (${${n}} >> 16)")
  math(EXPR ${n} "${${n}} | (${${n}} >> 32)")
  math(EXPR ${n} "${${n}} + 1")
  set(${n} ${${n}} PARENT_SCOPE)
endfunction()


function(zephyr_linker_memory)
  set(single_args "NAME;FLAGS;START;SIZE")
  cmake_parse_arguments(MEMORY "" "${single_args}" "" ${ARGN})

  if(MEMORY_UNPARSED_ARGUMENTS)
    message(FATAL_ERROR "zephyr_linker_memory(${ARGV0} ...) given unknown arguments: ${MEMORY_UNPARSED_ARGUMENTS}")
  endif()

  zephyr_linker_property_append("MEMORY" "${single_args}")

  string(REPLACE ";" "\;" MEMORY "${MEMORY}")
  set_property(TARGET   linker_target
               APPEND PROPERTY MEMORY_REGIONS "{${MEMORY}}"
  )
endfunction()

function(zephyr_linker_symbol)
  set(single_args "EXPR;SUBALIGN;SYMBOL")
  cmake_parse_arguments(SYMBOL "" "${single_args}" "" ${ARGN})

  if(SECTION_UNPARSED_ARGUMENTS)
    message(WARNING "zephyr_linker_symbol(${ARGV0} ...) given unknown arguments: ${SECTION_UNPARSED_ARGUMENTS}")
  endif()
  zephyr_linker_property_append("SYMBOL" "${single_args}")

  string(REPLACE ";" "\;" SYMBOL "${SYMBOL}")
  set_property(TARGET   linker_target
               APPEND PROPERTY SYMBOLS "{${SYMBOL}}"
  )
endfunction()

function(zephyr_linker_section)
  set(options "NOINPUT;NOINIT")
  set(single_args "NAME;ADDRESS;TYPE;ALIGN;SUBALIGN;VMA;LMA;FLAGS")
  set(multi_args "PASS")
  cmake_parse_arguments(SECTION "${options}" "${single_args}" "${multi_args}" ${ARGN})

  if(SECTION_UNPARSED_ARGUMENTS)
    message(WARNING "zephyr_linker_section(${ARGV0} ...) given unknown arguments: ${SECTION_UNPARSED_ARGUMENTS}")
  endif()
  zephyr_linker_property_append("SECTION" "${single_args}")
  zephyr_linker_property_append("SECTION" "${options}")
  zephyr_linker_property_append("SECTION" "${multi_args}")

  string(REPLACE ";" "\;" SECTION "${SECTION}")
  print(SECTION)
  set_property(TARGET   linker_target
               APPEND PROPERTY SECTIONS "{${SECTION}}"
  )
endfunction()
function(zephyr_linker_section_configure)
  set(options     "ANY;KEEP;FIRST")
  set(single_args "SECTION;;ALIGN;SORT;PRIO")
  set(multi_args  "FLAGS;INPUT;SYMBOLS")
  cmake_parse_arguments(SECTION "${options}" "${single_args}" "${multi_args}" ${ARGN})

  if(SECTION_UNPARSED_ARGUMENTS)
    message(FATAL_ERROR "zephyr_linker_section_configure(${ARGV0} ...) given unknown arguments: ${SECTION_UNPARSED_ARGUMENTS}")
  endif()

  if(DEFINED SECTION_SYMBOLS)
    list(LENGTH SECTION_SYMBOLS symbols_count)
    print(symbols_count)
    if(${symbols_count} GREATER 2)
      message(FATAL_ERROR "zephyr_linker_section_configure(SYMBOLS [start_sym [end_sym]]) takes maximum two symbol names (start and end).")

    endif()
  endif()

  zephyr_linker_property_append("SECTION" "${single_args}")
  zephyr_linker_property_append("SECTION" "${options}")
  zephyr_linker_property_append("SECTION" "${multi_args}")

  string(REPLACE ";" "\;" SECTION "${SECTION}")
  set_property(TARGET   linker_target
               APPEND PROPERTY SECTION_SETTINGS "{${SECTION}}"
  )
endfunction()

function(zephyr_iterable_section)
  # ToDo - Should we use ROM, RAM, etc as arguments ?
  set(options     "")
  set(single_args "NAME;SUBALIGN;VMA;LMA")
  set(multi_args  "")
  cmake_parse_arguments(SECTION "${options}" "${single_args}" "${multi_args}" ${ARGN})

  if(NOT DEFINED SECTION_NAME)
    message(FATAL_ERROR "zephyr_iterable_section(${ARGV0} ...) missing required argument: NAME")
  endif()

  if(NOT DEFINED SECTION_SUBALIGN)
    message(FATAL_ERROR "zephyr_iterable_section(${ARGV0} ...) missing required argument: SUBALIGN")
  endif()

  zephyr_linker_section(
    NAME ${SECTION_NAME}_area
    VMA ${SECTION_VMA} LMA ${SECTION_LMA} FLASH NOINPUT
    SUBALIGN ${SECTION_SUBALIGN}
  )
  zephyr_linker_section_configure(
    SECTION ${SECTION_NAME}_area
    INPUT ".${SECTION_NAME}.static.*"
    SYMBOLS _${SECTION_NAME}_list_start _${SECTION_NAME}_list_end
    KEEP SORT NAME
  )
endfunction()

function(zephyr_linker_section_obj_level)
  set(single_args "SECTION;LEVEL")
  cmake_parse_arguments(OBJ "" "${single_args}" "" ${ARGN})

  if(NOT DEFINED OBJ_SECTION)
    message(FATAL_ERROR "zephyr_linker_section_obj_level(${ARGV0} ...) missing required argument: SECTION")
  endif()

  if(NOT DEFINED OBJ_LEVEL)
    message(FATAL_ERROR "zephyr_linker_section_obj_level(${ARGV0} ...) missing required argument: LEVEL")
  endif()

  zephyr_linker_section_configure(
    SECTION ${OBJ_SECTION}
    INPUT ".${OBJ_SECTION}_${OBJ_LEVEL}[0-9]*"
    SYMBOLS __${OBJ_SECTION}_${OBJ_LEVEL}_start
    KEEP SORT NAME
  )
  zephyr_linker_section_configure(
    SECTION ${OBJ_SECTION}
    INPUT ".${OBJ_SECTION}_${OBJ_LEVEL}[1-9][0-9]*"
    KEEP SORT NAME
  )
endfunction()


set_ifndef(region_min_align CONFIG_CUSTOM_SECTION_MIN_ALIGN_SIZE)

# Set alignment to CONFIG_ARM_MPU_REGION_MIN_ALIGN_AND_SIZE if not set above
# to make linker section alignment comply with MPU granularity.
set_ifndef(region_min_align CONFIG_ARM_MPU_REGION_MIN_ALIGN_AND_SIZE)

# If building without MPU support, use default 4-byte alignment.. if not set abve.
set_ifndef(region_min_align 4)



math(EXPR FLASH_ADDR "${CONFIG_FLASH_BASE_ADDRESS} + ${CONFIG_FLASH_LOAD_OFFSET}" OUTPUT_FORMAT HEXADECIMAL)
math(EXPR FLASH_SIZE "${CONFIG_FLASH_SIZE} * 1024 - ${CONFIG_FLASH_LOAD_OFFSET}" OUTPUT_FORMAT HEXADECIMAL)
set(RAM_ADDR ${CONFIG_SRAM_BASE_ADDRESS})
math(EXPR RAM_SIZE "${CONFIG_SRAM_SIZE} * 1024" OUTPUT_FORMAT HEXADECIMAL)
math(EXPR IDT_ADDR "${RAM_ADDR} + ${RAM_SIZE}" OUTPUT_FORMAT HEXADECIMAL)

zephyr_linker_memory(NAME FLASH    FLAGS ro START ${FLASH_ADDR} SIZE ${FLASH_SIZE})
zephyr_linker_memory(NAME RAM      FLAGS rw START ${RAM_ADDR}   SIZE ${RAM_SIZE})
zephyr_linker_memory(NAME IDT_LIST FLAGS rw START ${IDT_ADDR}   SIZE 2K)

#zephyr_region(NAME FLASH ALIGN ${region_min_align})
#zephyr_region(NAME RAM ALIGN ${region_min_align})

# should go to a relocation.cmake - from include/linker/rel-sections.ld - start
zephyr_linker_section(NAME  .rel.plt  HIDDEN)
zephyr_linker_section(NAME  .rela.plt HIDDEN)
zephyr_linker_section(NAME  .rel.dyn)
zephyr_linker_section(NAME  .rela.dyn)
# should go to a relocation.cmake - from include/linker/rel-sections.ld - end

# Discard sections for GNU ld.
zephyr_linker_section_configure(SECTION /DISCARD/ INPUT ".plt")
zephyr_linker_section_configure(SECTION /DISCARD/ INPUT ".iplt")
zephyr_linker_section_configure(SECTION /DISCARD/ INPUT ".got.plt")
zephyr_linker_section_configure(SECTION /DISCARD/ INPUT ".igot.plt")
zephyr_linker_section_configure(SECTION /DISCARD/ INPUT ".got")
zephyr_linker_section_configure(SECTION /DISCARD/ INPUT ".igot")






if(DEFINED CONFIG_ROM_START_OFFSET
   AND (DEFINED CONFIG_ARM OR DEFINED CONFIG_X86 OR DEFINED CONFIG_SOC_OPENISA_RV32M1_RISCV32)
)
  zephyr_linker_section(NAME .rom_start ADDRESS ${CONFIG_ROM_START_OFFSET} VMA FLASH NOINPUT)
else()
  zephyr_linker_section(NAME .rom_start VMA FLASH NOINPUT)
endif()

zephyr_linker_section(NAME .text         VMA FLASH)

# ToDo: Find out again where section '.extra' originated before re-activating.
#zephyr_linker_section(NAME .extra        VMA RAM LMA FLASH SUBALIGN 8)
#zephyr_linker_section(NAME .bss          VMA RAM LMA RAM TYPE NOLOAD)
#zephyr_linker_section_ifdef(CONFIG_DEBUG_THREAD_INFO NAME zephyr_dbg_info VMA FLASH)

#zephyr_linker_section(NAME .ARM.exidx VMA RAM TYPE NOLOAD)
#zephyr_linker_section_configure_ifdef(GNU SECTION .ARM.exidx INPUT ".ARM.exidx* gnu.linkonce.armexidx.*")

zephyr_linker_section_configure(SECTION .rel.plt  INPUT ".rel.iplt")
zephyr_linker_section_configure(SECTION .rela.plt INPUT ".rela.iplt")

zephyr_linker_section_configure(SECTION text INPUT ".TEXT.*")
zephyr_linker_section_configure(SECTION text INPUT ".gnu.linkonce.t.*")

zephyr_linker_section_configure(SECTION text INPUT ".glue_7t")
zephyr_linker_section_configure(SECTION text INPUT ".glue_7")
zephyr_linker_section_configure(SECTION text INPUT ".vfp11_veneer")
zephyr_linker_section_configure(SECTION text INPUT ".v4_bx")

if(CONFIG_CPLUSPLUS)
  zephyr_linker_section(NAME .ARM.extab VMA FLASH)
  zephyr_linker_section_configure(SECTION .ARM.extab INPUT ".gnu.linkonce.armextab.*")
endif()

zephyr_linker_section(NAME .ARM.exidx VMA FLASH)
# Here the original linker would check for __GCC_LINKER_CMD__, need to check toolchain linker ?
#if(__GCC_LINKER_CMD__)
  zephyr_linker_section_configure(SECTION .ARM.exidx INPUT ".gnu.linkonce.armexidx.*")
#endif()


include(${CMAKE_CURRENT_LIST_DIR}/common-rom.cmake)
include(${CMAKE_CURRENT_LIST_DIR}/thread-local-storage.cmake)

zephyr_linker_section(NAME .rodata LMA FLASH)
zephyr_linker_section_configure(SECTION .rodata INPUT ".gnu.linkonce.r.*")
if(CONFIG_USERSPACE AND CONFIG_XIP)
  zephyr_linker_section_configure(SECTION .rodata INPUT ".kobject_data.rodata*")
endif()
zephyr_linker_section_configure(SECTION .rodata ALIGN 4)

# ToDo - . = ALIGN(_region_min_align);
# Symbol to add _image_ram_start = .;

# This comes from ramfunc.ls, via snippets-ram-sections.ld
zephyr_linker_section(NAME .ramfunc VMA RAM LMA FLASH SUBALIGN 8)
# MPU_ALIGN(_ramfunc_ram_size);
# } GROUP_DATA_LINK_IN(RAMABLE_REGION, ROMABLE_REGION)
#_ramfunc_ram_size = _ramfunc_ram_end - _ramfunc_ram_start;
#_ramfunc_rom_start = LOADADDR(.ramfunc);

# ToDo - handle if(CONFIG_USERSPACE)

zephyr_linker_section(NAME .data VMA RAM LMA FLASH)
#zephyr_linker_section_configure(SECTION .data SYMBOLS __data_ram_start)
zephyr_linker_section_configure(SECTION .data INPUT ".kernel.*")
#zephyr_linker_section_configure(SECTION .data SYMBOLS __data_ram_end)

include(${CMAKE_CURRENT_LIST_DIR}/common-ram.cmake)
#include(kobject.ld)

if(NOT CONFIG_USERSPACE)
  zephyr_linker_section(NAME .bss VMA RAM LMA FLASH TYPE NOLOAD)
#  zephyr_linker_section(NAME .bss VMA RAM LMA RAM TYPE NOLOAD)
  # For performance, BSS section is assumed to be 4 byte aligned and
  # a multiple of 4 bytes
#        . = ALIGN(4);
#	__kernel_ram_start = .;
  zephyr_linker_section_configure(SECTION .bss INPUT COMMON)
  zephyr_linker_section_configure(SECTION .bss INPUT ".kernel_bss.*")
  # As memory is cleared in words only, it is simpler to ensure the BSS
  # section ends on a 4 byte boundary. This wastes a maximum of 3 bytes.
  zephyr_linker_section_configure(SECTION .bss ALIGN 4)
  # GROUP_DATA_LINK_IN(RAMABLE_REGION, RAMABLE_REGION)

  zephyr_linker_section(NAME .noinit VMA RAM LMA FLASH TYPE NOLOAD NOINIT)
  # This section is used for non-initialized objects that
  # will not be cleared during the boot process.
  zephyr_linker_section_configure(SECTION .noinit INPUT ".kernel_noinit.*")
  # GROUP_LINK_IN(RAMABLE_REGION)
endif()

# _image_ram_end = .;
# _end = .; /* end of image */
#
# __kernel_ram_end = RAM_ADDR + RAM_SIZE;
# __kernel_ram_size = __kernel_ram_end - __kernel_ram_start;
#zephyr_linker_symbol(SYMBOL __kernel_ram_end  EXPR "${RAM_ADDR} + ${RAM_SIZE}")
zephyr_linker_symbol(SYMBOL __kernel_ram_end  EXPR "(${RAM_ADDR} + ${RAM_SIZE})")
zephyr_linker_symbol(SYMBOL __kernel_ram_size EXPR "(%__kernel_ram_end% - %__bss_start%)")
zephyr_linker_symbol(SYMBOL _image_ram_start  EXPR "(${RAM_ADDR})" SUBALIGN 32) # ToDo calculate 32 correctly

set(VECTOR_ALIGN 4)
if(CONFIG_CPU_CORTEX_M_HAS_VTOR)
  math(EXPR VECTOR_ALIGN "4 * (16 + ${CONFIG_NUM_IRQS})")
  if(${VECTOR_ALIGN} LESS 128)
    set(VECTOR_ALIGN 128)
  else()
    pow2round(VECTOR_ALIGN)
  endif()
endif()

#zephyr_linker_section_configure(SECTION rom_start INPUT ".exc_vector_table" KEEP FIRST)
# To be moved to: ./arch/arm/core/aarch32/CMakeLists.txt or similar - start
zephyr_linker_section_configure(
  SECTION .rom_start
  INPUT ".exc_vector_table*"
        ".gnu.linkonce.irq_vector_table*"
        ".vectors"
  KEEP FIRST
  SYMBOLS _vector_start _vector_end
  ALIGN ${VECTOR_ALIGN}
  PRIO 0
)

# Should this be GNU only ?
# Same symbol is used in code as _IRQ_VECTOR_TABLE_SECTION_NAME, see sections.h
#zephyr_linker_section_configure(SECTION .rom_start INPUT ".gnu.linkonce.irq_vector_table*" KEEP PRIO 1)
#zephyr_linker_section_configure(SECTION .rom_start INPUT ".vectors" KEEP PRIO 2)
#zephyr_linker_section_configure(SECTION .rom_start SYMBOLS _vector_end PRIO 3)
# To be moved to: ./arch/arm/core/aarch32/CMakeLists.txt or similar - end

# armlink specific flags
zephyr_linker_section_configure(SECTION .text ANY FLAGS "+RO" "+XO")
zephyr_linker_section_configure(SECTION .data ANY FLAGS "+RW" "+ZI")


include(${CMAKE_CURRENT_LIST_DIR}/debug-sections.cmake)

#$<GENEX_EVAL:$<   $<JOIN:$<TARGET_PROPERTY:linker_target,MEMORY_REGIONS>,>
#-I$<JOIN:$<TARGET_PROPERTY:INCLUDE_DIRECTORIES>, -I>
#
#
#foreach(region MEMORY_REGIONS)
#  for
#  set(MEMORY_REGION_LINKER
#    ""
#
#
#  )
#endforeach()
#
#set(MEMORY
#"MEMORY"
#"{"
#$
#"}"
#)
#
#

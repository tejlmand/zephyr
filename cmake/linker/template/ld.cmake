
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
    -P ${CMAKE_CURRENT_LIST_DIR}/scatter_script.cmake
  COMMAND ${CMAKE_COMMAND}
    -DMEMORY_REGIONS="$<TARGET_PROPERTY:linker_target,MEMORY_REGIONS>"
    -DSECTIONS="$<TARGET_PROPERTY:linker_target,SECTIONS>"
    -DSECTION_SETTINGS="$<TARGET_PROPERTY:linker_target,SECTION_SETTINGS>"
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
    if(${list}_${arg})
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

function(zephyr_linker_section)
  set(single_args "NAME;ADDRESS;TYPE;ALIGN;SUBALIGN;VMA;LMA;FLAGS")
  cmake_parse_arguments(SECTION "" "${single_args}" "" ${ARGN})

  if(REGION_UNPARSED_ARGUMENTS)
    message(FATAL_ERROR "zephyr_linker_section(${ARGV0} ...) given unknown arguments: ${SECTION_UNPARSED_ARGUMENTS}")
  endif()

  zephyr_linker_property_append("SECTION" "${single_args}")

  string(REPLACE ";" "\;" SECTION "${SECTION}")
  set_property(TARGET   linker_target
               APPEND PROPERTY SECTIONS "{${SECTION}}"
  )
endfunction()

function(zephyr_linker_section_configure)
  set(options     "ANY;KEEP;FIRST")
  set(single_args "SECTION;INPUT;SYMBOL;ALIGN")
  set(multi_args  "FLAGS")
  cmake_parse_arguments(SECTION "${options}" "${single_args}" "${multi_args}" ${ARGN})

  if(REGION_UNPARSED_ARGUMENTS)
    message(FATAL_ERROR "zephyr_linker_section_configure(${ARGV0} ...) given unknown arguments: ${SECTION_UNPARSED_ARGUMENTS}")
  endif()

  zephyr_linker_property_append("SECTION" "${single_args}")
  zephyr_linker_property_append("SECTION" "${options}")
  zephyr_linker_property_append("SECTION" "${multi_args}")

  string(REPLACE ";" "\;" SECTION "${SECTION}")
  set_property(TARGET   linker_target
               APPEND PROPERTY SECTION_SETTINGS "{${SECTION}}"
  )
endfunction()

zephyr_linker_memory(NAME FLASH FLAGS ro START "0x0" SIZE 1M)
zephyr_linker_memory(NAME RAM   FLAGS rw START "0x20000000" SIZE 1K)

zephyr_linker_section(NAME .rom_start    VMA FLASH)
zephyr_linker_section(NAME .text         VMA FLASH)
zephyr_linker_section(NAME .data         VMA RAM LMA FLASH)
zephyr_linker_section(NAME .extra        VMA RAM LMA FLASH SUBALIGN 8)
zephyr_linker_section(NAME .bss          VMA RAM LMA FLASH TYPE NOLOAD)
#zephyr_linker_section(NAME .bss          VMA RAM LMA RAM TYPE NOLOAD)
zephyr_linker_section(NAME .k_timer_area VMA RAM SUBALIGN 4)
zephyr_linker_section_ifdef(CONFIG_DEBUG_THREAD_INFO NAME zephyr_dbg_info VMA FLASH)

#zephyr_linker_section(NAME .ARM.exidx VMA RAM TYPE NOLOAD)
#zephyr_linker_section_configure_ifdef(GNU SECTION .ARM.exidx INPUT ".ARM.exidx* gnu.linkonce.armexidx.*")


zephyr_linker_section_configure(SECTION zephyr_dbg_info INPUT ".dbg_thread_info" KEEP)

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
zephyr_linker_section_configure(
  SECTION .rom_start
  INPUT ".exc_vector_table*"
  KEEP FIRST
  SYMBOL _vector_start
  ALIGN ${VECTOR_ALIGN}
)

# Should this be GNU only ?
# Same symbol is used in code as _IRQ_VECTOR_TABLE_SECTION_NAME, see sections.h
zephyr_linker_section_configure(SECTION .rom_start INPUT ".gnu.linkonce.irq_vector_table*" KEEP)
zephyr_linker_section_configure(SECTION .rom_start INPUT ".vectors" KEEP)

# armlink specific flags
zephyr_linker_section_configure(SECTION .text ANY FLAGS "+RO" "+XO")
zephyr_linker_section_configure(SECTION .data ANY FLAGS "+RW" "+ZI")

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

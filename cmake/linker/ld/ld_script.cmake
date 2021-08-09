# ToDo:
# - Ensure LMA / VMA sections are correctly grouped similar to scatter file creation.
cmake_minimum_required(VERSION 3.18)

set(SORT_TYPE_NAME SORT_BY_NAME)

function(system_to_string)
  cmake_parse_arguments(STRING "" "OBJECT;STRING" "" ${ARGN})

  get_property(name    GLOBAL PROPERTY ${STRING_OBJECT}_NAME)
  get_property(regions GLOBAL PROPERTY ${STRING_OBJECT}_REGIONS)
  get_property(format  GLOBAL PROPERTY ${STRING_OBJECT}_FORMAT)

  set(${STRING_STRING} "OUTPUT_FORMAT(\"${format}\")\n\n")

  set(${STRING_STRING} "${${STRING_STRING}}MEMORY\n{\n")
  foreach(region ${regions})
    get_property(name    GLOBAL PROPERTY ${region}_NAME)
    get_property(address GLOBAL PROPERTY ${region}_ADDRESS)
    get_property(flags   GLOBAL PROPERTY ${region}_FLAGS)
    get_property(size    GLOBAL PROPERTY ${region}_SIZE)

    if(DEFINED flags)
      set(flags "(${flags})")
    endif()

    if(DEFINED address)
      set(start ": ORIGIN = (${address})")
    endif()

    if(DEFINED size)
      set(size ", LENGTH = (${size})")
    endif()
    set(memory_region "  ${name} ${flags} ${start}${size}")

    set(${STRING_STRING} "${${STRING_STRING}}${memory_region}\n")
  endforeach()

  set(${STRING_STRING} "${${STRING_STRING}}}\n\n")

  set(${STRING_STRING} "${${STRING_STRING}}SECTIONS\n{")
  foreach(region ${regions})
    to_string(OBJECT ${region} STRING ${STRING_STRING})
  endforeach()

  get_property(sections GLOBAL PROPERTY ${STRING_OBJECT}_SECTIONS_FIXED)
  foreach(section ${sections})
    to_string(OBJECT ${section} STRING ${STRING_STRING})
  endforeach()

  get_property(sections GLOBAL PROPERTY ${STRING_OBJECT}_SECTIONS)
  foreach(section ${sections})
    to_string(OBJECT ${section} STRING ${STRING_STRING})
  endforeach()

  set(${STRING_STRING} "${${STRING_STRING}}\n}\n" PARENT_SCOPE)
endfunction()

function(symbol_to_string)
  cmake_parse_arguments(STRING "" "SYMBOL;STRING" "" ${ARGN})

  get_property(name     GLOBAL PROPERTY ${STRING_SYMBOL}_NAME)
  get_property(expr     GLOBAL PROPERTY ${STRING_SYMBOL}_EXPR)
  get_property(size     GLOBAL PROPERTY ${STRING_SYMBOL}_SIZE)
  get_property(symbol   GLOBAL PROPERTY ${STRING_SYMBOL}_SYMBOL)
  get_property(subalign GLOBAL PROPERTY ${STRING_SYMBOL}_SUBALIGN)

  string(REPLACE "\\" "" expr "${expr}")
  string(REGEX MATCHALL "%([^%]*)%" match_res ${expr})

  foreach(match ${match_res})
    string(REPLACE "%" "" match ${match})
    string(REPLACE "%${match}%" "${match}" expr ${expr})
  endforeach()

  set(${STRING_STRING} "${${STRING_STRING}}\n${symbol} = ${expr};\n" PARENT_SCOPE)
endfunction()

function(group_to_string)
  cmake_parse_arguments(STRING "" "OBJECT;STRING" "" ${ARGN})

  get_property(type GLOBAL PROPERTY ${STRING_OBJECT}_OBJ_TYPE)
  if(${type} STREQUAL REGION)
    get_property(address GLOBAL PROPERTY ${STRING_OBJECT}_ADDRESS)
    set(${STRING_STRING} "${${STRING_STRING}}\n  . = ${address};\n\n")
  else()
    get_property(name GLOBAL PROPERTY ${STRING_OBJECT}_NAME)
    string(TOLOWER ${name} name)
    set(${STRING_STRING} "${${STRING_STRING}}\n  __${name}_start = .;\n")
  endif()

  get_property(sections GLOBAL PROPERTY ${STRING_OBJECT}_SECTIONS_FIXED)
  foreach(section ${sections})
    to_string(OBJECT ${section} STRING ${STRING_STRING})
  endforeach()

  get_property(groups GLOBAL PROPERTY ${STRING_OBJECT}_GROUPS)
  foreach(group ${groups})
    to_string(OBJECT ${group} STRING ${STRING_STRING})
  endforeach()

  get_property(sections GLOBAL PROPERTY ${STRING_OBJECT}_SECTIONS)
  foreach(section ${sections})
    to_string(OBJECT ${section} STRING ${STRING_STRING})
  endforeach()

  get_parent(OBJECT ${STRING_OBJECT} PARENT parent TYPE SYSTEM)
  get_property(regions GLOBAL PROPERTY ${parent}_REGIONS)
  list(REMOVE_ITEM regions ${STRING_OBJECT})
  foreach(region ${regions})
    if(${type} STREQUAL REGION)
      get_property(address GLOBAL PROPERTY ${region}_ADDRESS)
      set(${STRING_STRING} "${${STRING_STRING}}\n  . = ${address};\n\n")
    endif()

    get_property(vma GLOBAL PROPERTY ${region}_NAME)
    get_property(sections GLOBAL PROPERTY ${STRING_OBJECT}_${vma}_SECTIONS_FIXED)
    foreach(section ${sections})
      to_string(OBJECT ${section} STRING ${STRING_STRING})
    endforeach()

    get_property(groups GLOBAL PROPERTY ${STRING_OBJECT}_${vma}_GROUPS)
    foreach(group ${groups})
      to_string(OBJECT ${group} STRING ${STRING_STRING})
    endforeach()

    get_property(sections GLOBAL PROPERTY ${STRING_OBJECT}_${vma}_SECTIONS)
    foreach(section ${sections})
      to_string(OBJECT ${section} STRING ${STRING_STRING})
    endforeach()
  endforeach()

  if(NOT ${type} STREQUAL REGION)
    set(${STRING_STRING} "${${STRING_STRING}}\n  __${name}_end = .;\n")
  endif()

  get_property(symbols GLOBAL PROPERTY ${STRING_OBJECT}_SYMBOLS)
  foreach(symbol ${symbols})
    to_string(OBJECT ${symbol} STRING ${STRING_STRING})
  endforeach()

  set(${STRING_STRING} ${${STRING_STRING}} PARENT_SCOPE)
endfunction()

function(section_to_string)
  cmake_parse_arguments(STRING "" "SECTION;STRING" "" ${ARGN})

  get_property(name       GLOBAL PROPERTY ${STRING_SECTION}_NAME)
  get_property(name_clean GLOBAL PROPERTY ${STRING_SECTION}_NAME_CLEAN)
  get_property(address    GLOBAL PROPERTY ${STRING_SECTION}_ADDRESS)
  get_property(type       GLOBAL PROPERTY ${STRING_SECTION}_TYPE)
  get_property(align      GLOBAL PROPERTY ${STRING_SECTION}_ALIGN)
  get_property(subalign   GLOBAL PROPERTY ${STRING_SECTION}_SUBALIGN)
  get_property(vma        GLOBAL PROPERTY ${STRING_SECTION}_VMA)
  get_property(lma        GLOBAL PROPERTY ${STRING_SECTION}_LMA)
  get_property(noinput    GLOBAL PROPERTY ${STRING_SECTION}_NOINPUT)
  get_property(noinit     GLOBAL PROPERTY ${STRING_SECTION}_NOINIT)
  get_property(nosymbols  GLOBAL PROPERTY ${STRING_SECTION}_NOSYMBOLS)
  get_property(parent     GLOBAL PROPERTY ${STRING_SECTION}_PARENT)

  string(REGEX REPLACE "^[\.]" "" name_clean "${name}")
  string(REPLACE "." "_" name_clean "${name_clean}")

  set(SECTION_TYPE_NOLOAD NOLOAD)
  set(SECTION_TYPE_BSS    NOLOAD)
  if(DEFINED type)
    set(type "(${SECTION_TYPE_${type}})")
  endif()

  set(TEMP "${TEMP} :")

  if(DEFINED subalign)
    set(subalign "SUBALIGN(${subalign})")
  endif()

  if(DEFINED align)
    set(TEMP "ALIGN(${SEC_ALIGN})")
  endif()

  set(TEMP "${name} ${address} ${type} : ${subalign} ${align}\n{")
  if(NOT nosymbols)
    set(TEMP "${TEMP}\n  __${name_clean}_start = .;")
  endif()

  if(NOT noinput)
    set(TEMP "${TEMP}\n  *(${name})")
    set(TEMP "${TEMP}\n  *(\"${name}.*\")")
  endif()

  get_property(length GLOBAL PROPERTY ${STRING_SECTION}_SETTINGS_INDEX)
  foreach(idx RANGE 0 ${length})
    get_property(align    GLOBAL PROPERTY ${STRING_SECTION}_SETTING_${idx}_ALIGN)
    get_property(any      GLOBAL PROPERTY ${STRING_SECTION}_SETTING_${idx}_ANY)
    get_property(first    GLOBAL PROPERTY ${STRING_SECTION}_SETTING_${idx}_FIRST)
    get_property(keep     GLOBAL PROPERTY ${STRING_SECTION}_SETTING_${idx}_KEEP)
    get_property(sort     GLOBAL PROPERTY ${STRING_SECTION}_SETTING_${idx}_SORT)
    get_property(flags    GLOBAL PROPERTY ${STRING_SECTION}_SETTING_${idx}_FLAGS)
    get_property(input    GLOBAL PROPERTY ${STRING_SECTION}_SETTING_${idx}_INPUT)
    get_property(symbols  GLOBAL PROPERTY ${STRING_SECTION}_SETTING_${idx}_SYMBOLS)

    if(DEFINED SETTINGS_ALIGN)
      set(TEMP "${TEMP}\n  . = ALIGN(${align});")
    endif()

    if(DEFINED symbols)
      list(LENGTH symbols symbols_count)
      if(${symbols_count} GREATER 0)
        list(GET symbols 0 symbol_start)
      endif()
      if(${symbols_count} GREATER 1)
        list(GET symbols 1 symbol_end)
      endif()
    endif()

    if(DEFINED symbol_start)
      set(TEMP "${TEMP}\n  ${symbol_start} = .;")
    endif()

    foreach(setting ${input})
      if(keep AND sort)
        set(TEMP "${TEMP}\n  KEEP(*(${SORT_TYPE_${sort}}(${setting})));")
      elseif(SETTINGS_SORT)
        message(WARNING "Not tested")
        set(TEMP "${TEMP}\n  *(${SORT_TYPE_${sort}}(${setting}));")
      elseif(keep)
        set(TEMP "${TEMP}\n  KEEP(*(${setting}));")
      else()
        set(TEMP "${TEMP}\n  *(${setting})")
      endif()
    endforeach()

    if(DEFINED symbol_end)
      set(TEMP "${TEMP}\n  ${symbol_end} = .;")
    endif()

    set(symbol_start)
    set(symbol_end)
  endforeach()

  if(NOT nosymbols)
    set(TEMP "${TEMP}\n  __${name_clean}_end = .;")
  endif()

  set(TEMP "${TEMP}\n}")

  get_property(parent_type GLOBAL PROPERTY ${parent}_OBJ_TYPE)
  if(${parent_type} STREQUAL GROUP)
    get_property(vma GLOBAL PROPERTY ${parent}_VMA)
    get_property(lma GLOBAL PROPERTY ${parent}_LMA)
  endif()

  if(DEFINED vma)
    set(TEMP "${TEMP} > ${vma}")
  endif()

  if(DEFINED vma AND DEFINED lma)
    set(TEMP "${TEMP} AT")
  endif()

  if(DEFINED lma)
    set(TEMP "${TEMP} > ${lma}")
  endif()

  if(NOT nosymbols)
    set(TEMP "${TEMP}\n__${name_clean}_size = __${name_clean}_end - __${name_clean}_start;")
    set(TEMP "${TEMP}\n__${name_clean}_load_start = LOADADDR(${name});")
  endif()

  set(${STRING_STRING} "${${STRING_STRING}}\n${TEMP}\n" PARENT_SCOPE)
endfunction()

# /DISCARD/ is an ld specific section, so let's append it here before processing.
list(APPEND SECTIONS "{NAME\;/DISCARD/\;NOINPUT\;TRUE\;NOSYMBOLS\;TRUE}")

include(${CMAKE_CURRENT_LIST_DIR}/../linker_script_common.cmake)

cmake_minimum_required(VERSION 3.17)

set(SORT_TYPE_NAME Lexical)

#
# Create functions - start
#

function(create_region)
  cmake_parse_arguments(OBJECT "" "NAME;OBJECT;SIZE;START;FLAGS" "" ${ARGN})

  if(DEFINED OBJECT_SIZE)
    if(${OBJECT_SIZE} MATCHES "^([0-9]*)[kK]$")
      math(EXPR OBJECT_SIZE "1024 * ${CMAKE_MATCH_1}" OUTPUT_FORMAT HEXADECIMAL)
    elseif(${OBJECT_SIZE} MATCHES "^([0-9]*)[mM]$")
      math(EXPR OBJECT_SIZE "1024 * 1024 * ${CMAKE_MATCH_1}" OUTPUT_FORMAT HEXADECIMAL)
    elseif(NOT (${OBJECT_SIZE} MATCHES "^([0-9]*)$" OR ${OBJECT_SIZE} MATCHES "^0x([0-9a-fA-F]*)$"))
      # ToDo: Handle hex sizes
      message(FATAL_ERROR "SIZE format is onknown.")
    endif()
  endif()

  set_property(GLOBAL PROPERTY REGION_${OBJECT_NAME}          TRUE)
  set_property(GLOBAL PROPERTY REGION_${OBJECT_NAME}_OBJ_TYPE REGION)
  set_property(GLOBAL PROPERTY REGION_${OBJECT_NAME}_NAME     ${OBJECT_NAME})
  set_property(GLOBAL PROPERTY REGION_${OBJECT_NAME}_ADDRESS  ${OBJECT_START})
  set_property(GLOBAL PROPERTY REGION_${OBJECT_NAME}_FLAGS    ${OBJECT_FLAGS})
  set_property(GLOBAL PROPERTY REGION_${OBJECT_NAME}_SIZE     ${OBJECT_SIZE})

  set(${OBJECT_OBJECT} REGION_${OBJECT_NAME} PARENT_SCOPE)
endfunction()

function(get_parent)
  cmake_parse_arguments(GET_PARENT "" "OBJECT;PARENT;TYPE" "" ${ARGN})

  get_property(type GLOBAL PROPERTY ${GET_PARENT_OBJECT}_OBJ_TYPE)
  if(${type} STREQUAL ${GET_PARENT_TYPE})
    # Already the right type, so just set and return.
    set(${GET_PARENT_PARENT} ${GET_PARENT_OBJECT} PARENT_SCOPE)
    return()
  endif()

  get_property(parent GLOBAL PROPERTY ${GET_PARENT_OBJECT}_PARENT)
  get_property(type   GLOBAL PROPERTY ${parent}_OBJ_TYPE)
  while(NOT ${type} STREQUAL ${GET_PARENT_TYPE})
    get_property(parent GLOBAL PROPERTY ${parent}_PARENT)
    get_property(type   GLOBAL PROPERTY ${parent}_OBJ_TYPE)
  endwhile()

  set(${GET_PARENT_PARENT} ${parent} PARENT_SCOPE)
endfunction()

function(create_group)
  cmake_parse_arguments(OBJECT "" "GROUP;LMA;NAME;OBJECT;VMA" "" ${ARGN})

  set_property(GLOBAL PROPERTY GROUP_${OBJECT_NAME}          TRUE)
  set_property(GLOBAL PROPERTY GROUP_${OBJECT_NAME}_OBJ_TYPE GROUP)
  set_property(GLOBAL PROPERTY GROUP_${OBJECT_NAME}_NAME     ${OBJECT_NAME})

  if(DEFINED OBJECT_GROUP)
    find_object(OBJECT parent NAME ${OBJECT_GROUP})
  else()
    if(DEFINED OBJECT_VMA)
      find_object(OBJECT obj NAME ${OBJECT_VMA})
      get_parent(OBJECT ${obj} PARENT parent TYPE REGION)

      get_property(vma GLOBAL PROPERTY ${parent}_NAME)
      set_property(GLOBAL PROPERTY GROUP_${OBJECT_NAME}_VMA ${vma})
    endif()

    if(DEFINED OBJECT_LMA)
      find_object(OBJECT obj NAME ${OBJECT_LMA})
      get_parent(OBJECT ${obj} PARENT parent TYPE REGION)

      get_property(lma GLOBAL PROPERTY ${parent}_NAME)
      set_property(GLOBAL PROPERTY GROUP_${OBJECT_NAME}_LMA ${lma})
    endif()
  endif()

  get_property(GROUP_FLAGS_INHERITED GLOBAL PROPERTY ${parent}_FLAGS)
  set_property(GLOBAL PROPERTY GROUP_${OBJECT_NAME}_FLAGS  ${GROUP_FLAGS_INHERITED})
  set_property(GLOBAL PROPERTY GROUP_${OBJECT_NAME}_PARENT ${parent})

  add_group(OBJECT ${parent} GROUP GROUP_${OBJECT_NAME})

  set(${OBJECT_OBJECT} GROUP_${OBJECT_NAME} PARENT_SCOPE)
endfunction()

function(create_section)
  set(single_args "NAME;ADDRESS;TYPE;ALIGN;SUBALIGN;VMA;LMA;NOINPUT;NOINIT;GROUP")
  set(multi_args  "PASS")

  cmake_parse_arguments(SECTION "" "${single_args}" "${multi_args}" ${ARGN})

  if(DEFINED SECTION_PASS AND NOT "${PASS}" IN_LIST SECTION_PASS)
    # This section is not active in this pass, ignore.
    return()
  endif()

  set_property(GLOBAL PROPERTY SECTION_${SECTION_NAME} TRUE)
  set_property(GLOBAL PROPERTY SECTION_${SECTION_NAME}_OBJ_TYPE SECTION)
  set_property(GLOBAL PROPERTY SECTION_${SECTION_NAME}_NAME     ${SECTION_NAME})
  set_property(GLOBAL PROPERTY SECTION_${SECTION_NAME}_ADDRESS  ${SECTION_ADDRESS})
  set_property(GLOBAL PROPERTY SECTION_${SECTION_NAME}_TYPE     ${SECTION_TYPE})
  set_property(GLOBAL PROPERTY SECTION_${SECTION_NAME}_ALIGN    ${SECTION_ALIGN})
  set_property(GLOBAL PROPERTY SECTION_${SECTION_NAME}_SUBALIGN ${SECTION_SUBALIGN})
  set_property(GLOBAL PROPERTY SECTION_${SECTION_NAME}_NOINPUT  ${SECTION_NOINPUT})
  set_property(GLOBAL PROPERTY SECTION_${SECTION_NAME}_NOINIT   ${SECTION_NOINIT})

  string(REGEX REPLACE "^[\.]" "" name_clean "${SECTION_NAME}")
  string(REPLACE "." "_" name_clean "${name_clean}")
  set_property(GLOBAL PROPERTY SECTION_${SECTION_NAME}_NAME_CLEAN ${name_clean})

  set_property(GLOBAL PROPERTY SYMBOL_TABLE___${name_clean}_start      ${name_clean})
  set_property(GLOBAL PROPERTY SYMBOL_TABLE___${name_clean}_size       ${name_clean})
  set_property(GLOBAL PROPERTY SYMBOL_TABLE___${name_clean}_load_start ${name_clean})
  set_property(GLOBAL PROPERTY SYMBOL_TABLE___${name_clean}_end        ${name_clean})

  set(INDEX 0)
  set(settings_single "ALIGN;ANY;FIRST;KEEP;PASS;SECTION;SORT")
  set(settings_multi  "FLAGS;INPUT;SYMBOLS")
  foreach(settings ${SECTION_SETTINGS})
    if("${settings}" MATCHES "^{(.*)}$")
      cmake_parse_arguments(SETTINGS "" "${settings_single}" "${settings_multi}" ${CMAKE_MATCH_1})

      if(NOT ("${SETTINGS_SECTION}" STREQUAL "${SECTION_NAME}"))
        continue()
      endif()

      if(DEFINED SETTINGS_PASS AND NOT "${PASS}" IN_LIST SETTINGS_PASS)
        # This section setting is not active in this pass, ignore.
        continue()
      endif()

      foreach(setting ${settings_single} ${settings_multi})
        set_property(GLOBAL PROPERTY
	  SECTION_${SECTION_NAME}_SETTING_${INDEX}_${setting}
	  ${SETTINGS_${setting}}
        )
	if(DEFINED SETTINGS_SORT)
          set_property(GLOBAL PROPERTY SYMBOL_TABLE___${name_clean}_end ${name_clean}_end)
        endif()
      endforeach()

      math(EXPR INDEX "${INDEX} + 1")
    endif()
  endforeach()

  set_property(GLOBAL PROPERTY SECTION_${SECTION_NAME}_SETTINGS_INDEX ${INDEX})

  if(DEFINED SECTION_GROUP)
    find_object(OBJECT parent NAME ${SECTION_GROUP})
  else()
    if(DEFINED SECTION_VMA)
      find_object(OBJECT object NAME ${SECTION_VMA})
      get_parent(OBJECT ${object} PARENT parent TYPE REGION)

      get_property(vma GLOBAL PROPERTY ${parent}_NAME)
      set_property(GLOBAL PROPERTY SECTION_${SECTION_NAME}_VMA ${vma})
      set(SECTION_VMA ${vma})
    endif()

    if(DEFINED SECTION_LMA)
      find_object(OBJECT object NAME ${SECTION_LMA})
      get_parent(OBJECT ${object} PARENT parent TYPE REGION)

      get_property(lma GLOBAL PROPERTY ${parent}_NAME)
      set_property(GLOBAL PROPERTY SECTION_${SECTION_NAME}_LMA ${lma})
      set(SECTION_LMA ${lma})
    endif()
  endif()

  set_property(GLOBAL PROPERTY SECTION_${SECTION_NAME}_PARENT ${parent})
  add_section(OBJECT ${parent} SECTION ${SECTION_NAME} ADDRESS ${SECTION_ADDRESS} VMA ${SECTION_VMA})
endfunction()

function(create_symbol)
  cmake_parse_arguments(SYM "" "OBJECT;EXPR;SIZE;SUBALIGN;SYMBOL" "" ${ARGN})

  set_property(GLOBAL PROPERTY SYMBOL_${SYM_SYMBOL} TRUE)
  set_property(GLOBAL PROPERTY SYMBOL_${SYM_SYMBOL}_OBJ_TYPE SYMBOL)
  set_property(GLOBAL PROPERTY SYMBOL_${SYM_SYMBOL}_NAME     ${SYM_SYMBOL})
  set_property(GLOBAL PROPERTY SYMBOL_${SYM_SYMBOL}_EXPR     ${SYM_EXPR})
  set_property(GLOBAL PROPERTY SYMBOL_${SYM_SYMBOL}_SIZE     ${SYM_SIZE})
  set_property(GLOBAL PROPERTY SYMBOL_${SYM_SYMBOL}_SYMBOL   ${SYM_SYMBOL})

  set_property(GLOBAL PROPERTY SYMBOL_TABLE_${SYM_SYMBOL} ${SYM_SYMBOL})

  add_symbol(OBJECT ${SYM_OBJECT} SYMBOL SYMBOL_${SYM_SYMBOL})
endfunction()

#
# Create functions - end
#

#
# Add functions - start
#
function(add_group)
  cmake_parse_arguments(ADD_GROUP "" "OBJECT;GROUP" "" ${ARGN})

  # Section can be fixed address or not, VMA == LMA, .
  #
  get_property(exists GLOBAL PROPERTY ${ADD_GROUP_OBJECT})
  if(NOT exists)
    message(FATAL_ERROR
      "Adding group ${ADD_GROUP_GROUP} to none-existing object: "
      "${ADD_GROUP_OBJECT}"
    )
  endif()

  get_property(vma GLOBAL PROPERTY ${ADD_GROUP_GROUP}_VMA)
  get_property(object_name GLOBAL PROPERTY ${ADD_GROUP_OBJECT}_NAME)

  if((NOT DEFINED vma) OR ("${vma}" STREQUAL ${object_name}))
    set_property(GLOBAL APPEND PROPERTY ${ADD_GROUP_OBJECT}_GROUPS ${ADD_GROUP_GROUP})
  else()
    set_property(GLOBAL APPEND PROPERTY ${ADD_GROUP_OBJECT}_${vma}_GROUPS ${ADD_GROUP_GROUP})
  endif()
endfunction()

function(add_section)
  cmake_parse_arguments(ADD_SECTION "" "OBJECT;SECTION;ADDRESS;VMA" "" ${ARGN})

  # Section can be fixed address or not, VMA == LMA, .
  #
  if(DEFINED ADD_SECTION_OBJECT)
    get_property(type GLOBAL PROPERTY ${ADD_SECTION_OBJECT}_OBJ_TYPE)
    get_property(object_name GLOBAL PROPERTY ${ADD_SECTION_OBJECT}_NAME)

    if(NOT DEFINED type)
      message(FATAL_ERROR
              "Adding section ${ADD_SECTION_SECTION} to "
              "none-existing object: ${ADD_SECTION_OBJECT}"
      )
    endif()
  else()
    set(ADD_SECTION_OBJECT RELOCATEABLE)
  endif()

  if("${ADD_SECTION_VMA}" STREQUAL "${object_name}" AND DEFINED ADD_SECTION_ADDRESS)
    set_property(GLOBAL APPEND PROPERTY
      ${ADD_SECTION_OBJECT}_SECTIONS_FIXED
      SECTION_${ADD_SECTION_SECTION}
    )
  elseif(NOT DEFINED ADD_SECTION_VMA AND DEFINED SECTION_ADDRESS)
    set_property(GLOBAL APPEND PROPERTY
      ${ADD_SECTION_OBJECT}_SECTIONS_FIXED
      SECTION_${ADD_SECTION_SECTION}
    )
  elseif("${ADD_SECTION_VMA}" STREQUAL "${object_name}")
    set_property(GLOBAL APPEND PROPERTY
      ${ADD_SECTION_OBJECT}_SECTIONS
      SECTION_${ADD_SECTION_SECTION}
    )
  elseif(NOT DEFINED ADD_SECTION_VMA)
    set_property(GLOBAL APPEND PROPERTY
      ${ADD_SECTION_OBJECT}_SECTIONS
      SECTION_${ADD_SECTION_SECTION}
    )
  elseif(DEFINED SECTION_ADDRESS)
    set_property(GLOBAL APPEND PROPERTY
      ${ADD_SECTION_OBJECT}_${ADD_SECTION_VMA}_SECTIONS_FIXED
      SECTION_${ADD_SECTION_SECTION}
    )
  else()
    set_property(GLOBAL APPEND PROPERTY
      ${ADD_SECTION_OBJECT}_${ADD_SECTION_VMA}_SECTIONS
      SECTION_${ADD_SECTION_SECTION}
    )
  endif()
endfunction()

#
# Add functions - end
#

#
# Retrieval functions - start
#
function(find_object)
  cmake_parse_arguments(FIND "" "OBJECT;NAME" "" ${ARGN})

  get_property(REGION  GLOBAL PROPERTY REGION_${FIND_NAME})
  get_property(GROUP   GLOBAL PROPERTY GROUP_${FIND_NAME})
  get_property(SECTION GLOBAL PROPERTY SECTION_${FIND_NAME})

  if(REGION)
    set(${FIND_OBJECT} REGION_${FIND_NAME} PARENT_SCOPE)
  elseif(GROUP)
    set(${FIND_OBJECT} GROUP_${FIND_NAME} PARENT_SCOPE)
  elseif(SECTION)
    set(${FIND_OBJECT} SECTION_${FIND_NAME} PARENT_SCOPE)
  else()
    message(WARNING "No object with name ${FIND_NAME} could be found.")
  endif()
endfunction()

function(get_objects)
  cmake_parse_arguments(GET "" "LIST;OBJECT;TYPE" "" ${ARGN})

  get_property(type GLOBAL PROPERTY ${GET_OBJECT}_OBJ_TYPE)

  if(${type} STREQUAL SECTION)
    # A section doesn't have sub-items.
    return()
  endif()

  if(NOT (${GET_TYPE} STREQUAL SECTION))
    message(WARNING "Only retrieval of SECTION objects is supported.")
    return()
  endif()

  set(out)

  get_property(sections GLOBAL PROPERTY ${GET_OBJECT}_SECTIONS_FIXED)
  list(APPEND out ${sections})

  get_property(groups GLOBAL PROPERTY ${GET_OBJECT}_GROUPS)
  foreach(group ${groups})
    get_objects(LIST sections OBJECT ${group} TYPE ${GET_TYPE})
    list(APPEND out ${sections})
  endforeach()

  get_property(sections GLOBAL PROPERTY ${GET_OBJECT}_SECTIONS)
  list(APPEND out ${sections})

  list(REMOVE_ITEM REGIONS ${GET_OBJECT})
  foreach(region ${REGIONS})
    get_property(vma GLOBAL PROPERTY ${region}_NAME)

    get_property(sections GLOBAL PROPERTY ${GET_OBJECT}_${vma}_SECTIONS_FIXED)
    list(APPEND out ${sections})

    get_property(groups GLOBAL PROPERTY ${GET_OBJECT}_${vma}_GROUPS)
    foreach(group ${groups})
      get_objects(LIST sections OBJECT ${group} TYPE ${GET_TYPE})
      list(APPEND out ${sections})
    endforeach()

    get_property(sections GLOBAL PROPERTY ${GET_OBJECT}_${vma}_SECTIONS)
    list(APPEND out ${sections})
  endforeach()

  set(${GET_LIST} ${out} PARENT_SCOPE)
endfunction()

#
# Retrieval functions - end
#


# This function post process the region for easier use.
#
# Tasks:
# - Apply missing settings, such as initial address for first section in a region.
# - Symbol names on sections
# - Ordered list of all sections for easier retrival on printing and configuration.
function(process_region)
  cmake_parse_arguments(REGION "" "OBJECT" "" ${ARGN})

  set(sections)
  get_objects(LIST sections OBJECT ${REGION_OBJECT} TYPE SECTION)
  set_property(GLOBAL PROPERTY ${REGION_OBJECT}_SECTION_LIST_ORDERED ${sections})

  list(LENGTH sections section_count)
  if(section_count GREATER 0)
    list(GET sections 0 section)
    get_property(address GLOBAL PROPERTY ${section}_ADDRESS)
    if(NOT DEFINED address)
      get_parent(OBJECT ${REGION_OBJECT} PARENT parent TYPE REGION)
      get_property(address GLOBAL PROPERTY ${parent}_ADDRESS)
      set_property(GLOBAL PROPERTY ${section}_ADDRESS ${address})
    endif()
  endif()

  list(REMOVE_ITEM REGIONS ${REGION_OBJECT})
  foreach(region ${REGIONS})
    get_property(vma GLOBAL PROPERTY ${region}_NAME)
    set(sections_${vma})
    get_property(sections GLOBAL PROPERTY ${REGION_OBJECT}_${vma}_SECTIONS_FIXED)
    list(APPEND sections_${vma} ${sections})

    get_property(groups GLOBAL PROPERTY ${REGION_OBJECT}_${vma}_GROUPS)
    foreach(group ${groups})
      get_objects(LIST sections OBJECT ${group} TYPE SECTION)
      list(APPEND sections_${vma} ${sections})
    endforeach()

    get_property(sections GLOBAL PROPERTY ${REGION_OBJECT}_${vma}_SECTIONS)
    list(APPEND sections_${vma} ${sections})

    list(LENGTH sections_${vma} section_count)
    if(section_count GREATER 0)
      list(GET sections_${vma} 0 section)
      get_property(address GLOBAL PROPERTY ${section}_ADDRESS)
      if(NOT DEFINED address)
        get_property(address GLOBAL PROPERTY ${region}_ADDRESS)
        set_property(GLOBAL PROPERTY ${section}_ADDRESS ${address})
      endif()
    endif()
  endforeach()

  get_property(symbols GLOBAL PROPERTY ${REGION_OBJECT}_SYMBOLS)
  foreach(symbol ${symbols})
    get_property(name GLOBAL PROPERTY ${STRING_SYMBOL}_SYMBOL)
    set_property(GLOBAL APPEND PROPERTY SYMBOL_STEERING_C "Image$$${name}$$Base")

    set_property(GLOBAL APPEND PROPERTY SYMBOL_STEERING_FILE
      "RESOLVE ${name} AS Image$$${name}$$Base\n"
    )
  endforeach()

  get_property(sections GLOBAL PROPERTY ${REGION_OBJECT}_SECTION_LIST_ORDERED)
  foreach(section ${sections})

    get_property(name_clean GLOBAL PROPERTY ${section}_NAME_CLEAN)
    get_property(length GLOBAL PROPERTY ${section}_SETTINGS_INDEX)
    foreach(idx RANGE 0 ${length})
      set(steering_postfixes Base Limit)
      get_property(symbols GLOBAL PROPERTY ${section}_SETTING_${idx}_SYMBOLS)
      get_property(sort    GLOBAL PROPERTY ${section}_SETTING_${idx}_SORT)
      get_property(noinput GLOBAL PROPERTY ${section}_SETTING_${idx}_NOINPUT)
      if(sort)
        foreach(symbol ${symbols})
          list(POP_FRONT steering_postfixes postfix)
          set_property(GLOBAL APPEND PROPERTY SYMBOL_STEERING_C
            "Image$$${name_clean}_${idx}$$${postfix}"
          )
          set_property(GLOBAL APPEND PROPERTY SYMBOL_STEERING_FILE
            "RESOLVE ${symbol} AS Image$$${name_clean}_${idx}$$${postfix}\n"
          )
        endforeach()
      elseif(DEFINED symbols AND ${length} EQUAL 1 AND noinput)
        set(steering_postfixes Base Limit)
        foreach(symbol ${symbols})
          list(POP_FRONT steering_postfixes postfix)
          set_property(GLOBAL APPEND PROPERTY SYMBOL_STEERING_C
            "Image$$${name_clean}$$${postfix}"
          )
          set_property(GLOBAL APPEND PROPERTY SYMBOL_STEERING_FILE
            "RESOLVE ${symbol} AS Image$$${name_clean}$$${postfix}\n"
          )
        endforeach()
      endif()
    endforeach()

    # Symbols translation here.
    set_property(GLOBAL APPEND PROPERTY SYMBOL_STEERING_C "Image$$${name_clean}${ZI}$$Base")
    set_property(GLOBAL APPEND PROPERTY SYMBOL_STEERING_C "Image$$${name_clean}${ZI}$$Length")
    set_property(GLOBAL APPEND PROPERTY SYMBOL_STEERING_C "Load$$${name_clean}${ZI}$$Base")

    set_property(GLOBAL APPEND PROPERTY SYMBOL_STEERING_FILE
      "RESOLVE __${name_clean}_start AS Image$$${name_clean}${ZI}$$Base\n"
      "RESOLVE __${name_clean}_size AS Image$$${name_clean}${ZI}$$Length\n"
      "RESOLVE __${name_clean}_load_start AS Load$$${name_clean}${ZI}$$Base\n"
      "EXPORT  __${name_clean}_start AS __${name_clean}_start\n"
    )

    if("${length}" GREATER 0)
      set_property(GLOBAL APPEND PROPERTY SYMBOL_STEERING_C "Image$$${name_clean}_end$$Limit")
      set_property(GLOBAL APPEND PROPERTY SYMBOL_STEERING_FILE
        "RESOLVE __${name_clean}_end AS Image$$${name_clean}_end$$Limit\n"
      )
    else()
      set_property(GLOBAL APPEND PROPERTY SYMBOL_STEERING_C "Image$$${name_clean}${ZI}$$Limit")
      set_property(GLOBAL APPEND PROPERTY SYMBOL_STEERING_FILE
        "RESOLVE __${name_clean}_end AS Image$$${name_clean}${ZI}$$Limit\n"
      )
    endif()

  endforeach()

endfunction()

#
# String functions - start
#

function(group_to_string)
  cmake_parse_arguments(STRING "" "OBJECT;STRING" "" ${ARGN})

  get_property(type GLOBAL PROPERTY ${STRING_OBJECT}_OBJ_TYPE)
  if(${type} STREQUAL REGION)
    get_property(name GLOBAL PROPERTY ${STRING_OBJECT}_NAME)
    get_property(address GLOBAL PROPERTY ${STRING_OBJECT}_ADDRESS)
    get_property(size GLOBAL PROPERTY ${STRING_OBJECT}_SIZE)
    set(${STRING_STRING} "${${STRING_STRING}}\n${name} ${address} ${size}\n{\n")
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

  list(REMOVE_ITEM REGIONS ${STRING_OBJECT})
  foreach(region ${REGIONS})
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

  get_property(symbols GLOBAL PROPERTY ${STRING_OBJECT}_SYMBOLS)
  foreach(symbol ${symbols})
    to_string(OBJECT ${symbol} STRING ${STRING_STRING})
  endforeach()

  if(${type} STREQUAL REGION)
    set(${STRING_STRING} "${${STRING_STRING}}\n}\n")
  endif()
  set(${STRING_STRING} ${${STRING_STRING}} PARENT_SCOPE)
endfunction()


function(section_to_string)
  cmake_parse_arguments(STRING "" "SECTION;STRING" "" ${ARGN})

  get_property(name     GLOBAL PROPERTY ${STRING_SECTION}_NAME)
  get_property(address  GLOBAL PROPERTY ${STRING_SECTION}_ADDRESS)
  get_property(type     GLOBAL PROPERTY ${STRING_SECTION}_TYPE)
  get_property(align    GLOBAL PROPERTY ${STRING_SECTION}_ALIGN)
  get_property(subalign GLOBAL PROPERTY ${STRING_SECTION}_SUBALIGN)
  get_property(vma      GLOBAL PROPERTY ${STRING_SECTION}_VMA)
  get_property(lma      GLOBAL PROPERTY ${STRING_SECTION}_LMA)
  get_property(noinput  GLOBAL PROPERTY ${STRING_SECTION}_NOINPUT)
  get_property(noinit   GLOBAL PROPERTY ${STRING_SECTION}_NOINIT)

  string(REGEX REPLACE "^[\.]" "" name_clean "${name}")
  string(REPLACE "." "_" name_clean "${name_clean}")

  set(TEMP "  ${name_clean}")
  if(DEFINED address)
    set(TEMP "${TEMP} ${address}")
  else()
    set(TEMP "${TEMP} +0")
  endif()

  if(noinit)
    # Currently we simply uses offset +0, but we must support offset defined
    # externally.
    set(TEMP "${TEMP} UNINIT")
  endif()

  if(subalign)
    # Currently we simply uses offset +0, but we must support offset defined
    # externally.
    set(TEMP "${TEMP} ALIGN ${subalign}")
  endif()

  if(NOT noinput)
    set(TEMP "${TEMP}\n  {")

    if("${type}" STREQUAL NOLOAD)
      set(TEMP "${TEMP}\n    *.o(${name}*)")
      set(TEMP "${TEMP}\n    *.o(${name}*.*)")
    elseif(VMA_FLAGS)
      # ToDo: Proper names as provided by armclang
#      set(TEMP "${TEMP}\n    *.o(${SEC_NAME}*, +${VMA_FLAGS})")
#      set(TEMP "${TEMP}\n    *.o(${SEC_NAME}*.*, +${VMA_FLAGS})")
      set(TEMP "${TEMP}\n    *.o(${name}*)")
      set(TEMP "${TEMP}\n    *.o(${name}*.*)")
    else()
      set(TEMP "${TEMP}\n    *.o(${name}*)")
      set(TEMP "${TEMP}\n    *.o(${name}*.*)")
    endif()
  else()
    set(empty TRUE)
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

    if(sort)
      set(section_close TRUE)
      if(empty)
        set(TEMP "${TEMP} EMPTY 0x0\n  {")
        set(empty FALSE)
      endif()
      set(TEMP "${TEMP}\n  }")
      set(TEMP "${TEMP}\n  ${name_clean}_${idx} +0 SORTTYPE ${SORT_TYPE_${sort}}\n  {")
    endif()

    if(empty)
      set(TEMP "${TEMP}\n  {")
      set(empty FALSE)
    endif()

    foreach(setting ${input})
      #set(SETTINGS ${SETTINGS_INPUT})

#      # ToDo: The code below had en error in original implementation, causing
#      #       settings not to be applied
#      #       Verify behaviour and activate if working as intended.
#      if(align)
#        set(setting "${setting}, OVERALIGN ${align}")
#      endif()

      #if(SETTINGS_KEEP)
      # armlink has --keep=<section_id>, but is there an scatter equivalant ?
      #endif()

      if(first)
        set(setting "${setting}, +First")
        set(first "")
      endif()

      set(TEMP "${TEMP}\n    *.o(${setting})")
    endforeach()

    if(any)
      if(NOT flags)
        message(FATAL_ERROR ".ANY requires flags to be set.")
      endif()
      string(REPLACE ";" " " flags "${flags}")

      set(TEMP "${TEMP}\n    .ANY (${flags})")
    endif()
  endforeach()

  if(section_close)
    set(section_close)
    set(TEMP "${TEMP}\n  }")
    set(TEMP "${TEMP}\n  ${name_clean}_end +0 EMPTY 0x0\n  {")
  endif()

  set(TEMP "${TEMP}")
  # ToDo: add patterns here.

  if("${type}" STREQUAL BSS)
    set(ZI "$$ZI")
  endif()

  set(TEMP "${TEMP}\n  }")

  set(${STRING_STRING} "${${STRING_STRING}}\n${TEMP}\n" PARENT_SCOPE)
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
    get_property(symbol_val GLOBAL PROPERTY SYMBOL_TABLE_${match})
    string(REPLACE "%${match}%" "ImageBase(${symbol_val})" expr ${expr})
  endforeach()

  if(DEFINED subalign)
    set(subalign "ALIGN ${subalign}")
  endif()

  if(NOT DEFINED size)
    set(size "0x0")
  endif()

  set(${STRING_STRING}
    "${${STRING_STRING}}\n  ${symbol} ${expr} ${subalign} EMPTY ${size}\n  {\n  }\n"
    PARENT_SCOPE
  )
endfunction()

function(to_string)
  cmake_parse_arguments(STRING "" "OBJECT;STRING" "" ${ARGN})

  get_property(type GLOBAL PROPERTY ${STRING_OBJECT}_OBJ_TYPE)

  if(("${type}" STREQUAL REGION) OR ("${type}" STREQUAL GROUP))
    group_to_string(OBJECT ${STRING_OBJECT} STRING ${STRING_STRING})
  elseif("${type}" STREQUAL SECTION)
    section_to_string(SECTION ${STRING_OBJECT} STRING ${STRING_STRING})
  elseif("${type}" STREQUAL SYMBOL)
    symbol_to_string(SYMBOL ${STRING_OBJECT} STRING ${STRING_STRING})
  endif()

  set(${STRING_STRING} ${${STRING_STRING}} PARENT_SCOPE)
endfunction()

function(add_symbol)
  cmake_parse_arguments(ADD_SYMBOL "" "OBJECT;SYMBOL" "" ${ARGN})

  # Section can be fixed address or not, VMA == LMA, .
  #
  get_property(exists GLOBAL PROPERTY ${ADD_SYMBOL_OBJECT})
  if(NOT exists)
    message(FATAL_ERROR
      "Adding symbol ${ADD_SYMBOL_SYMBOL} to none-existing object: "
      "${ADD_SYMBOL_OBJECT}"
    )
  endif()

  set_property(GLOBAL APPEND PROPERTY ${ADD_SYMBOL_OBJECT}_SYMBOLS ${ADD_SYMBOL_SYMBOL})
endfunction()

#
# String functions - end
#

# Sorting the memory sections in ascending order.
foreach(region ${MEMORY_REGIONS})
  if("${region}" MATCHES "^{(.*)}$")
    cmake_parse_arguments(REGION "" "START" "" ${CMAKE_MATCH_1})
    math(EXPR start_dec "${REGION_START}" OUTPUT_FORMAT DECIMAL)
    set(region_${start_dec} ${region})
    string(REPLACE ";" "\;" region_${start_dec} "${region_${start_dec}}")
    list(APPEND region_sort ${start_dec})
  endif()
endforeach()

list(SORT region_sort COMPARE NATURAL)
set(MEMORY_REGIONS_SORTED)
foreach(region_start ${region_sort})
  list(APPEND MEMORY_REGIONS_SORTED "${region_${region_start}}")
endforeach()
# sorting complete.

foreach(region ${MEMORY_REGIONS_SORTED})
  if("${region}" MATCHES "^{(.*)}$")
    create_region(OBJECT new_region ${CMAKE_MATCH_1})

    list(APPEND REGIONS ${new_region})
  endif()
endforeach()

foreach(group ${GROUPS})
  if("${group}" MATCHES "^{(.*)}$")
    create_group(OBJECT new_group ${CMAKE_MATCH_1})
  endif()
endforeach()

foreach(section ${SECTIONS})
  if("${section}" MATCHES "^{(.*)}$")
    create_section(${CMAKE_MATCH_1})
  endif()
endforeach()

foreach(region ${REGIONS})
  process_region(OBJECT ${region})
endforeach()

list(GET REGIONS 0 symbol_region)
message("idx0: ${symbol_region} in ${REGIONS}")
foreach(symbol ${SYMBOLS})
  if("${symbol}" MATCHES "^{(.*)}$")
    create_symbol(OBJECT ${symbol_region} ${CMAKE_MATCH_1})
  endif()
endforeach()

set(OUT)
foreach(region ${REGIONS})
  to_string(OBJECT ${region} STRING OUT)
endforeach()

if(OUT_FILE)
  file(WRITE ${OUT_FILE} "${OUT}")
endif()

if(DEFINED STEERING_C)
  get_property(symbols_c GLOBAL PROPERTY SYMBOL_STEERING_C)
  file(WRITE ${STEERING_C}  "/* AUTO-GENERATED - Do not modify\n")
  file(APPEND ${STEERING_C} " * AUTO-GENERATED - All changes will be lost\n")
  file(APPEND ${STEERING_C} " */\n")
  foreach(symbol ${symbols_c})
    file(APPEND ${STEERING_C} "extern char ${symbol}[];\n")
  endforeach()

  file(APPEND ${STEERING_C} "\nint __armlink_symbol_steering(void) {\n")
  file(APPEND ${STEERING_C} "\treturn\n")
  foreach(symbol ${symbols_c})
    file(APPEND ${STEERING_C} "\t\t${OPERAND} (int)${symbol}\n")
    set(OPERAND "&")
  endforeach()
  file(APPEND ${STEERING_C} "\t;\n}\n")
endif()

if(DEFINED STEERING_FILE)
  get_property(steering_content GLOBAL PROPERTY SYMBOL_STEERING_FILE)
  file(WRITE ${STEERING_FILE}  "; AUTO-GENERATED - Do not modify\n")
  file(APPEND ${STEERING_FILE} "; AUTO-GENERATED - All changes will be lost\n")
  file(APPEND ${STEERING_FILE} ${steering_content})
endif()

function(memory_content)
  cmake_parse_arguments(MC "" "CONTENT;NAME;START;SIZE;FLAGS" "" ${ARGN})

  set(TEMP)
  if(MC_NAME)
    set(TEMP "${TEMP} ${MC_NAME}")
  endif()

  if(MC_FLAGS)
    set(TEMP "${TEMP} (${MC_FLAGS})")
  endif()

  if(MC_START)
    set(TEMP "${TEMP} : ORIGIN = (${MC_START})")
  endif()

  if(MC_SIZE)
    set(TEMP "${TEMP}, LENGTH = (${MC_SIZE})")
  endif()

  set(${MC_CONTENT} "${${MC_CONTENT}}\n${TEMP}" PARENT_SCOPE)
endfunction()

function(section_content)
  cmake_parse_arguments(SEC "" "CONTENT;NAME;ADDRESS;TYPE;ALIGN;SUBALIGN;VMA;LMA" "" ${ARGN})

  # SEC_NAME is required, test for that.
  #if(SEC_NAME)
  set(TEMP "${SEC_NAME}")
  #endif()

  if(SEC_ADDRESS)
    set(TEMP "${TEMP} ${SEC_ADDRESS}")
  endif()

  if(SEC_TYPE)
    set(TEMP "${TEMP} (${SEC_TYPE})")
  endif()

  set(TEMP "${TEMP} :")

  if(SEC_SUBALIGN)
    set(TEMP "${TEMP} SUBALIGN(${SEC_SUBALIGN})")
  endif()

  set(TEMP "${TEMP}\n{")
  set(TEMP "${TEMP}\n  __${SEC_NAME}_start = .;")
  set(TEMP "${TEMP}\n  *(.${SEC_NAME})")
  set(TEMP "${TEMP}\n  *(\".${SEC_NAME}.*\")")

  if(SECTION_${SEC_NAME}_SETTINGS)
    cmake_parse_arguments(SETTINGS "KEEP" "INPUT;ALIGN;SYMBOL" "" ${SECTION_${SEC_NAME}_SETTINGS})
    if(SETTINGS_ALIGN)
      set(TEMP "${TEMP}\n  . = ALIGN(${SETTINGS_ALIGN});")
    endif()

    if(SETTINGS_SYMBOL)
      set(TEMP "${TEMP}\n  ${SETTINGS_SYMBOL} = .;")
    endif()



    if(SETTINGS_KEEP)
      set(TEMP "${TEMP}\n  KEEP(*(${SETTINGS_INPUT}));")
    else()
      set(TEMP "${TEMP}\n  *(${SETTINGS_INPUT})")
    endif()
  endif()

  set(TEMP "${TEMP}\n  __${SEC_NAME}_end = .;")

  # ToDo: add patterns here.
  #       add symbols here.
  set(TEMP "${TEMP}\n} > ${SEC_VMA}")

  if(SEC_LMA)
    set(TEMP "${TEMP} > ${SEC_LMA}")
  endif()

  set(${SEC_CONTENT} "${${SEC_CONTENT}}\n${TEMP}\n" PARENT_SCOPE)
endfunction()


set(OUT "MEMORY\n{")
foreach(region ${MEMORY_REGIONS})
  if("${region}" MATCHES "^{(.*)}$")
    cmake_parse_arguments(REGION "" "NAME;START" "" ${CMAKE_MATCH_1})
    set(REGION_${REGION_NAME}_START ${REGION_START})
    memory_content(CONTENT OUT ${CMAKE_MATCH_1})
  endif()
endforeach()
set(OUT "${OUT}\n}\n")

foreach(settings ${SECTION_SETTINGS})
  if("${settings}" MATCHES "^{(.*)}$")
    cmake_parse_arguments(SETTINGS "" "SECTION" "" ${CMAKE_MATCH_1})

    set(SECTION_${SETTINGS_SECTION}_SETTINGS ${CMAKE_MATCH_1})
  endif()
endforeach()

foreach(section ${SECTIONS})
  if("${section}" MATCHES "^{(.*)}$")
    cmake_parse_arguments(SECTION "" "VMA" "" ${CMAKE_MATCH_1})

    if(NOT "${CURRENT_VMA}" STREQUAL "${SECTION_VMA}")
      set(CURRENT_VMA ${SECTION_VMA})
      set(OUT "${OUT}\n. = ${REGION_${SECTION_VMA}_START}")
    endif()
    section_content(CONTENT OUT ${CMAKE_MATCH_1})
  endif()
endforeach()


message("${OUT}")
#
#set(MEMORY
#"MEMORY"
#"{"
#$
#"}"
#)
#
#

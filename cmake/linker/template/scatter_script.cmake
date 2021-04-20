
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
  cmake_parse_arguments(SEC "" "REGION_NAME;REGION_FLAGS;CONTENT;NAME;ADDRESS;TYPE;ALIGN;SUBALIGN;VMA;LMA" "" ${ARGN})

  if("${SEC_REGION_NAME}" STREQUAL "${SEC_VMA}"
     AND NOT SEC_LMA
     OR  "${SEC_REGION_NAME}" STREQUAL "${SEC_LMA}"
  )

    # SEC_NAME is required, test for that.
    set(TEMP "  ${SEC_NAME}")

    if(SEC_ADDRESS)
      set(TEMP "${TEMP} ${SEC_ADDRESS}")
    else()
      set(TEMP "${TEMP} +0")
    endif()

    if(SEC_SUBALIGN)
      # Currently we simply uses offset +0, but we must support offset defined
      # externally.
      set(TEMP "${TEMP} +0 ALIGN ${SEC_SUBALIGN}")
    endif()


    set(TEMP "${TEMP}\n  {")

    string(TOUPPER ${REGION_${SEC_VMA}_FLAGS} VMA_FLAGS)
    if("${SEC_TYPE}" STREQUAL NOLOAD)
      set(TEMP "${TEMP}\n    *.o(${SEC_NAME}*)")
      set(TEMP "${TEMP}\n    *.o(${SEC_NAME}*.*)")
    elseif(VMA_FLAGS)
      # ToDo: Proper names as provided by armclang
#      set(TEMP "${TEMP}\n    *.o(${SEC_NAME}*, +${VMA_FLAGS})")
#      set(TEMP "${TEMP}\n    *.o(${SEC_NAME}*.*, +${VMA_FLAGS})")
      set(TEMP "${TEMP}\n    *.o(${SEC_NAME}*)")
      set(TEMP "${TEMP}\n    *.o(${SEC_NAME}*.*)")
    else()
      set(TEMP "${TEMP}\n    *.o(${SEC_NAME}*)")
      set(TEMP "${TEMP}\n    *.o(${SEC_NAME}*.*)")
    endif()



    if(SECTION_${SEC_NAME}_INDEX)
      message("SECTION_${SEC_NAME}_INDEX: ${SECTION_${SEC_NAME}_INDEX}")
      foreach(idx RANGE 0 ${SECTION_${SEC_NAME}_INDEX})
        cmake_parse_arguments(SETTINGS "" "ANY;INPUT;KEEP;FIRST;ALIGN;SYMBOL" "FLAGS" ${SECTION_${SEC_NAME}_SETTINGS_${idx}})

        if(SETTINGS_INPUT)
          set(SETTINGS ${SETTINGS_INPUT})

          if(SETTINGS_ALIGN)
             set(SETTINGS "${SETTINGS}, OVERALIGN ${SETTINGS_ALIGN}")
          endif()

          #if(SETTINGS_KEEP)
          # armlink has --keep=<section_id>, but is there an scatter equivalant ?
          #endif()

          if(SETTINGS_FIRST)
             set(SETTINGS "${SETTINGS}, +First")
          endif()

          set(TEMP "${TEMP}\n    *.o(${SETTINGS})")
        endif()

        if(SETTINGS_ANY)
          if(NOT SETTINGS_FLAGS)
            message(FATAL_ERROR ".ANY requires flags to be set.")
          endif()
          string(REPLACE ";" " " SETTINGS_FLAGS "${SETTINGS_FLAGS}")

          set(TEMP "${TEMP}\n    .ANY (${SETTINGS_FLAGS})")
        endif()
      endforeach()
    endif()

    #  if(SEC_TYPE)
    #    set(TEMP "${TEMP} (${SEC_TYPE})")
    #  endif()


    set(TEMP "${TEMP}")
    # ToDo: add patterns here.
    #       add symbols here.
    set(TEMP "${TEMP}\n  }")

    #  if(SEC_LMA)
    #    set(TEMP "${TEMP} > ${SEC_LMA}")
    #  endif()

    set(${SEC_CONTENT} "${${SEC_CONTENT}}\n${TEMP}\n" PARENT_SCOPE)
  endif()
endfunction()



# Strategy:
# - Find all
#set(OUT "MEMORY\n{")


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
    message("${region_start}")
    list(APPEND MEMORY_REGIONS_SORTED "${region_${region_start}}")
endforeach()
# sorting complete.


foreach(region ${MEMORY_REGIONS_SORTED})
  if("${region}" MATCHES "^{(.*)}$")
    cmake_parse_arguments(REGION "" "NAME;FLAGS" "" ${CMAKE_MATCH_1})
    set(REGION_${REGION_NAME}_FLAGS ${REGION_FLAGS})
    list(APPEND MEMORY_REGIONS_NAMES ${REGION_NAME})
  endif()
endforeach()

foreach(section ${SECTIONS})
  if("${section}" MATCHES "^{(.*)}$")
    cmake_parse_arguments(SEC "" "VMA;LMA" "" ${CMAKE_MATCH_1})
    string(REPLACE ";" "\;" section "${section}")
    if(NOT SEC_LMA)
      list(APPEND SECTIONS_${SEC_VMA} "${section}")
      message("++ SECTIONS_${SEC_VMA}")
    else()
      list(APPEND SECTIONS_${SEC_LMA}_${SEC_VMA} "${section}")
      message("++ SECTIONS_${SEC_LMA}_${SEC_VMA}")
    endif()
  endif()
endforeach()





foreach(settings ${SECTION_SETTINGS})
  if("${settings}" MATCHES "^{(.*)}$")
    cmake_parse_arguments(SETTINGS "" "SECTION" "" ${CMAKE_MATCH_1})
    if(NOT SECTION_${SETTINGS_SECTION}_INDEX)
      set(SECTION_${SETTINGS_SECTION}_INDEX 0)
    endif()

    set(SECTION_${SETTINGS_SECTION}_SETTINGS_${SECTION_${SETTINGS_SECTION}_INDEX} ${CMAKE_MATCH_1})
    math(EXPR SECTION_${SETTINGS_SECTION}_INDEX "${SECTION_${SETTINGS_SECTION}_INDEX} + 1")
  endif()
endforeach()

foreach(region ${MEMORY_REGIONS_SORTED})
  if("${region}" MATCHES "^{(.*)}$")
    cmake_parse_arguments(REGION "" "NAME;START;FLAGS" "" ${CMAKE_MATCH_1})
    set(OUT)
    message("== ${region}")
    message("%% SECTIONS_${REGION_NAME} - ${SECTIONS_${REGION_NAME}}")
    foreach(section ${SECTIONS_${REGION_NAME}})
      string(REGEX MATCH "^{(.*)}$" ignore "${section}")
      message("== ${CMAKE_MATCH_1}")
      section_content(REGION_NAME ${REGION_NAME} REGION_FLAGS ${REGION_FLAGS} CONTENT OUT ${CMAKE_MATCH_1})
      set(SECTIONS_${REGION_NAME})
    endforeach()

    foreach(section ${SECTIONS_${REGION_NAME}_${REGION_NAME}})
      string(REGEX MATCH "^{(.*)}$" ignore "${section}")
      message("== ${CMAKE_MATCH_1}")
      section_content(REGION_NAME ${REGION_NAME} REGION_FLAGS ${REGION_FLAGS} CONTENT OUT ${CMAKE_MATCH_1})
      set(SECTIONS_${REGION_NAME}_${REGION_NAME})
    endforeach()

    foreach(vma_region ${MEMORY_REGIONS_NAMES})
      message("%% SECTIONS_${REGION_NAME}_${vma_region} - ${SECTIONS_${REGION_NAME}_${vma_region}}")
      foreach(section ${SECTIONS_${REGION_NAME}_${vma_region}})
        string(REGEX MATCH "^{(.*)}$" ignore "${section}")
        message("== ${CMAKE_MATCH_1}")
        section_content(REGION_NAME ${REGION_NAME} REGION_FLAGS ${REGION_FLAGS} CONTENT OUT ${CMAKE_MATCH_1})
        set(SECTIONS_${REGION_NAME}_${vma_region})
      endforeach()
    endforeach()

    if(NOT "${OUT}" STREQUAL "")
      set(SCATTER_OUT "${SCATTER_OUT}\n${REGION_NAME} ${REGION_START}\n{")
      set(SCATTER_OUT "${SCATTER_OUT}\n${OUT}\n}")
    endif()
  endif()
endforeach()

#
#
#
#    memory_content(CONTENT OUT ${CMAKE_MATCH_1})
#  endif()
#endforeach()
#set(OUT "${OUT}\n}\n")
#
#
#foreach(section ${SECTIONS})
##  message("${section}")
#  if("${section}" MATCHES "^{(.*)}$")
#    message("${section}")
#    set(FLASH)
#    section_content(${CMAKE_MATCH_1})
#  endif()
#endforeach()



if(OUT_FILE)
  file(WRITE ${OUT_FILE} "${SCATTER_OUT}")
else()
  message("${SCATTER_OUT}")
endif()

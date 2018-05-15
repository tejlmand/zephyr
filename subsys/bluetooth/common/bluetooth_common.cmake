target_sources(bluetooth PRIVATE
    ${CMAKE_CURRENT_LIST_DIR}/dummy.c
    $<$<BOOL:${CONFIG_BT_DEBUG}>: ${CMAKE_CURRENT_LIST_DIR}/log.c >
    $<$<BOOL:${CONFIG_BT_RPA}>:   ${CMAKE_CURRENT_LIST_DIR}/rpa.c >
)

set_target_properties(bluetooth PROPERTIES EXCLUDE_FROM_ALL False)

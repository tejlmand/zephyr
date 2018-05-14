target_sources(bluetooth_common PRIVATE
    ${CMAKE_CURRENT_LIST_DIR}/dummy.c
    $<$<BOOL:${CONFIG_BT_DEBUG}>: ${CMAKE_CURRENT_LIST_DIR}/log.c >
    $<$<BOOL:${CONFIG_BT_RPA}>:   ${CMAKE_CURRENT_LIST_DIR}/rpa.c >
)

target_link_libraries(bluetooth_common subsys__bluetooth)
set_target_properties(bluetooth_common PROPERTIES EXCLUDE_FROM_ALL False)

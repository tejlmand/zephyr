 
target_sources(mesh PRIVATE
    ${CMAKE_CURRENT_LIST_DIR}/main.c >
    ${CMAKE_CURRENT_LIST_DIR}/madv.c >
    ${CMAKE_CURRENT_LIST_DIR}/mbeacon.c >
    ${CMAKE_CURRENT_LIST_DIR}/mnet.c >
    ${CMAKE_CURRENT_LIST_DIR}/mtransport.c >
    ${CMAKE_CURRENT_LIST_DIR}/mcrypto.c >
    ${CMAKE_CURRENT_LIST_DIR}/maccess.c >
    ${CMAKE_CURRENT_LIST_DIR}/mcfg_srv.c >
    ${CMAKE_CURRENT_LIST_DIR}/mhealth_srv.c >

    $<$<AND:$<BOOL:${CONFIG_BT_MESH}>,$<BOOL:${CONFIG_BT_MESH_LOW_POWER}>>:  ${CMAKE_CURRENT_LIST_DIR}/lpn.c >
    $<$<AND:$<BOOL:${CONFIG_BT_MESH}>,$<BOOL:${CONFIG_BT_MESH_FRIEND}>>:     ${CMAKE_CURRENT_LIST_DIR}/friend.c >
    $<$<AND:$<BOOL:${CONFIG_BT_MESH}>,$<BOOL:${CONFIG_BT_MESH_PROV}>>:       ${CMAKE_CURRENT_LIST_DIR}/prov.c >
    $<$<AND:$<BOOL:${CONFIG_BT_MESH}>,$<BOOL:${CONFIG_BT_MESH_PROXY}>>:      ${CMAKE_CURRENT_LIST_DIR}/proxy.c >
    $<$<AND:$<BOOL:${CONFIG_BT_MESH}>,$<BOOL:${CONFIG_BT_MESH_CFG_CLI}>>:    ${CMAKE_CURRENT_LIST_DIR}/cfg_cli.c >
    $<$<AND:$<BOOL:${CONFIG_BT_MESH}>,$<BOOL:${CONFIG_BT_MESH_HEALTH_CLI}>>: ${CMAKE_CURRENT_LIST_DIR}/health_cli.c >
    $<$<AND:$<BOOL:${CONFIG_BT_MESH}>,$<BOOL:${CONFIG_BT_MESH_SELF_TEST}>>:  ${CMAKE_CURRENT_LIST_DIR}/test.c >
    $<$<AND:$<BOOL:${CONFIG_BT_MESH}>,$<BOOL:${CONFIG_BT_MESH_SHELL}>>:      ${CMAKE_CURRENT_LIST_DIR}/shell.c >
)

target_link_libraries(mesh subsys__bluetooth)

set_target_properties(mesh PROPERTIES TRUE)


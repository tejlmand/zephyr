zephyr_populate_source_list(
  IFDEF:${CONFIG_BT_MESH} main.c
                          adv.c
                          beacon.c
                          net.c
                          transport.c
                          crypto.c
                          access.c
                          cfg_srv.c
                          health_srv.c
  IFDEF:${CONFIG_BT_MESH_LOW_POWER}  lpn.c
  IFDEF:${CONFIG_BT_MESH_FRIEND}     friend.c
  IFDEF:${CONFIG_BT_MESH_PROV}       prov.c
  IFDEF:${CONFIG_BT_MESH_PROXY}      proxy.c
  IFDEF:${CONFIG_BT_MESH_CFG_CLI}    cfg_cli.c
  IFDEF:${CONFIG_BT_MESH_HEALTH_CLI} health_cli.c
  IFDEF:${CONFIG_BT_MESH_SELF_TEST}  test.c
  IFDEF:${CONFIG_BT_MESH_SHELL}      shell.c
)

target_sources(bluetooth PRIVATE ${PRIVATE_SOURCES})
set_target_properties(bluetooth PROPERTIES TRUE)


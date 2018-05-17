zephyr_populate_source_list(
  dummy.c
  IFDEF:${CONFIG_BT_DEBUG} log.c
  IFDEF:${CONFIG_BT_RPA}   rpa.c
)

target_sources(bluetooth PRIVATE ${PRIVATE_SOURCES})

set_target_properties(bluetooth PROPERTIES EXCLUDE_FROM_ALL False)

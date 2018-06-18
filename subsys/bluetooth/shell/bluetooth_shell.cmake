
zephyr_list(SOURCES
            OUTPUT PRIVATE_SOURCES
            bt.c
            IFDEF:${CONFIG_BT_CONN}       gatt.c
            IFDEF:${CONFIG_BT_CTLR}       ll.c
                                          ticker.c
            IFDEF:${CONFIG_SOC_FLASH_NRF} flash.c
)

target_sources(subsys_bluetooth PRIVATE ${PRIVATE_SOURCES})

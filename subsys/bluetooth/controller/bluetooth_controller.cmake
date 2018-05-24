set_target_properties(bluetooth PROPERTIES EXCLUDE_FROM_ALL False)

zephyr_populate_source_list(
  util/mem.c
  util/memq.c
  util/mayfly.c
  util/util.c
  ticker/ticker.c
  ll_sw/ll_addr.c
  ll_sw/ll_tx_pwr.c
  crypto/crypto.c
  hci/hci_driver.c
  hci/hci.c
  IFDEF:${CONFIG_BT_CTLR_FILTER} ll_sw/ll_filter.c
  IFDEF:${CONFIG_SOC_FAMILY_NRF} hal/nrf5/cntr.c
                                 hal/nrf5/ecb.c
                                 hal/nrf5/radio/radio.c
                                 hal/nrf5/mayfly.c
                                 hal/nrf5/ticker.c
)

if(CONFIG_BT_LL_SW)
  zephyr_populate_source_list(
    APPEND
    ll_sw/ctrl.c
    ll_sw/ll.c
    IFDEF:${CONFIG_BT_BROADCASTER} ll_sw/ll_adv.c
    IFDEF:${CONFIG_BT_OBSERVER}    ll_sw/ll_scan.c
    IFDEF:${CONFIG_BT_CENTRAL}     ll_sw/ll_master.c
    IFDEF:${CONFIG_BT_CTLR_DTM}    ll_sw/ll_test.c
  )
endif()

target_sources(bluetooth PRIVATE   ${PRIVATE_SOURCES})

#
# The lines below can be updated in similar way, if principle is approved.
#
target_include_directories(bluetooth PRIVATE
  ${CMAKE_CURRENT_LIST_DIR}/.
  ${CMAKE_CURRENT_LIST_DIR}/util
  ${CMAKE_CURRENT_LIST_DIR}/hal
  ${CMAKE_CURRENT_LIST_DIR}/ticker
  ${CMAKE_CURRENT_LIST_DIR}/include
)

target_compile_definitions(bluetooth PRIVATE
  $<$<BOOL:${CONFIG_BT_CTLR_FAST_ENC}>: -Ofast >
)

# We must tell the linker not to remove the _hci_driver_init function during linking.
# Notice: This is done in the same file where we have the knowledge that hci_driver.c is added to
#         the library target.
target_link_libraries(bluetooth INTERFACE -u_hci_driver_init)

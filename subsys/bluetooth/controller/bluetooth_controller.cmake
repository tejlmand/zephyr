set_target_properties(bluetooth PROPERTIES EXCLUDE_FROM_ALL False)

target_sources(bluetooth PRIVATE
  ${CMAKE_CURRENT_LIST_DIR}/util/mem.c
  ${CMAKE_CURRENT_LIST_DIR}/util/memq.c
  ${CMAKE_CURRENT_LIST_DIR}/util/mayfly.c
  ${CMAKE_CURRENT_LIST_DIR}/util/util.c
  ${CMAKE_CURRENT_LIST_DIR}/ticker/ticker.c
  ${CMAKE_CURRENT_LIST_DIR}/ll_sw/ll_addr.c
  ${CMAKE_CURRENT_LIST_DIR}/ll_sw/ll_tx_pwr.c
  ${CMAKE_CURRENT_LIST_DIR}/crypto/crypto.c
  ${CMAKE_CURRENT_LIST_DIR}/hci/hci_driver.c
  ${CMAKE_CURRENT_LIST_DIR}/hci/hci.c
  $<$<BOOL:${CONFIG_BT_LL_SW}>: ${CMAKE_CURRENT_LIST_DIR}/ll_sw/ctrl.c >
  $<$<BOOL:${CONFIG_BT_LL_SW}>: ${CMAKE_CURRENT_LIST_DIR}/ll_sw/ll.c >

  $<$<AND:$<BOOL:${CONFIG_BT_LL_SW}>,$<BOOL:${CONFIG_BT_BROADCASTER}>>: ${CMAKE_CURRENT_LIST_DIR}/ll_sw/ll_adv.c >
  $<$<AND:$<BOOL:${CONFIG_BT_LL_SW}>,$<BOOL:${CONFIG_BT_OBSERVER}>>: ${CMAKE_CURRENT_LIST_DIR}/ll_sw/ll_scan.c >
  $<$<AND:$<BOOL:${CONFIG_BT_LL_SW}>,$<BOOL:${CONFIG_BT_CENTRAL}>>: ${CMAKE_CURRENT_LIST_DIR}/ll_sw/ll_master.c >
  $<$<AND:$<BOOL:${CONFIG_BT_LL_SW}>,$<BOOL:${CONFIG_BT_CTLR_DTM}>>: ${CMAKE_CURRENT_LIST_DIR}/ll_sw/ll_test.c >
  $<$<AND:$<BOOL:${CONFIG_BT_LL_SW}>,$<BOOL:${CONFIG_BT_CTLR_FILTER}>>: ${CMAKE_CURRENT_LIST_DIR}/ll_sw/ll_filter.c >
  $<$<AND:$<BOOL:${CONFIG_BT_LL_SW}>,$<BOOL:${CONFIG_SOC_FAMILY_NRF}>>: ${CMAKE_CURRENT_LIST_DIR}/hal/nrf5/cntr.c >
  $<$<AND:$<BOOL:${CONFIG_BT_LL_SW}>,$<BOOL:${CONFIG_SOC_FAMILY_NRF}>>: ${CMAKE_CURRENT_LIST_DIR}/hal/nrf5/ecb.c >
  $<$<AND:$<BOOL:${CONFIG_BT_LL_SW}>,$<BOOL:${CONFIG_SOC_FAMILY_NRF}>>: ${CMAKE_CURRENT_LIST_DIR}/hal/nrf5/radio/radio.c >
  $<$<AND:$<BOOL:${CONFIG_BT_LL_SW}>,$<BOOL:${CONFIG_SOC_FAMILY_NRF}>>: ${CMAKE_CURRENT_LIST_DIR}/hal/nrf5/mayfly.c >
  $<$<AND:$<BOOL:${CONFIG_BT_LL_SW}>,$<BOOL:${CONFIG_SOC_FAMILY_NRF}>>: ${CMAKE_CURRENT_LIST_DIR}/hal/nrf5/ticker.c >
)

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



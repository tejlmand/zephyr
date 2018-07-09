zephyr_list(SOURCES
            OUTPUT PRIVATE_SOURCES
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
  zephyr_list(SOURCES
              OUTPUT PRIVATE_SOURCES
              APPEND
              ll_sw/ctrl.c
              ll_sw/ll.c
              IFDEF:${CONFIG_BT_BROADCASTER} ll_sw/ll_adv.c
              IFDEF:${CONFIG_BT_OBSERVER}    ll_sw/ll_scan.c
              IFDEF:${CONFIG_BT_CENTRAL}     ll_sw/ll_master.c
              IFDEF:${CONFIG_BT_CTLR_DTM}    ll_sw/ll_test.c
  )
endif()

target_sources(subsys_bluetooth PRIVATE ${PRIVATE_SOURCES})

#
# The lines below can be updated in similar way, if principle is approved.
#
target_include_directories(subsys_bluetooth PRIVATE
  ${CMAKE_CURRENT_LIST_DIR}/.
  ${CMAKE_CURRENT_LIST_DIR}/util
  ${CMAKE_CURRENT_LIST_DIR}/hal
  ${CMAKE_CURRENT_LIST_DIR}/ticker
  ${CMAKE_CURRENT_LIST_DIR}/include
)

# This way of overriding compile flags for specific sources is safer than the
# link libraries. Source file specified flags are always added in the end by
# CMake, thus those flags will have precedence over any library flags.
# This automatically takes care of what is discussed in: #5097
# Also it prevents any unintended propagation of flags as described in: #5338
if(CONFIG_BT_CTLR_FAST_ENC)
  SET_SOURCE_FILES_PROPERTIES( ${PRIVATE_SOURCES} PROPERTIES COMPILE_FLAGS -Ofast)
endif()


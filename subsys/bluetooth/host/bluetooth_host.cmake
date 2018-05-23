
# Just use the default, where PREPEND_PATH is set to ${CMAKE_CURRENT_SOURCE_DIR} and output variable is PRIVATE_SOURCES
zephyr_populate_source_list(
  IFDEF:${CONFIG_BT_INTERNAL_STORAGE} storage.c # If the variable is true, then append sources
  IFDEF:${CONFIG_BT_HCI_RAW}          hci_raw.c
  IFDEF:${CONFIG_BT_DEBUG_MONITOR}    monitor.c
  IFDEF:${CONFIG_BT_TINYCRYPT_ECC}    hci_ecc.c
  IFDEF:${CONFIG_BT_A2DP}             a2dp.c
  IFDEF:${CONFIG_BT_AVDTP}            avdtp.c
  IFDEF:${CONFIG_BT_RFCOMM}           rfcomm.c
  IFDEF:${CONFIG_BT_TESTING}          testing.c
  IFDEF:${CONFIG_BT_BREDR}            keys_br.c
                                      l2cap_br.c 
                                      sdp.c
  IFDEF:${CONFIG_BT_HFP_HF}           hfp_hf.c
                                      at.c
)

if(CONFIG_BT_HCI_HOST)
  zephyr_populate_source_list(
    APPEND                                  # APPEND to the PRIVATE_SOURCES as we already did one call to populate_sources.
    uuid.c
    hci_core.c
    IFDEF:${CONFIG_BT_HOST_CRYPTO} crypto.c
    IFDEF:${CONFIG_BT_CONN}        conn.c
                                   l2cap.c
                                   att.c
                                   gatt.c
  )  

  if(CONFIG_BT_CONN)
    # Show some more optional arguments to the macro.
    zephyr_populate_source_list(
      PREPEND_PATH ${CMAKE_CURRENT_LIST_DIR}  # Specify a specific PREPEND_PATH to use for all sources provided as arguments.
      OUTPUT       SMP_SOURCES                # Specifying specific output variable, just to give an example
      IFDEF:${CONFIG_BT_SMP} smp.c
                             keys.c
      IFNDEF:${CONFIG_BT_SMP} smp_null.c
    )  
  endif()
endif()

zephyr_populate_source_exe_list(
  controller_sys_init.c
)

# Call the standard CMake function.
target_sources(bluetooth PRIVATE   ${PRIVATE_SOURCES} ${SMP_SOURCES}
                         INTERFACE ${INTERFACE_EXE_SOURCES}
)

# If internal storage is enabled, we link the subsys fs lib
target_link_libraries(bluetooth PUBLIC
                      "$<$<BOOL:${CONFIG_BT_INTERNAL_STORAGE}>:subsys__fs>" # Please disregard this for know, but focus on the source changes. Then this can change later.
)

if(CONFIG_BT_MESH)
  include(${CMAKE_CURRENT_LIST_DIR}/mesh/mesh.cmake)
endif()


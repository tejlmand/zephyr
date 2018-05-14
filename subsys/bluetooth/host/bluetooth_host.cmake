
# Using CMake standard way here actually allows for better handling of what populates private, public, interface properties
target_sources(bluetooth_host PRIVATE
    $<$<BOOL:${CONFIG_BT_INTERNAL_STORAGE}>: ${CMAKE_CURRENT_LIST_DIR}/storage.c >
    $<$<BOOL:${CONFIG_BT_HCI_RAW}>:          ${CMAKE_CURRENT_LIST_DIR}/hci_raw.c >
    $<$<BOOL:${CONFIG_BT_DEBUG_MONITOR}>:    ${CMAKE_CURRENT_LIST_DIR}/monitor.c >
    $<$<BOOL:${CONFIG_BT_TINYCRYPT_ECC}>:    ${CMAKE_CURRENT_LIST_DIR}/hci_ecc.c >
    $<$<BOOL:${CONFIG_BT_A2DP}>:             ${CMAKE_CURRENT_LIST_DIR}/a2dp.c >
    $<$<BOOL:${CONFIG_BT_AVDTP}>:            ${CMAKE_CURRENT_LIST_DIR}/avdtp.c >
    $<$<BOOL:${CONFIG_BT_RFCOMM}>:           ${CMAKE_CURRENT_LIST_DIR}/rfcomm.c >
    $<$<BOOL:${CONFIG_BT_TESTING}>:          ${CMAKE_CURRENT_LIST_DIR}/testing.c >
    $<$<BOOL:${CONFIG_BT_BREDR}>:            ${CMAKE_CURRENT_LIST_DIR}/keys_br.c >
    $<$<BOOL:${CONFIG_BT_BREDR}>:            ${CMAKE_CURRENT_LIST_DIR}/l2cap_br.c >
    $<$<BOOL:${CONFIG_BT_BREDR}>:            ${CMAKE_CURRENT_LIST_DIR}/sdp.c >
    $<$<BOOL:${CONFIG_BT_HFP_HF}>:           ${CMAKE_CURRENT_LIST_DIR}/hfp_hf.c >
    $<$<BOOL:${CONFIG_BT_HFP_HF}>:           ${CMAKE_CURRENT_LIST_DIR}/at.c >
    $<$<BOOL:${CONFIG_BT_HCI_HOST}>:         ${CMAKE_CURRENT_LIST_DIR}/uuid.c >
    $<$<BOOL:${CONFIG_BT_HCI_HOST}>:         ${CMAKE_CURRENT_LIST_DIR}/hci_core.c >

    $<$<AND:$<BOOL:${CONFIG_BT_HCI_HOST}>,$<BOOL:${CONFIG_BT_HOST_CRYPTO}>>: ${CMAKE_CURRENT_LIST_DIR}/crypto.c >
    $<$<AND:$<BOOL:${CONFIG_BT_HCI_HOST}>,$<BOOL:${CONFIG_BT_CONN}>>: ${CMAKE_CURRENT_LIST_DIR}/conn.c >
    $<$<AND:$<BOOL:${CONFIG_BT_HCI_HOST}>,$<BOOL:${CONFIG_BT_CONN}>>: ${CMAKE_CURRENT_LIST_DIR}/l2cap.c >
    $<$<AND:$<BOOL:${CONFIG_BT_HCI_HOST}>,$<BOOL:${CONFIG_BT_CONN}>>: ${CMAKE_CURRENT_LIST_DIR}/att.c >
    $<$<AND:$<BOOL:${CONFIG_BT_HCI_HOST}>,$<BOOL:${CONFIG_BT_CONN}>>: ${CMAKE_CURRENT_LIST_DIR}/gatt.c >

    $<$<AND:$<BOOL:${CONFIG_BT_HCI_HOST}>,$<BOOL:${CONFIG_BT_CONN}>,$<BOOL:${CONFIG_BT_SMP}>>: ${CMAKE_CURRENT_LIST_DIR}/smp.c >
    $<$<AND:$<BOOL:${CONFIG_BT_HCI_HOST}>,$<BOOL:${CONFIG_BT_CONN}>,$<BOOL:${CONFIG_BT_SMP}>>: ${CMAKE_CURRENT_LIST_DIR}/keys.c >
    $<$<AND:$<BOOL:${CONFIG_BT_HCI_HOST}>,$<BOOL:${CONFIG_BT_CONN}>,$<NOT:$<BOOL:${CONFIG_BT_SMP}>>>: ${CMAKE_CURRENT_LIST_DIR}/smp_null.c >
)

target_link_libraries(bluetooth_host
                      subsys__bluetooth
                      "$<$<BOOL:${CONFIG_BT_INTERNAL_STORAGE}>:subsys__fs>"
)

if(CONFIG_BT_MESH)
  include(${CMAKE_CURRENT_LIST_DIR}/mesh/mesh.cmake)
endif()


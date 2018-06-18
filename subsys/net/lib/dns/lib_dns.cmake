zephyr_list(SOURCES
  OUTPUT PRIVATE_SOURCES
  dns_pack.c
  IFDEF:${CONFIG_DNS_RESOLVER}    resolve.c
  IFDEF:${CONFIG_MDNS_RESPONDER}  mdns_responder.c
  IFDEF:${CONFIG_LLMNR_RESPONDER} llmnr_responder.c
)

target_sources(subsys_net PRIVATE ${PRIVATE_SOURCES})
target_include_directories(subsys_net PUBLIC ${CMAKE_CURRENT_LIST_DIR})

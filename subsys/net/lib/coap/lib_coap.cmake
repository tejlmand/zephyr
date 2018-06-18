zephyr_list(SOURCES
  OUTPUT PRIVATE_SOURCES
  coap.c
  coap_link_format.c
)

target_sources(subsys_net PRIVATE ${PRIVATE_SOURCES})
target_include_directories(subsys_net PRIVATE ${CMAKE_CURRENT_LIST_DIR})

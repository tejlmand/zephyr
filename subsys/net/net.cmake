zephyr_populate_source_list(
  IFDEF:${CONFIG_NET_BUF}             buf.c
  IFDEF:${CONFIG_NET_HOSTNAME_ENABLE} hostname.c
)

if(CONFIG_NETWORKING)
  zephyr_populate_source_list(APPEND IFDEF:${CONFIG_NET_RAW_MODE} ip/net_pkt.c)
endif()

target_sources(net PRIVATE ${PRIVATE_SOURCES})


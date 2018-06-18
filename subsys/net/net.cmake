zephyr_list(SOURCES
            OUTPUT PRIVATE_SOURCES
            IFDEF:${CONFIG_NET_BUF}             buf.c
            IFDEF:${CONFIG_NET_HOSTNAME_ENABLE} hostname.c
)

if(CONFIG_NETWORKING)
  zephyr_list(SOURCES APPEND
              OUTPUT PRIVATE_SOURCES
              IFDEF:${CONFIG_NET_RAW_MODE} ip/net_pkt.c)
endif()

target_sources(subsys_net PRIVATE ${PRIVATE_SOURCES})


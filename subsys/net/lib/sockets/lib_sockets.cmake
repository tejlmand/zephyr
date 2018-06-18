zephyr_list(SOURCES
            OUTPUT PRIVATE_SOURCES
            getaddrinfo.c
            sockets.c
            IFDEF:${CONFIG_NET_SOCKETS_SOCKOPT_TLS} sockets_tls.c
)
target_sources(subsys_net PRIVATE ${PRIVATE_SOURCES})
target_include_directories(subsys_net PUBLIC ${CMAKE_CURRENT_LIST_DIR})

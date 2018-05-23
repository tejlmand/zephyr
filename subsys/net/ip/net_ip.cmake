zephyr_populate_source_list(
  net_context.c
  net_core.c
  net_if.c
  net_pkt.c
  net_tc.c
  utils.c
  IFDEF:${CONFIG_NET_6LO}          6lo.c
  IFDEF:${CONFIG_NET_DHCPV4}       dhcpv4.c
  IFDEF:${CONFIG_NET_IPV4}         icmpv4.c       ipv4.c
  IFDEF:${CONFIG_NET_IPV6}         icmpv6.c nbr.c ipv6.c
  IFDEF:${CONFIG_NET_MGMT_EVENT}   net_mgmt.c
  IFDEF:${CONFIG_NET_ROUTE}        route.c
  IFDEF:${CONFIG_NET_RPL}          rpl.c
  IFDEF:${CONFIG_NET_RPL_MRHOF}    rpl-mrhof.c
  IFDEF:${CONFIG_NET_RPL_OF0}      rpl-of0.c
  IFDEF:${CONFIG_NET_SHELL}        net_shell.c
  IFDEF:${CONFIG_NET_STATISTICS}   net_stats.c
  IFDEF:${CONFIG_NET_TCP}          connection.c tcp.c
  IFDEF:${CONFIG_NET_TRICKLE}      trickle.c
  IFDEF:${CONFIG_NET_UDP}          connection.c udp.c
)

set_source_file_properties(${PRIVATE_SOURCES} PROPERTIES COMPILE_DEFINITIONS $<$<BOOL:${CONFIG_NEWLIB_LIBC}>:__LINUX_ERRNO_EXTENSIONS__>)
target_sources(net PRIVATE ${PRIVATE_SOURCES})
target_include_directories(net PRIVATE ${CMAKE_CURRENT_LIST_DIR})

include(${CMAKE_CURRENT_LIST_DIR}/l2/net_ip_l2.cmake)

if(CONFIG_NET_SHELL)
  zephyr_link_interface_ifdef(CONFIG_MBEDTLS mbedTLS)
  target_link_libraries(net $<$<BOOL:${CONFIG_MBEDTLS}>:mbedTLS>)
endif()

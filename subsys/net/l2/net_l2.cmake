target_include_directories(subsys_net PRIVATE ${CMAKE_CURRENT_LIST_DIR})

if(CONFIG_NET_L2_BT OR CONFIG_NET_L2_BT_SHELL)
  include_relative(bluetooth/net_bluetooth.cmake)
endif()

include_relative_ifdef(CONFIG_NET_L2_DUMMY dummy/net_dummy.cmake)

include_relative_ifdef(CONFIG_NET_L2_ETHERNET ethernet/net_l2_ethernet.cmake)

include_relative_ifdef(CONFIG_NET_L2_IEEE802154 ieee802154/net_l2_ieee802154.cmake)

include_relative_ifdef(CONFIG_NET_L2_OPENTHREAD openthread/net_l2_openthread.cmake)

if(CONFIG_NET_L2_WIFI_MGMT OR CONFIG_NET_L2_WIFI_SHELL)
  include_relative(wifi/net_wifi.cmake)
endif()

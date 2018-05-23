
if(CONFIG_NET_L2_BT OR
    CONFIG_NET_L2_BT_SHELL OR
    CONFIG_NET_L2_DUMMY OR
    CONFIG_NET_L2_WIFI_MGMT)

  zephyr_populate_source_list(
    IFDEF:${CONFIG_NET_L2_BT}         bluetooth.c
    IFDEF:${CONFIG_NET_L2_BT_SHELL}   bluetooth_shell.c
    IFDEF:${CONFIG_NET_L2_DUMMY}      dummy.c
    IFDEF:${CONFIG_NET_L2_WIFI_MGMT}  wifi_mgmt.c
    IFDEF:${CONFIG_NET_L2_WIFI_SHELL} wifi_shell.c
  )

  set_source_file_properties(${PRIVATE_SOURCES} PROPERTIES COMPILE_DEFINITIONS $<$<BOOL:${CONFIG_NEWLIB_LIBC}>:__LINUX_ERRNO_EXTENSIONS__>)
  target_sources(net PRIVATE ${PRIVATE_SOURCES})
  target_include_directories(net PRIVATE ${CMAKE_CURRENT_LIST_DIR})
endif()

if(CONFIG_NET_L2_ETHERNET)
  add_subdirectory(ethernet)
endif()

if(CONFIG_NET_L2_IEEE802154)
  add_subdirectory(ieee802154)
endif()

if(CONFIG_NET_L2_OPENTHREAD)
  add_subdirectory(openthread)
endif()

add_library(subsys_net STATIC "")

include(${CMAKE_CURRENT_LIST_DIR}/net.cmake)

if(CONFIG_NETWORKING)
  include(${CMAKE_CURRENT_LIST_DIR}/l2/net_l2.cmake)

  if(NOT CONFIG_NET_RAW_MODE)
    include(${CMAKE_CURRENT_LIST_DIR}/ip/net_ip.cmake)
  endif()
endif()

include(${CMAKE_CURRENT_LIST_DIR}/lib/net_lib.cmake)

target_link_libraries(subsys_net PUBLIC zephyr)

if(CONFIG_MBEDTLS)
  target_link_libraries(mbedTLS INTERFACE zephyr_interface)
  target_link_libraries(subsys_net PUBLIC mbedTLS)
endif()

if(CONFIG_NEWLIB_LIBC)
  target_compile_definitions(subsys_net PRIVATE __LINUX_ERRNO_EXTENSIONS__)
endif()

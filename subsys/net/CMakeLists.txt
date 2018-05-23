add_library(net STATIC "")
zephyr_append_cmake_library(net) # Needed to ensure the lib is linked inside --whole-archive.

include(${CMAKE_CURRENT_LIST_DIR}/net.cmake)

if(CONFIG_NETWORKING AND (NOT CONFIG_NET_RAW_MODE))
  include(${CMAKE_CURRENT_LIST_DIR}/ip/net_ip.cmake)
endif()

add_subdirectory(lib)

target_link_libraries(net zephyr kernel)

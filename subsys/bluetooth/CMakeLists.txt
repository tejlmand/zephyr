# We are just defining avaiable libaries created in the Bluetooth subsystem in order to provide
# easy understanding og what is available Mesh is part of host in this example.

add_library(bluetooth STATIC "")
target_include_directories(bluetooth PUBLIC ${CMAKE_CURRENT_LIST_DIR})
zephyr_append_cmake_library(bluetooth) # Needed to ensure the lib is linked inside --whole-archive.

include(${CMAKE_CURRENT_LIST_DIR}/common/bluetooth_common.cmake)

if(CONFIG_BT_HCI)
  include(${CMAKE_CURRENT_LIST_DIR}/host/bluetooth_host.cmake)
endif()

if(CONFIG_BT_CTLR)
  include(${CMAKE_CURRENT_LIST_DIR}/controller/bluetooth_controller.cmake)
endif()

add_subdirectory_ifdef(CONFIG_BT_SHELL shell)

target_link_libraries(bluetooth PUBLIC zephyr kernel net )

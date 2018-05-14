add_library(subsys__bluetooth INTERFACE)

target_include_directories(subsys__bluetooth INTERFACE ${CMAKE_CURRENT_SOURCE_DIR})

# We are just defining avaiable libaries created in the Bluetooth subsystem in order to provide
# easy understanding og what is available Mesh is part of host in this example.

add_library(bluetooth_common STATIC "") 
zephyr_append_cmake_library(bluetooth_common) # This is currently still needed in order to ensure the lib is linked inside --start-group and --end-group. Normally this would not be needed in a regular CMake setup, but haven't explorer complete zephyr build system to find out the reason for linking this way.
include(${CMAKE_CURRENT_LIST_DIR}/common/bluetooth_common.cmake)

if(CONFIG_BT_HCI)
  add_library(bluetooth_host STATIC "") 
  zephyr_append_cmake_library(bluetooth_host) # This is currently still needed in order to ensure the lib is linked inside --start-group and --end-group. Normally this would not be needed in a regular CMake setup, but haven't explorer complete zephyr build system to find out the reason for linking this way.
  include(${CMAKE_CURRENT_LIST_DIR}/host/bluetooth_host.cmake)
endif()

if(CONFIG_BT_MESH)
  add_library(mesh STATIC "") 
endif()

if(CONFIG_BT_CTLR)
  add_library(bluetooth_controller STATIC "") 
  zephyr_append_cmake_library(bluetooth_controller) # This is currently still needed in order to ensure the lib is linked inside --start-group and --end-group. Normally this would not be needed in a regular CMake setup, but haven't explorer complete zephyr build system to find out the reason for linking this way.
  include(${CMAKE_CURRENT_LIST_DIR}/controller/bluetooth_controller.cmake)
endif()

add_subdirectory_ifdef(CONFIG_BT_SHELL shell)

target_link_libraries(subsys__bluetooth INTERFACE zephyr_interface)

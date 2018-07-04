# We are just defining available libraries created in the Bluetooth subsystem in order to provide
# easy understanding of what is available. Mesh is part of host in this example.

add_library(subsys_bluetooth STATIC "")

include(${CMAKE_CURRENT_LIST_DIR}/common/bluetooth_common.cmake)

if(CONFIG_BT_HCI)
  include(${CMAKE_CURRENT_LIST_DIR}/host/bluetooth_host.cmake)
endif()

if(CONFIG_BT_CTLR)
  include(${CMAKE_CURRENT_LIST_DIR}/controller/bluetooth_controller.cmake)
endif()

if(CONFIG_BT_SHELL)
  include(${CMAKE_CURRENT_LIST_DIR}/shell/bluetooth_shell.cmake)
endif()

target_link_libraries(subsys_bluetooth PUBLIC zephyr subsys_net )
zephyr_set_property(TARGET subsys_bluetooth MEMORY_SPACE kernel)

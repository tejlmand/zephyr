zephyr_compile_definitions_ifdef(
  CONFIG_SOC_SERIES_NRF51X
  NRF51
  NRF51822
  )

target_sources(arch_arm PRIVATE ${CMAKE_CURRENT_LIST_DIR}/soc.c)

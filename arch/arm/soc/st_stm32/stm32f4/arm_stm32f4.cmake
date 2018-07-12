zephyr_include_directories(${ZEPHYR_BASE}/drivers)
zephyr_list(SOURCES
            OUTPUT PRIVATE_SOURCES
            soc.c
            IFDEF:${CONFIG_GPIO} soc_gpio.c
)

target_sources(arch_arm PRIVATE ${PRIVATE_SOURCES})

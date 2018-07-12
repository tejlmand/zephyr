set_property(GLOBAL PROPERTY PROPERTY_OUTPUT_FORMAT elf32-littleriscv)

include_relative(soc/riscv32_soc.cmake)
include_relative(core/riscv32_core.cmake)

# Temporary fix, to allow time for further investigation on
# link handling (extern symbol) when removing whole-archive.
zephyr_append_cmake_library(arch_riscv32)

# SPDX-License-Identifier: Apache-2.0

# The vector table must be placed at the start of SRAM
zephyr_linker_sources_ifdef(CONFIG_SRAM_VECTOR_TABLE
  RAM_SECTIONS
  SORT_KEY 0
  sram_vector_table.ld
)
zephyr_include_directories(${ZEPHYR_BASE}/drivers)
zephyr_sources(soc.c)

zephyr_linker_section(NAME .st_stm32f0x_vt VMA RAM LMA RAM TYPE NOLOAD NOINPUT)
# Working for ld, whatabout armlink ?
zephyr_linker_section_configure(SECTION .st_stm32f0x_vt
  OFFSET "_vector_end - _vector_start"
  SYMBOLS _ram_vector_start _ram_vector_end
)


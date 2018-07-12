add_definitions(-D__ZEPHYR_SUPERVISOR__)

add_library(arch_${ARCH} STATIC "")
target_link_libraries(arch_${ARCH} PUBLIC zephyr_interface)
zephyr_set_property(TARGET arch_${ARCH}
                    MEMORY_SPACE kernel
                    SYSINIT
)

include_relative(common/arch_common.cmake)

if( ${ARCH} STREQUAL arm )
  include_relative(${ARCH}/arch_${ARCH}.cmake)
else()
  # Not updated archs
  add_subdirectory(${ARCH})
  # To ensure a file is always present in arch not updated yet.
  target_sources(arch_${ARCH} PRIVATE $ENV{ZEPHYR_BASE}/misc/empty_file.c)
endif()

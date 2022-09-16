
include_guard(GLOBAL)

include(sysbuild_kconfig)

# 'SOC_ROOT' is a prioritized list of directories where socs may be
# found. It always includes ${ZEPHYR_BASE}/soc at the lowest priority.
list(APPEND SOC_ROOT ${ZEPHYR_BASE})

set(SOC_NAME   ${SB_CONFIG_SOC})
set(SOC_SERIES ${SB_CONFIG_SOC_SERIES})
set(SOC_FAMILY ${SB_CONFIG_SOC_FAMILY})

if("${SOC_SERIES}" STREQUAL "")
  set(SOC_PATH ${SOC_NAME})
else()
  set(SOC_PATH ${SOC_FAMILY}/${SOC_SERIES})
endif()

set_property(GLOBAL PROPERTY PROPERTY_OUTPUT_FORMAT elf32-xtensa-le)


if(SOC_FAMILY)
  include_relative(soc/${SOC_FAMILY}/xtensa_${SOC_FAMILY}.cmake)
else()
  include_relative(soc/${SOC_PATH}/xtensa_${SOC_PATH}.cmake)
endif()

include_relative(core/xtensa_core.cmake)

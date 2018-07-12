zephyr_cc_option_ifdef(CONFIG_LTO -flto)

set(ARCH_FOR_cortex-m0        armv6s-m        )
set(ARCH_FOR_cortex-m0plus    armv6s-m        )
set(ARCH_FOR_cortex-m3        armv7-m         )
set(ARCH_FOR_cortex-m4        armv7e-m        )
set(ARCH_FOR_cortex-m23       armv8-m.base    )
set(ARCH_FOR_cortex-m33       armv8-m.main+dsp)
set(ARCH_FOR_cortex-m33+nodsp armv8-m.main    )

if(ARCH_FOR_${GCC_M_CPU})
    set(ARCH_FLAG -march=${ARCH_FOR_${GCC_M_CPU}})
endif()

zephyr_compile_options(
  -mabi=aapcs
  ${ARCH_FLAG}
  )

if(SOC_FAMILY)
  include_relative(soc/${SOC_FAMILY}/arm_${SOC_FAMILY}.cmake)
else()
  include_relative(soc/${SOC_NAME}/arm_${SOC_NAME}.cmake)
endif()

include_relative(core/arm_core.cmake)

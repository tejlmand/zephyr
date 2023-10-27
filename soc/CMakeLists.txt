# SPDX-License-Identifier: Apache-2.0

# FIXME: SHADOW_VARS: Remove this once we have enabled -Wshadow globally.
#
# Limit warning of shadow variables to in-tree SoC files for now.
cmake_path(IS_PREFIX ZEPHYR_BASE "${SOC_DIR}" NORMALIZE _SOC_IS_IN_TREE)
if(_SOC_IS_IN_TREE)
  add_compile_options($<TARGET_PROPERTY:compiler,warning_shadow_variables>)
endif()
unset(_SOC_IS_IN_TREE)

if(HWMv1)
  if(EXISTS ${SOC_DIR}/${ARCH}/CMakeLists.txt)
    add_subdirectory(${SOC_DIR}/${ARCH} soc/${ARCH})
  else()
    add_subdirectory(${SOC_DIR}/${ARCH}/${SOC_PATH} soc/${ARCH}/${SOC_PATH})
  endif()
elseif(HWMv2)
  # Below is inclusion of HWMv2 SoC CMake lists.
  include(${CMAKE_CURRENT_LIST_DIR}/soc.v2.cmake)

  # Include all SoC roots except Zephyr, as we are already in the Zephyr SoC root.
  set(local_soc_root ${SOC_ROOT})
  list(REMOVE_ITEM local_soc_root ${ZEPHYR_BASE})
  foreach(root ${local_soc_root})
    cmake_path(GET root FILENAME name)
    # A SoC root for HWMv1 may not contain a CMakeLists.txt file on this so
    # let's check for existance before including.
    if(EXISTS ${root}/soc/CMakeLists.txt)
      add_subdirectory(${root}/soc soc/${name})
    endif()
  endforeach()
endif()

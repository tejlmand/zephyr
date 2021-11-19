# Copyright (c) 2021 Nordic Semiconductor
#
# SPDX-License-Identifier: Apache-2.0

if(CONFIG_SB_OPENAMP_REMOTE)
  if(NOT DEFINED openamp_remote_DTC_OVERLAY_FILE)
    if(DEFINED DTC_OVERLAY_FILE)
      set(openamp_remote_DTC_OVERLAY_FILE ${DTC_OVERLAY_FILE} CACHE STRING
          "Openamp remote DTC overlay, propagated from DTC_OVERLAY_FILE"
      )
    elseif(DEFINED ${app_name}_DTC_OVERLAY_FILE)
      set(openamp_remote_DTC_OVERLAY_FILE ${DTC_OVERLAY_FILE} CACHE STRING
          "Openamp remote DTC overlay, propagated from ${app_name}_DTC_OVERLAY_FILE"
      )
    endif()
  endif()

  ExternalZephyrProject_Add(
    APPLICATION openamp_remote
    SOURCE_DIR ${CMAKE_CURRENT_LIST_DIR}/remote
    BOARD ${CONFIG_SB_BOARD_openamp_remote}
    BUILD_ALWAYS True
  )
endif()

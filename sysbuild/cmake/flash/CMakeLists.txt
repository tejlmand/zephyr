# Copyright (c) 2021 Nordic Semiconductor
#
# SPDX-License-Identifier: Apache-2.0

set(runners_yaml "default: ${DEFAULT_IMAGE}\n")
list(APPEND runners_yaml "domains:\n")
foreach(image ${IMAGES})
  list(APPEND runners_yaml "  ${image}:\n")
  list(APPEND runners_yaml "    build_dir: ${${image}_BINARY_DIR}\n")
endforeach()
file(WRITE ${CMAKE_BINARY_DIR}/domain_runners.yaml ${runners_yaml})

# SPDX-License-Identifier: Apache-2.0

cmake_minimum_required(VERSION 3.20.0)

FILE(GLOB SOURCES src/*.c)

project(bluetooth_bt_buf_get_cmd_complete)

find_package(Zephyr COMPONENTS unittest HINTS $ENV{ZEPHYR_BASE})

include(${ZEPHYR_BASE}/tests/bluetooth/host/host_mocks.cmake)
include(${ZEPHYR_BASE}/tests/bluetooth/host/buf/mocks.cmake)

target_sources(testbinary PRIVATE ${host_module} ${module_mocks} ${host_mocks})

# Copyright (c) 2019 Lexmark International, Inc.
#
# SPDX-License-Identifier: Apache-2.0

set(SUPPORTED_EMU_PLATFORMS qemu)
set(QEMU_ARCH xilinx-aarch64)

set(QEMU_CPU_TYPE_${ARCH} cortex-r5)
set(QEMU_FLAGS_${ARCH}
  -nographic
  -machine arm-generic-fdt
  -dtb ${ZEPHYR_BASE}/boards/${ARCH}/${BOARD}/fdt-single_arch-zcu102-arm.dtb
  )

set(QEMU_KERNEL_OPTION
  "-device;loader,file=\$<TARGET_FILE:\${logical_target_for_zephyr_elf}>,cpu-num=4"
  "-device;loader,addr=0xff5e023c,data=0x80008fde,data-len=4"
  "-device;loader,addr=0xff9a0000,data=0x80000218,data-len=4"
  )

board_runner_args(qemu "--commander=qemu-system-xilinx-aarch64" "--cpu=cortex-r5" "--machine=arm-generic-fdt"
             "--dtb=${CMAKE_CURRENT_LIST_DIR}/fdt-single_arch-zcu102-arm.dtb"
             "--qemu_option=${CMAKE_CURRENT_LIST_DIR}/qemu_cortex_r5_option.yaml")

include(${ZEPHYR_BASE}/boards/common/qemu.board.cmake)

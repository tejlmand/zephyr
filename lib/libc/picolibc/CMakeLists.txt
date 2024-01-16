# SPDX-License-Identifier: Apache-2.0

add_library(c_picolibc
  assert.c
  cbprintf.c
  chk_fail.c
  errno_wrap.c
  exit.c
  locks.c
  stdio.c
  write.c
  )

zephyr_kernel_link_libraries(c_picolibc)
target_link_libraries(c_picolibc PRIVATE zephyr_interface c_common c)
set_target_properties(c_picolibc PROPERTIES LINK_INTERFACE_MULTIPLICITY 3)

# define __LINUX_ERRNO_EXTENSIONS__ so we get errno defines like -ESHUTDOWN
# used by the network stack
zephyr_compile_definitions(__LINUX_ERRNO_EXTENSIONS__)

if(NOT CONFIG_PICOLIBC_USE_MODULE)

  # Use picolibc provided with the toolchain

  # Create a C import library to apply dependencies

  add_library(c STATIC IMPORTED GLOBAL)

  # A kludge to use '-lc' in the linker command line while still allowing
  # dependencies. Depend on the file "-lc", so that appears in the linker
  # command line, and then create a file named "-lc" in the top level build
  # directory

  set_target_properties(c PROPERTIES IMPORTED_LOCATION "-lc")

  file(TOUCH ${CMAKE_BINARY_DIR}/-lc)

  target_link_libraries(c INTERFACE kernel)

  zephyr_compile_options(--specs=picolibc.specs)
  zephyr_compile_definitions(_POSIX_C_SOURCE=200809)
  zephyr_libc_link_libraries(--specs=picolibc.specs -lgcc)
  if(CONFIG_PICOLIBC_IO_FLOAT)
    zephyr_compile_definitions(PICOLIBC_DOUBLE_PRINTF_SCANF)
    zephyr_link_libraries(-DPICOLIBC_DOUBLE_PRINTF_SCANF)
  elseif(CONFIG_PICOLIBC_IO_MINIMAL)
    zephyr_compile_definitions(PICOLIBC_MINIMAL_PRINTF_SCANF)
    zephyr_link_libraries(-DPICOLIBC_MINIMAL_PRINTF_SCANF)
  elseif(CONFIG_PICOLIBC_IO_LONG_LONG)
    zephyr_compile_definitions(PICOLIBC_LONG_LONG_PRINTF_SCANF)
    zephyr_link_libraries(-DPICOLIBC_LONG_LONG_PRINTF_SCANF)
  else()
    zephyr_compile_definitions(PICOLIBC_INTEGER_PRINTF_SCANF)
    zephyr_link_libraries(-DPICOLIBC_INTEGER_PRINTF_SCANF)
  endif()

endif()

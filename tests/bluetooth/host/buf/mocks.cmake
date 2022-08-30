#
# Common include directories and source files for bluetooth/host/buf.c unit tests
#

include_directories(
  ${ZEPHYR_BASE}/tests/bluetooth/host/buf
)

SET( host_module
  ${ZEPHYR_BASE}/subsys/bluetooth/host/buf.c
)

SET( module_mocks
  ${ZEPHYR_BASE}/tests/bluetooth/host/buf/mocks/net_buf.c
  ${ZEPHYR_BASE}/tests/bluetooth/host/buf/mocks/iso.c
  ${ZEPHYR_BASE}/tests/bluetooth/host/buf/mocks/hci_core.c
  ${ZEPHYR_BASE}/tests/bluetooth/host/buf/mocks/net_buf_expects.c
)

/*
 * Copyright (c) 2022 Nordic Semiconductor ASA
 *
 * SPDX-License-Identifier: Apache-2.0
 */

#include <zephyr/zephyr.h>
#include <zephyr/bluetooth/buf.h>
#include "mocks/net_buf.h"
#include "mocks/net_buf_expects.h"
#include "mocks/buf_help_utils.h"

/* Rows count equals number of events x 2 */
#define TEST_PARAMETERS_LUT_ROWS_COUNT		60

/* LUT containing testing parameters that will be used
 * during each iteration to cover different scenarios
 */
static const struct testing_params testing_params_lut[] = {
	TEST_PARAM_PAIR_DEFINE(BT_HCI_EVT_UNKNOWN),
	TEST_PARAM_PAIR_DEFINE(BT_HCI_EVT_VENDOR),
	TEST_PARAM_PAIR_DEFINE(BT_HCI_EVT_INQUIRY_COMPLETE),
	TEST_PARAM_PAIR_DEFINE(BT_HCI_EVT_CONN_COMPLETE),
	TEST_PARAM_PAIR_DEFINE(BT_HCI_EVT_CONN_REQUEST),
	TEST_PARAM_PAIR_DEFINE(BT_HCI_EVT_DISCONN_COMPLETE),
	TEST_PARAM_PAIR_DEFINE(BT_HCI_EVT_AUTH_COMPLETE),
	TEST_PARAM_PAIR_DEFINE(BT_HCI_EVT_REMOTE_NAME_REQ_COMPLETE),
	TEST_PARAM_PAIR_DEFINE(BT_HCI_EVT_ENCRYPT_CHANGE),
	TEST_PARAM_PAIR_DEFINE(BT_HCI_EVT_REMOTE_FEATURES),
	TEST_PARAM_PAIR_DEFINE(BT_HCI_EVT_REMOTE_VERSION_INFO),
	TEST_PARAM_PAIR_DEFINE(BT_HCI_EVT_HARDWARE_ERROR),
	TEST_PARAM_PAIR_DEFINE(BT_HCI_EVT_ROLE_CHANGE),
	TEST_PARAM_PAIR_DEFINE(BT_HCI_EVT_PIN_CODE_REQ),
	TEST_PARAM_PAIR_DEFINE(BT_HCI_EVT_LINK_KEY_REQ),
	TEST_PARAM_PAIR_DEFINE(BT_HCI_EVT_LINK_KEY_NOTIFY),
	TEST_PARAM_PAIR_DEFINE(BT_HCI_EVT_DATA_BUF_OVERFLOW),
	TEST_PARAM_PAIR_DEFINE(BT_HCI_EVT_INQUIRY_RESULT_WITH_RSSI),
	TEST_PARAM_PAIR_DEFINE(BT_HCI_EVT_REMOTE_EXT_FEATURES),
	TEST_PARAM_PAIR_DEFINE(BT_HCI_EVT_SYNC_CONN_COMPLETE),
	TEST_PARAM_PAIR_DEFINE(BT_HCI_EVT_EXTENDED_INQUIRY_RESULT),
	TEST_PARAM_PAIR_DEFINE(BT_HCI_EVT_ENCRYPT_KEY_REFRESH_COMPLETE),
	TEST_PARAM_PAIR_DEFINE(BT_HCI_EVT_IO_CAPA_REQ),
	TEST_PARAM_PAIR_DEFINE(BT_HCI_EVT_IO_CAPA_RESP),
	TEST_PARAM_PAIR_DEFINE(BT_HCI_EVT_USER_CONFIRM_REQ),
	TEST_PARAM_PAIR_DEFINE(BT_HCI_EVT_USER_PASSKEY_REQ),
	TEST_PARAM_PAIR_DEFINE(BT_HCI_EVT_SSP_COMPLETE),
	TEST_PARAM_PAIR_DEFINE(BT_HCI_EVT_USER_PASSKEY_NOTIFY),
	TEST_PARAM_PAIR_DEFINE(BT_HCI_EVT_LE_META_EVENT),
	TEST_PARAM_PAIR_DEFINE(BT_HCI_EVT_AUTH_PAYLOAD_TIMEOUT_EXP)
};

BUILD_ASSERT(ARRAY_SIZE(testing_params_lut) == TEST_PARAMETERS_LUT_ROWS_COUNT);

/* Global iterator to iterate over the LUT */
static uint8_t testing_params_it;

/* Pointer to the current set of testing parameter */
struct testing_params const *current_test_vector;

/* Return the memory pool used for event memory allocation
 * based on compilation flags
 */
static struct net_buf_pool *get_memory_pool(bool discardable)
{
	struct net_buf_pool *memory_pool;

	if ((IS_ENABLED(CONFIG_BT_HCI_ACL_FLOW_CONTROL))) {
		memory_pool = bt_buf_get_evt_pool();
	} else {
		memory_pool = bt_buf_get_hci_rx_pool();
	}

	if (discardable) {
		memory_pool = bt_buf_get_discardable_pool();
	}

	return memory_pool;
}

/*
 *  Return value from bt_buf_get_evt() should not be NULL
 *
 *  Constraints:
 *   - All events except 'BT_HCI_EVT_CMD_COMPLETE', 'BT_HCI_EVT_CMD_STATUS' or
 *     'BT_HCI_EVT_NUM_COMPLETED_PACKETS'
 *   - Timeout value is a positive non-zero value
 *
 *  Expected behaviour:
 *   - net_buf_alloc() to be called with the correct memory allocation pool
 *     and the same timeout value passed to bt_buf_get_evt()
 *   - bt_buf_get_evt() returns the same reference returned by net_buf_alloc_fixed()
 */
static void test_returns_not_null_default_events(void)
{
	static struct net_buf expected_buf;
	struct net_buf *returned_buf;
	uint8_t returned_buffer_type;
	k_timeout_t timeout = Z_TIMEOUT_TICKS(1000);
	uint8_t evt = current_test_vector->evt;
	bool discardable = current_test_vector->discardable;

	zassert_true((evt != BT_HCI_EVT_CMD_COMPLETE && evt != BT_HCI_EVT_CMD_STATUS &&
		      evt != BT_HCI_EVT_NUM_COMPLETED_PACKETS),
		     "Invalid event type %u to this test", evt);

	net_buf_alloc_fixed_fake.return_val = &expected_buf;

	returned_buf = bt_buf_get_evt(evt, discardable, timeout);

	expect_single_call_net_buf_alloc(get_memory_pool(discardable), &timeout);
	expect_single_call_net_buf_reserve(&expected_buf);
	expect_not_called_net_buf_ref();

	zassert_equal(returned_buf, &expected_buf,
		      "bt_buf_get_evt() returned incorrect buffer pointer value");

	returned_buffer_type = bt_buf_get_type(returned_buf);
	zassert_equal(returned_buffer_type, BT_BUF_EVT,
		      "bt_buf_get_evt() returned incorrect buffer type %u, expected %u (%s)",
		      returned_buffer_type, BT_BUF_EVT, STRINGIFY(BT_BUF_EVT));
}

/*
 *  Return value from bt_buf_get_evt() should be NULL
 *
 *  Constraints:
 *   - All events except 'BT_HCI_EVT_CMD_COMPLETE', 'BT_HCI_EVT_CMD_STATUS' or
 *     'BT_HCI_EVT_NUM_COMPLETED_PACKETS'
 *   - Timeout value is a positive non-zero value
 *
 *  Expected behaviour:
 *   - net_buf_alloc() to be called with the correct memory allocation pool
 *     and the same timeout value passed to bt_buf_get_evt()
 *   - bt_buf_get_evt() returns NULL
 */
static void test_returns_null_default_events(void)
{
	struct net_buf *returned_buf;
	k_timeout_t timeout = Z_TIMEOUT_TICKS(1000);
	uint8_t evt = current_test_vector->evt;
	bool discardable = current_test_vector->discardable;

	zassert_true((evt != BT_HCI_EVT_CMD_COMPLETE && evt != BT_HCI_EVT_CMD_STATUS &&
		      evt != BT_HCI_EVT_NUM_COMPLETED_PACKETS),
		     "Invalid event type %u to this test", evt);

	net_buf_alloc_fixed_fake.return_val = NULL;

	returned_buf = bt_buf_get_evt(evt, discardable, timeout);

	expect_single_call_net_buf_alloc(get_memory_pool(discardable), &timeout);
	expect_not_called_net_buf_reserve();
	expect_not_called_net_buf_ref();

	zassert_is_null(returned_buf,
			"bt_buf_get_evt() returned non-NULL value while expecting NULL");
}

/* Initialize test variables */
static void test_round_initialization(void)
{
	testing_params_it = 0;
	current_test_vector = NULL;
}

/* Setup test variables */
static void unit_test_setup(void)
{
	zassert_true((testing_params_it < (ARRAY_SIZE(testing_params_lut))),
		     "Invalid testing parameters index %u", testing_params_it);
	current_test_vector = &testing_params_lut[testing_params_it];
	testing_params_it++;

	/* Register resets */
	NET_BUFF_FFF_FAKES_LIST(RESET_FAKE);
}

/* Each run will use a testing parameters set from LUT
 * This can help in identifying which parameters fails instead of using
 * a single 'void' test function and call the parameterized function.
 */
ztest_register_test_suite(bt_buf_get_evt_default_type_returns_not_null, NULL,
			  ztest_unit_test(test_round_initialization),
			  LISTIFY(TEST_PARAMETERS_LUT_ROWS_COUNT, REGISTER_SETUP_TEARDOWN, (,),
				  test_returns_not_null_default_events));

ztest_register_test_suite(bt_buf_get_evt_default_type_returns_null, NULL,
			  ztest_unit_test(test_round_initialization),
			  LISTIFY(TEST_PARAMETERS_LUT_ROWS_COUNT, REGISTER_SETUP_TEARDOWN, (,),
				  test_returns_null_default_events));

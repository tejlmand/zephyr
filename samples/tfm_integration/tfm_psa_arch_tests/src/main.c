/*
 * Copyright (c) 2019 Linaro Limited
 *
 * SPDX-License-Identifier: Apache-2.0
 */

#include <zephyr.h>
#include <sys/printk.h>
#include "cmsis_os2.h"
#include "tfm_ns_interface.h"

/**
 * \brief This symbol is the entry point provided by the PSA API compliance
 *        test libraries
 */
extern void val_entry(void);

static u64_t test_app_stack[(3u * 1024u) / (sizeof(u64_t))];
static const osThreadAttr_t thread_attr = {
	.name = "test_thread",
	.stack_mem = test_app_stack,
	.stack_size = sizeof(test_app_stack),
};

static osStatus_t     status;
static osThreadId_t   thread_id;
static osThreadFunc_t thread_func;

void main(void)
{
	/* Initialize the TFM NS interface */
	tfm_ns_interface_init();

	thread_func = (osThreadFunc_t)val_entry;
	thread_id = osThreadNew(thread_func, NULL, &thread_attr);

	(void)status;
	(void)thread_id;
	(void)thread_func;

	printk("TF-M PSA Arch Tests with Zephyr on %s\n", CONFIG_BOARD);
}

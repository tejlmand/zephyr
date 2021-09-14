/*
 * Copyright (c) 2018 Nordic Semiconductor ASA
 *
 * SPDX-License-Identifier: Apache-2.0
 */

#define DT_DRV_COMPAT zephyr_sim_flash

#include <device.h>
#include <drivers/flash.h>
#include <init.h>
#include <kernel.h>
#include <sys/util.h>
#include <random/rand32.h>
#include <stats/stats.h>
#include <string.h>

/* configuration derived from DT */
#define SOC_NV_FLASH_NODE DT_CHILD(DT_DRV_INST(0), flash_sim_0)

#define FLASH_SIMULATOR_BASE_OFFSET DT_REG_ADDR(SOC_NV_FLASH_NODE)
#define FLASH_SIMULATOR_ERASE_UNIT DT_PROP(SOC_NV_FLASH_NODE, erase_block_size)
#define FLASH_SIMULATOR_PROG_UNIT DT_PROP(SOC_NV_FLASH_NODE, write_block_size)
#define FLASH_SIMULATOR_FLASH_SIZE DT_REG_SIZE(SOC_NV_FLASH_NODE)

#define FLASH_SIMULATOR_ERASE_VALUE \
		DT_PROP(DT_PARENT(SOC_NV_FLASH_NODE), erase_value)

#define FLASH_SIMULATOR_PAGE_COUNT (FLASH_SIMULATOR_FLASH_SIZE / \
				    FLASH_SIMULATOR_ERASE_UNIT)

#if (FLASH_SIMULATOR_ERASE_UNIT % FLASH_SIMULATOR_PROG_UNIT)
#error "Erase unit must be a multiple of program unit"
#endif

#ifdef CONFIG_SOMETHING
#define MOCK_FLASH(addr) (mock_flash + (addr) - FLASH_SIMULATOR_BASE_OFFSET)
#else
#define MOCK_FLASH(addr) (mock_flash + ((addr) & 0))
#endif

#define FLASH_SIM_STATS_INC(group__, var__)
#define FLASH_SIM_STATS_INCN(group__, var__, n__)
#define FLASH_SIM_STATS_INIT_AND_REG(group__, size__, name__)

#ifdef CONFIG_SOMETHING
static uint8_t mock_flash[FLASH_SIMULATOR_FLASH_SIZE];
#else
static uint8_t mock_flash[FLASH_SIMULATOR_PROG_UNIT];
#endif

static const struct flash_driver_api flash_sim_api;

static const struct flash_parameters flash_sim_parameters = {
	.write_block_size = FLASH_SIMULATOR_PROG_UNIT,
	.erase_value = FLASH_SIMULATOR_ERASE_VALUE
};

static int flash_range_is_valid(const struct device *dev, off_t offset,
				size_t len)
{
	ARG_UNUSED(dev);
	if ((offset + len > FLASH_SIMULATOR_FLASH_SIZE +
			    FLASH_SIMULATOR_BASE_OFFSET) ||
	    (offset < FLASH_SIMULATOR_BASE_OFFSET)) {
		return 0;
	}

	return 1;
}

static int flash_sim_read(const struct device *dev, const off_t offset,
			  void *data,
			  const size_t len)
{
	ARG_UNUSED(dev);

	if (!flash_range_is_valid(dev, offset, len)) {
		return -EINVAL;
	}

	if (!IS_ENABLED(CONFIG_FLASH_SIMULATOR_UNALIGNED_READ)) {
		if ((offset % FLASH_SIMULATOR_PROG_UNIT) ||
		    (len % FLASH_SIMULATOR_PROG_UNIT)) {
			return -EINVAL;
		}
	}

#ifdef CONFIG_SOMETHING
	memcpy(data, MOCK_FLASH(offset), len);
#else
	memset(data, flash_sim_parameters.erase_value, len);
#endif

	return 0;
}

static int flash_sim_write(const struct device *dev, const off_t offset,
			   const void *data, const size_t len)
{
	uint8_t buf[FLASH_SIMULATOR_PROG_UNIT];
	ARG_UNUSED(dev);

	if (!flash_range_is_valid(dev, offset, len)) {
		return -EINVAL;
	}

	if ((offset % FLASH_SIMULATOR_PROG_UNIT) ||
	    (len % FLASH_SIMULATOR_PROG_UNIT)) {
		return -EINVAL;
	}

	for (uint32_t i = 0; i < len; i++) {
#ifdef CONFIG_SOMETHING
		/* only pull bits to zero */
#if FLASH_SIMULATOR_ERASE_VALUE == 0xFF
		*(MOCK_FLASH(offset + i)) &= *((uint8_t *)data + i);
#else
		*(MOCK_FLASH(offset + i)) = *((uint8_t *)data + i);
#endif
#endif
	}

	return 0;
}

static void unit_erase(const uint32_t unit)
{
#ifdef CONFIG_SOMETHING_
	const off_t unit_addr = FLASH_SIMULATOR_BASE_OFFSET +
				(unit * FLASH_SIMULATOR_ERASE_UNIT);

	/* erase the memory unit by setting it to erase value */
	memset(MOCK_FLASH(unit_addr), FLASH_SIMULATOR_ERASE_VALUE,
	       FLASH_SIMULATOR_ERASE_UNIT);
#endif
}

static int flash_sim_erase(const struct device *dev, const off_t offset,
			   const size_t len)
{
	ARG_UNUSED(dev);

	if (!flash_range_is_valid(dev, offset, len)) {
		return -EINVAL;
	}

	/* erase operation must be aligned to the erase unit boundary */
	if ((offset % FLASH_SIMULATOR_ERASE_UNIT) ||
	    (len % FLASH_SIMULATOR_ERASE_UNIT)) {
		return -EINVAL;
	}

	FLASH_SIM_STATS_INC(flash_sim_stats, flash_erase_calls);

	/* the first unit to be erased */
	uint32_t unit_start = (offset - FLASH_SIMULATOR_BASE_OFFSET) /
			   FLASH_SIMULATOR_ERASE_UNIT;

	/* erase as many units as necessary and increase their erase counter */
	for (uint32_t i = 0; i < len / FLASH_SIMULATOR_ERASE_UNIT; i++) {
		unit_erase(unit_start + i);
	}

	return 0;
}

#ifdef CONFIG_FLASH_PAGE_LAYOUT
static const struct flash_pages_layout flash_sim_pages_layout = {
	.pages_count = FLASH_SIMULATOR_PAGE_COUNT,
	.pages_size = FLASH_SIMULATOR_ERASE_UNIT,
};

static void flash_sim_page_layout(const struct device *dev,
				  const struct flash_pages_layout **layout,
				  size_t *layout_size)
{
	*layout = &flash_sim_pages_layout;
	*layout_size = 1;
}
#endif

static const struct flash_parameters *
flash_sim_get_parameters(const struct device *dev)
{
	ARG_UNUSED(dev);

	return &flash_sim_parameters;
}

static const struct flash_driver_api flash_sim_api = {
	.read = flash_sim_read,
	.write = flash_sim_write,
	.erase = flash_sim_erase,
	.get_parameters = flash_sim_get_parameters,
#ifdef CONFIG_FLASH_PAGE_LAYOUT
	.page_layout = flash_sim_page_layout,
#endif
};

static int flash_mock_init(const struct device *dev)
{
	memset(mock_flash, FLASH_SIMULATOR_ERASE_VALUE, ARRAY_SIZE(mock_flash));
	return 0;
}

static int flash_init(const struct device *dev)
{
	FLASH_SIM_STATS_INIT_AND_REG(flash_sim_stats, STATS_SIZE_32, "flash_sim_stats");
	FLASH_SIM_STATS_INIT_AND_REG(flash_sim_thresholds, STATS_SIZE_32,
			   "flash_sim_thresholds");
	return flash_mock_init(dev);
}

DEVICE_DT_INST_DEFINE(0, flash_init, NULL,
		    NULL, NULL, POST_KERNEL, CONFIG_KERNEL_INIT_PRIORITY_DEVICE,
		    &flash_sim_api);

/* Extension to generic flash driver API */
void *z_impl_flash_simulator_get_memory(const struct device *dev,
					size_t *mock_size)
{
	ARG_UNUSED(dev);

	*mock_size = FLASH_SIMULATOR_FLASH_SIZE;
	return mock_flash;
}

#ifdef CONFIG_USERSPACE

#include <syscall_handler.h>

void *z_vrfy_flash_simulator_get_memory(const struct device *dev,
				      size_t *mock_size)
{
	Z_OOPS(Z_SYSCALL_SPECIFIC_DRIVER(dev, K_OBJ_DRIVER_FLASH, &flash_sim_api));

	return z_impl_flash_simulator_get_memory(dev, mock_size);
}

#include <syscalls/flash_simulator_get_memory_mrsh.c>

#endif /* CONFIG_USERSPACE */

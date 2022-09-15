# SPDX-License-Identifier: Apache-2.0
#
# Copyright (c) 2023, Nordic Semiconductor ASA

# This file contains adding of hw model v2 SoC CMake lists.
# Inclusion must be guarded on SoC name, SoC Family, or similar
add_subdirectory_ifdef(CONFIG_SOC_FAMILY_NRF v2/nordic_nrf)

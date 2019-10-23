.. _tfm_psa_arch_api:

TF-M psa-arch-tests
###################

Overview
********
This is a sample for Zephyr PSA level 1 with TF-M integrated.

Zephyr uses Trusted Firmware (TF-M) Platform Security Architecture (PSA) APIs
to run in a secure configuration with Zephyr itself in a non-secure configuration.
The sample prints test info to the console as a multi-thread application.

The psa-arch-tests provides different test suite configurations:
``crypto``, ``protected_storage``, or ``initial_attestation``, as set in
the sample's ``prj.conf`` file, for example:

.. code-block:: bash

   CONFIG_PSA_API_TEST_SUITE="crypto"

Building and Running
********************

This project outputs test status and info to the console. It can be built and
executed on MPS2+ AN521.

On MPS2+ AN521:
===============

#. Build Zephyr with a non-secure configuration (``-DBOARD=mps2_an521_nonsecure``).

   .. code-block:: bash

      cd $ZEPHYR_ROOT/samples/tfm_integration/tfm_psa_arch_tests/
      mkdir build
      cd build
      cmake -GNinja -DBOARD=mps2_an521_nonsecure ..
      ninja -v

#. Copy application binary files (mcuboot.bin and tfm_sign.bin) to ``<MPS2 device name>/SOFTWARE/``.
#. Open ``<MPS2 device name>/MB/HBI0263C/AN521/images.txt``. Edit the ``AN521/images.txt`` file as follows:

   .. code-block:: bash

      TITLE: Versatile Express Images Configuration File

      [IMAGES]
      TOTALIMAGES: 2 ;Number of Images (Max: 32)

      IMAGE0ADDRESS: 0x10000000
      IMAGE0FILE: \SOFTWARE\mcuboot.bin  ; BL2 bootloader

      IMAGE1ADDRESS: 0x10080000
      IMAGE1FILE: \SOFTWARE\tfm_sign.bin ; TF-M with application binary blob

#. Reset MPS2+ board.

On V2M Musca B1:
================

#. Build Zephyr with a non-secure configuration (``-DBOARD=v2m_musca_b1_nonsecure``).

   .. code-block:: bash

      cd $ZEPHYR_ROOT/samples/tfm_integration/tfm_psa_arch_tests/
      mkdir build
      cd build
      cmake -GNinja -DBOARD=v2m_musca_b1_nonsecure ..
      ninja -v

#. The binary file ``tfm_zephyr.hex`` will be signed and combined
   automatically into the build folder.
#. Connect the USB cable from your development system
   to the Musca B1 board, and press the power-on button.
#. Copy ``tfm_zephyr.hex`` to the root of the MUSCA_B USB mass storage drive.
#. Reset the board.


Sample Output
=============

.. code-block:: console

  [INF] Swap type: none
  [INF] Bootloader chainload address offset: 0x80000
  [INF] Jumping to the first image slot
  [Sec Thread] Secure image initializing!
  ***** Booting Zephyr OS build zephyr-v2.0.0-1327-g39d2abdb5270 *****
  TF-M PSA Arch Tests with Zephyr on mps2_an521_nonsecure

  ***** PSA Architecture Test Suite - Version 0.9 *****

  Running.. Attestation Suite
  ******************************************

  TEST: 801 | DESCRIPTION: Testing initial attestation APIs
  [Info] Executing tests from non-secure
  [Check 1] Test psa_initial_attestation_get_token with Challenge 32
  [Check 2] Test psa_initial_attestation_get_token with Challenge 48
  [Check 3] Test psa_initial_attestation_get_token with Challenge 64
  [Check 4] Test psa_initial_attestation_get_token with zero challenge size
  [Check 5] Test psa_initial_attestation_get_token with small challenge size
  [Check 6] Test psa_initial_attestation_get_token with invalid challenge size
  [Check 7] Test psa_initial_attestation_get_token with large challenge size
  [Check 8] Test psa_initial_attestation_get_token with zero as token size
  [Check 9] Test psa_initial_attestation_get_token with small token size
  [Check 10] Test psa_initial_attestation_get_token_size with Challenge 32
  [Check 11] Test psa_initial_attestation_get_token_size with Challenge 48
  [Check 12] Test psa_initial_attestation_get_token_size with Challenge 64
  [Check 13] Test psa_initial_attestation_get_token_size with zero challenge size
  [Check 14] Test psa_initial_attestation_get_token_size with small challenge size
  [Check 15] Test psa_initial_attestation_get_token_size with invalid challenge size
  [Check 16] Test psa_initial_attestation_get_token_size with large challenge size
  TEST RESULT: PASSED

  ******************************************

  ************ Attestation Suite Report **********
  TOTAL TESTS     : 1
  TOTAL PASSED    : 1
  TOTAL SIM ERROR : 0
  TOTAL FAILED    : 0
  TOTAL SKIPPED   : 0
  ******************************************

  Entering standby.

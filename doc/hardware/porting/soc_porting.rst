.. _soc_porting_guide:

SoC Porting Guide
###################

To add Zephyr support for a new :term:`SoC`, you at least need a *SoC directory*
with various files in it. Also a SoC :file:`.dtsi` in
:zephyr_file:`dts/<ARCH>/<VENDOR>` is required.

Architecture
============

See :ref:`architecture_porting_guide`.


Create your SoC directory
*************************

Blah blah blah

.. note::
  A ``<VENDOR>`` subdirectory is mandatory if contributing your SoC
  to Zephyr, but if your SoC is placed in a local repo, then any folder
  structure under ``<your-repo>/soc`` is permitted.
  If the vendor is defined in the list in
  :zephyr_file:`dts/bindings/vendor-prefixes.txt` then you must use
  that vendor prefix as ``<VENDOR>``.

Your SoC directory should look like this:

.. code-block:: none

   soc/<VENDOR>/<soc-name>
   ├── soc.yml
   ├── soc.h
   ├── CMakeLists.txt
   ├── Kconfig
   ├── Kconfig.soc
   └── Kconfig.defconfig

Replace ``<soc-name>`` with your board's name, of course.

##### Update below #######

The mandatory files are:

#. :file:`board.yml`: a YAML file describing the high-level meta data of the
   boards such as the boards names, their SoCs, and variants.
   CPU clusters for multi-core SoCs are not described in this file as they are
   inherited from the SoC's YAML description.

#. :file:`plank.dts` or :file:`plank_<identifier>.dts`: a hardware description
   in :ref:`devicetree <dt-guide>` format. This declares your SoC, connectors,
   and any other hardware components such as LEDs, buttons, sensors, or
   communication peripherals (USB, BLE controller, etc).

#. :file:`Kconfig.plank`: the base software configuration for selecting SoC and
   other board and SoC related settings. Kconfig settings outside of the board
   and SoC tree must not be selected. To select general Zephyr Kconfig settings
   the :file:`Kconfig` file must be used.


The optional files are:

- :file:`Kconfig`, :file:`Kconfig.defconfig` software configuration in
  :ref:`kconfig` formats. This provides default settings for software features
  and peripheral drivers.
- :file:`plank_defconfig` and :file:`plank_<identifier>_defconfig`: software
  configuration in Kconfig ``.conf`` format.
- :file:`board.cmake`: used for :ref:`flash-and-debug-support`
- :file:`CMakeLists.txt`: if you need to add additional source files to
  your build.
- :file:`doc/index.rst`, :file:`doc/plank.png`: documentation for and a picture
  of your board. You only need this if you're :ref:`contributing-your-board` to
  Zephyr.
- :file:`plank.yaml`: a YAML file with miscellaneous metadata used by the
  :ref:`twister_script`.

Board identifiers of the form ``<soc>/<cpucluster>/<variant>`` are sanitized so
that ``/`` is replaced with ``_`` when used for filenames, for example:
``soc1/foo`` becomes ``soc1_foo`` when used in filenames.

Write your SoC YAML
*********************

The board YAML file describes the board at a high level.
This includes the SoC, board variants, and board revisions.

Detailed configurations, such as hardware description and configuration are done
in devicetree and Kconfig.

The skeleton of the board YAML file is:

.. code-block:: yaml

   board:
     name: <board-name>
     vendor: <board-vendor>
     revision:
       format: <major.minor.patch|letter|number|custom>
       default: <default-revision-value>
       exact: <true|false>
       revisions:
       - name: <revA>
       - name: <revB>
         ...
     socs:
     - name: <soc-1>
       variants:
       - name: <variant-1>
       - name: <variant-2>
         variants:
         - name: <sub-variant-2-1>
           ...
     - name: <soc-2>
       ...

It is possible to have multiple boards located in the board folder.
If multiple boards are placed in the same board folder, then the file
:file:`board.yml` must describe those in a list as:

.. code-block:: yaml

   boards:
   - name: <board-name-1>
     vendor: <board-vendor>
     ...
   - name: <board-name-2>
     vendor: <board-vendor>
     ...
   ...


Write your devicetree
*********************

Write Kconfig files
*******************

General recommendations
***********************

Multiple CPU clusters
*********************

.. _contributing-your-soc:

Contributing your SoC
*********************

If you want to contribute your board to Zephyr, first -- thanks!

There are some extra things you'll need to do:

#. Make sure you've followed all the :ref:`porting-general-recommendations`.
   They are requirements for boards included with Zephyr.

#. Prepare a pull request adding your SoC which follows the
   :ref:`contribute_guidelines`.


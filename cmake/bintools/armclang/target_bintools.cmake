# List of format the tool supports for converting, for example,
# GNU tools uses objectcopyy, which supports the following: ihex, srec, binary
set_property(TARGET bintools PROPERTY elfconvert_formats ihex binary)

# armclang toolchain does not support all options in a single command
# Therefore a CMake script is used, so that multiple commands can be executed
# successively.
set_property(TARGET bintools PROPERTY elfconvert_command ${CMAKE_COMMAND})

set_property(TARGET bintools PROPERTY elfconvert_flag
                                      -DFROMELF=${CMAKE_FROMELF}
)

set_property(TARGET bintools PROPERTY elfconvert_flag_final
                                      -P ${CMAKE_CURRENT_LIST_DIR}/elfconvert_command.cmake)

set_property(TARGET bintools PROPERTY elfconvert_flag_strip_all "-DSTRIP_ALL=True")
set_property(TARGET bintools PROPERTY elfconvert_flag_strip_debug "-DSTRIP_DEBUG=True")

set_property(TARGET bintools PROPERTY elfconvert_flag_intarget "-DINTARGET=")
set_property(TARGET bintools PROPERTY elfconvert_flag_outtarget "-DOUTTARGET=")

set_property(TARGET bintools PROPERTY elfconvert_flag_section_remove "-DREMOVE_SECTION=")
set_property(TARGET bintools PROPERTY elfconvert_flag_section_only "-DONLY_SECTION=")

# mwdt doesn't handle rename, consider adjusting abstraction.
set_property(TARGET bintools PROPERTY elfconvert_flag_section_rename "-DRENAME_SECTION=")

set_property(TARGET bintools PROPERTY elfconvert_flag_gapfill "-DGAP_FILL=")
set_property(TARGET bintools PROPERTY elfconvert_flag_srec_len "-DSREC_LEN=")

set_property(TARGET bintools PROPERTY elfconvert_flag_infile "-DINFILE=")
set_property(TARGET bintools PROPERTY elfconvert_flag_outfile "-DOUTFILE=")

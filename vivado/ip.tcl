source -quiet $::env(RUCKUS_DIR)/vivado/env_var.tcl
source -quiet $::env(RUCKUS_DIR)/vivado/proc.tcl


open_project -quiet ${VIVADO_PROJECT}
source -quiet ${RUCKUS_DIR}/vivado/properties.tcl
source -quiet ${RUCKUS_DIR}/vivado/messages.tcl
update_compile_order -quiet -fileset sources_1

########################################################
## Check project configuration for errors
########################################################
if { [CheckPrjConfig sources_1] != true ||
     [CheckPrjConfig sim_1]     != true } {
   exit -1
}

########################################################
## Check if we need to clean up or stop the implement
########################################################
if { [CheckImpl] != true } {
   reset_run impl_1
}

########################################################
## Check if we need to clean up or stop the synthesis
########################################################
if { [CheckSynth] != true } {
   reset_run synth_1
}

BuildIpCores


########################################################
## Target Pre synthesis script
########################################################
source ${RUCKUS_DIR}/vivado/pre_synthesis.tcl

########################################################
## Synthesize
########################################################
set syn_rc [catch {
   if { [CheckSynth] != true } {
      ## Check for DCP only synthesis run
      if { [info exists ::env(SYNTH_DCP)] } {
         SetSynthOutOfContext
      }
      ## Launch the run
      launch_runs synth_1 -jobs $::env(PARALLEL_SYNTH)
      set src_rc [catch {
         wait_on_run synth_1
      } _RESULT]
   }
} _SYN_RESULT]

########################################################
# Check for error return code during synthesis process
########################################################
if { ${syn_rc} } {
   PrintOpenGui ${_SYN_RESULT}
   exit -1
}

########################################################
## Check that the Synthesize is completed
########################################################
if { [CheckSynth printMsg] != true } {
   close_project
   exit -1
}

########################################################
## Target post synthesis script
########################################################
source ${RUCKUS_DIR}/vivado/post_synthesis.tcl

## Package Project into IP. AXIL ADDRESS width is auto-calculated based on register information.

ipx::package_project -root_dir $::env(TOP_DIR)/common/ip/$::env(PROJECT) -vendor user.org -library user -taxonomy /UserIP -import_files -set_current false
ipx::unload_core $::env(TOP_DIR)/build/$::env(PROJECT)/ip_repo/component.xml
ipx::edit_ip_in_project -upgrade true -name tmp_edit_project -directory $::env(TOP_DIR)/common/ip/$::env(PROJECT) $::env(TOP_DIR)/common/ip/$::env(PROJECT)/component.xml
update_compile_order -fileset sources_1
set_property enablement_value false [ipx::get_user_parameters AXILADDRWITDH_G -of_objects [ipx::current_core]]
set_property value_tcl_expr {expr ceil([expr {log($AXILDATAREGDEPTH_G+$NUMCONTREGS_G+$NUMSTATUSREGS_G)/[expr log(2)]}])} [ipx::get_user_parameters AXILADDRWITDH_G -of_objects [ipx::current_core]]
ipgui::remove_param -component [ipx::current_core] [ipgui::get_guiparamspec -name "AXILADDRWITDH_G" -component [ipx::current_core]]
ipgui::remove_param -component [ipx::current_core] [ipgui::get_guiparamspec -name "NUMCONTREGS_G" -component [ipx::current_core]]
ipgui::remove_param -component [ipx::current_core] [ipgui::get_guiparamspec -name "NUMSTATUSREGS_G" -component [ipx::current_core]]
set_property core_revision 1 [ipx::current_core]
ipx::update_source_project_archive -component [ipx::current_core]
ipx::create_xgui_files [ipx::current_core]
ipx::update_checksums [ipx::current_core]
ipx::check_integrity [ipx::current_core]
ipx::save_core [ipx::current_core]
ipx::check_integrity -quiet -xrt [ipx::current_core]
ipx::move_temp_component_back -component [ipx::current_core]
close_project -delete

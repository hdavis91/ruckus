source -quiet $::env(RUCKUS_DIR)/vivado_proc.tcl
source -quiet ${RUCKUS_DIR}/vivado/properties.tcl
source -quiet ${RUCKUS_DIR}/vivado/messages.tcl
loadSource -dir "$::DIR_PATH/hdl/IP/"
set_property top ${PROJECT}_IP [current_fileset]
update_compile_order -quiet -fileset sources_1
RemoveUnsuedCode
exec mkdir -p $::env(TOP_DIR)/build/ip_repo
ipx::package_project -root_dir $::env(TOP_DIR)/build/ip_repo/$::env(PROJECT) -vendor user.org -library user -taxonomy /UserIP -import_files -set_current false
ipx::unload_core $::env(TOP_DIR)/build/$::env(PROJECT)/ip_repo/component.xml
ipx::edit_ip_in_project -upgrade true -name tmp_edit_project -directory $::env(TOP_DIR)/build/ip_repo/$::env(PROJECT) $::env(TOP_DIR)/build/ip_repo/$::env(PROJECT)/component.xml
update_compile_order -fileset sources_1
set_property enablement_value false [ipx::get_user_parameters AXILADDRWITDH_G -of_objects [ipx::current_core]]
set_property value_tcl_expr {expr ceil([expr {log(4*($AXILDATAREGDEPTH_G+$NUMCONTREGS_G+$NUMSTATUSREGS_G))/[expr log(2)]}])} [ipx::get_user_parameters AXILADDRWITDH_G -of_objects [ipx::current_core]]
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

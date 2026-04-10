# Definitional proc to organize widgets for parameters.
proc init_gui { IPINST } {
  ipgui::add_param $IPINST -name "Component_Name"
  #Adding Page
  set Page_0 [ipgui::add_page $IPINST -name "Page 0"]
  ipgui::add_param $IPINST -name "DS_F" -parent ${Page_0}
  ipgui::add_param $IPINST -name "OUT_SIZE" -parent ${Page_0}


}

proc update_PARAM_VALUE.DS_F { PARAM_VALUE.DS_F } {
	# Procedure called to update DS_F when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.DS_F { PARAM_VALUE.DS_F } {
	# Procedure called to validate DS_F
	return true
}

proc update_PARAM_VALUE.OUT_SIZE { PARAM_VALUE.OUT_SIZE } {
	# Procedure called to update OUT_SIZE when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.OUT_SIZE { PARAM_VALUE.OUT_SIZE } {
	# Procedure called to validate OUT_SIZE
	return true
}


proc update_MODELPARAM_VALUE.OUT_SIZE { MODELPARAM_VALUE.OUT_SIZE PARAM_VALUE.OUT_SIZE } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.OUT_SIZE}] ${MODELPARAM_VALUE.OUT_SIZE}
}

proc update_MODELPARAM_VALUE.DS_F { MODELPARAM_VALUE.DS_F PARAM_VALUE.DS_F } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.DS_F}] ${MODELPARAM_VALUE.DS_F}
}


# Definitional proc to organize widgets for parameters.
proc init_gui { IPINST } {
  ipgui::add_param $IPINST -name "Component_Name"
  #Adding Page
  set Page_0 [ipgui::add_page $IPINST -name "Page 0"]
  ipgui::add_param $IPINST -name "DOWNSCALE_SIZE" -parent ${Page_0}
  ipgui::add_param $IPINST -name "DS_FACTOR" -parent ${Page_0}
  ipgui::add_param $IPINST -name "INPUT_HEIGHT" -parent ${Page_0}
  ipgui::add_param $IPINST -name "INPUT_WIDTH" -parent ${Page_0}
  ipgui::add_param $IPINST -name "LINE_WIDTH" -parent ${Page_0}


}

proc update_PARAM_VALUE.DOWNSCALE_SIZE { PARAM_VALUE.DOWNSCALE_SIZE } {
	# Procedure called to update DOWNSCALE_SIZE when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.DOWNSCALE_SIZE { PARAM_VALUE.DOWNSCALE_SIZE } {
	# Procedure called to validate DOWNSCALE_SIZE
	return true
}

proc update_PARAM_VALUE.DS_FACTOR { PARAM_VALUE.DS_FACTOR } {
	# Procedure called to update DS_FACTOR when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.DS_FACTOR { PARAM_VALUE.DS_FACTOR } {
	# Procedure called to validate DS_FACTOR
	return true
}

proc update_PARAM_VALUE.INPUT_HEIGHT { PARAM_VALUE.INPUT_HEIGHT } {
	# Procedure called to update INPUT_HEIGHT when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.INPUT_HEIGHT { PARAM_VALUE.INPUT_HEIGHT } {
	# Procedure called to validate INPUT_HEIGHT
	return true
}

proc update_PARAM_VALUE.INPUT_WIDTH { PARAM_VALUE.INPUT_WIDTH } {
	# Procedure called to update INPUT_WIDTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.INPUT_WIDTH { PARAM_VALUE.INPUT_WIDTH } {
	# Procedure called to validate INPUT_WIDTH
	return true
}

proc update_PARAM_VALUE.LINE_WIDTH { PARAM_VALUE.LINE_WIDTH } {
	# Procedure called to update LINE_WIDTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.LINE_WIDTH { PARAM_VALUE.LINE_WIDTH } {
	# Procedure called to validate LINE_WIDTH
	return true
}


proc update_MODELPARAM_VALUE.DS_FACTOR { MODELPARAM_VALUE.DS_FACTOR PARAM_VALUE.DS_FACTOR } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.DS_FACTOR}] ${MODELPARAM_VALUE.DS_FACTOR}
}

proc update_MODELPARAM_VALUE.DOWNSCALE_SIZE { MODELPARAM_VALUE.DOWNSCALE_SIZE PARAM_VALUE.DOWNSCALE_SIZE } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.DOWNSCALE_SIZE}] ${MODELPARAM_VALUE.DOWNSCALE_SIZE}
}

proc update_MODELPARAM_VALUE.LINE_WIDTH { MODELPARAM_VALUE.LINE_WIDTH PARAM_VALUE.LINE_WIDTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.LINE_WIDTH}] ${MODELPARAM_VALUE.LINE_WIDTH}
}

proc update_MODELPARAM_VALUE.INPUT_WIDTH { MODELPARAM_VALUE.INPUT_WIDTH PARAM_VALUE.INPUT_WIDTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.INPUT_WIDTH}] ${MODELPARAM_VALUE.INPUT_WIDTH}
}

proc update_MODELPARAM_VALUE.INPUT_HEIGHT { MODELPARAM_VALUE.INPUT_HEIGHT PARAM_VALUE.INPUT_HEIGHT } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.INPUT_HEIGHT}] ${MODELPARAM_VALUE.INPUT_HEIGHT}
}


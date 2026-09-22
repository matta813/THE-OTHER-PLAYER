class_name FacilityTerminal
extends Interactable
signal terminal_used
@export_multiline var text:="LINK STATUS: STANDBY"
func _perform_interaction(_actor:Node)->void:terminal_used.emit()
func remote_action(action:StringName,payload:Dictionary={})->bool:
 if action==&"display_text":text=payload.get("text",text);return true
 return false

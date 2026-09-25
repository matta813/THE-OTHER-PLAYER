extends Node

func _ready() -> void:
	var observer := Node.new()
	observer.name = "LoadingFlowObserver"
	observer.set_script(preload("res://tests/loading_flow_observer.gd"))
	get_tree().root.call_deferred("add_child", observer)

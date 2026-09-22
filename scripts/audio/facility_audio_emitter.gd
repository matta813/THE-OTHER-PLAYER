class_name FacilityAudioEmitter
extends AudioStreamPlayer3D

@export var interaction_stream: AudioStream
@export var unavailable_stream: AudioStream
@export var remote_stream: AudioStream
@export_range(-60.0, 6.0) var interaction_volume_db := -6.0

func play_interaction() -> void: _play_slot(interaction_stream)
func play_unavailable() -> void: _play_slot(unavailable_stream)
func play_remote() -> void: _play_slot(remote_stream)
func _play_slot(slot: AudioStream) -> void:
	if slot == null: return
	stream = slot; volume_db = interaction_volume_db; play()

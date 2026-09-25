class_name FacilityAudioEmitter
extends AudioStreamPlayer3D

@export var interaction_stream: AudioStream
@export var unavailable_stream: AudioStream
@export var remote_stream: AudioStream
@export_range(-60.0, 6.0) var interaction_volume_db := -6.0

func _ready() -> void:
	bus = "SFX"
	if interaction_stream == null: interaction_stream = FacilitySoundLibrary.relay()
	if unavailable_stream == null: unavailable_stream = FacilitySoundLibrary.relay()
	if remote_stream == null: remote_stream = FacilitySoundLibrary.motor()

func play_interaction() -> void: _play_slot(interaction_stream)
func play_unavailable() -> void: _play_slot(unavailable_stream)
func play_remote() -> void: _play_slot(remote_stream)
func _play_slot(slot: AudioStream) -> void:
	if slot == null: return
	if DisplayServer.get_name() == "headless": return
	stream = slot; volume_db = interaction_volume_db; play()

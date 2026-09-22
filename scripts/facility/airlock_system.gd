class_name AirlockSystem
extends Node

signal phase_changed(phase: int)
signal cycle_opened

enum Phase {IDLE, REQUESTED, SEALING, PRESSURIZING, OPENING, OPEN, CLOSING}
const PHASE_SECONDS := {Phase.REQUESTED: 1.0, Phase.SEALING: 1.8, Phase.PRESSURIZING: 4.5, Phase.OPENING: 2.0, Phase.CLOSING: 2.0}
var phase := Phase.IDLE
var elapsed := 0.0
var predicted_start := false
var inner_door: ElectronicDoor
var outer_door: ElectronicDoor

func configure(inner: ElectronicDoor, outer: ElectronicDoor) -> void:
	inner_door = inner; outer_door = outer
	set_process(false)

func request(predicted := false) -> bool:
	if phase != Phase.IDLE or inner_door == null or outer_door == null: return false
	predicted_start = predicted
	_set_phase(Phase.REQUESTED)
	return true

func close_cycle() -> bool:
	if phase != Phase.OPEN: return false
	_set_phase(Phase.CLOSING)
	return true

func _process(delta: float) -> void:
	if phase == Phase.IDLE or phase == Phase.OPEN: return
	elapsed += delta
	if elapsed < float(PHASE_SECONDS.get(phase, 0.0)): return
	match phase:
		Phase.REQUESTED:
			inner_door.remote_action(&"close")
			_set_phase(Phase.SEALING)
		Phase.SEALING: _set_phase(Phase.PRESSURIZING)
		Phase.PRESSURIZING:
			outer_door.remote_action(&"unlock")
			outer_door.remote_action(&"open")
			_set_phase(Phase.OPENING)
		Phase.OPENING:
			_set_phase(Phase.OPEN)
			cycle_opened.emit()
		Phase.CLOSING:
			outer_door.remote_action(&"close")
			_set_phase(Phase.IDLE)

func _set_phase(next: int) -> void:
	phase = next; elapsed = 0.0
	set_process(phase != Phase.IDLE and phase != Phase.OPEN)
	phase_changed.emit(phase)

func state_dict() -> Dictionary: return {"phase": phase, "elapsed": elapsed, "predicted_start": predicted_start}
func load_state(data: Dictionary) -> void:
	phase = clampi(int(data.get("phase", Phase.IDLE)), Phase.IDLE, Phase.CLOSING)
	elapsed = maxf(float(data.get("elapsed", 0.0)), 0.0)
	predicted_start = bool(data.get("predicted_start", false))
	set_process(phase != Phase.IDLE and phase != Phase.OPEN)
	phase_changed.emit(phase)

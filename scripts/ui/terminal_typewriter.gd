class_name TerminalTypewriter
extends Node

var panel: Control
var label: Label
var tail_start := 0
var character_index := 0
var accumulator := 0.0
var pause_remaining := 0.0
var hold_remaining := 0.0
var generation := 0

func _ready() -> void: set_process(false)

func configure(target_panel: Control, target_label: Label) -> void:
	panel = target_panel; label = target_label; set_process(false)

func display(history: String, newest_line := "") -> void:
	if panel == null or label == null: return
	generation += 1
	panel.visible = true
	label.text = history
	tail_start = maxi(history.length() - newest_line.length(), 0)
	character_index = tail_start if newest_line != "" else history.length()
	label.visible_characters = character_index
	accumulator = 0.0; pause_remaining = 0.0; hold_remaining = 3.0
	set_process(true)

func interrupt_with(history: String, newest_line: String) -> void: display(history, newest_line)

func _process(delta: float) -> void:
	if character_index >= label.text.length():
		hold_remaining -= delta
		if hold_remaining <= 0.0: panel.visible = false; set_process(false)
		return
	if pause_remaining > 0.0: pause_remaining -= delta; return
	accumulator += delta
	var next_character := label.text[character_index]
	var variation := float(abs(hash("%d:%d" % [generation, character_index])) % 7) * 0.002
	var interval := 0.026 + variation
	if accumulator < interval: return
	accumulator = 0.0
	character_index += 1
	label.visible_characters = character_index
	if next_character in [".", ",", "-", "?"]: pause_remaining = 0.09 if next_character != "?" else 0.18

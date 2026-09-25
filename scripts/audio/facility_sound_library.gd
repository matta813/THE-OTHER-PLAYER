class_name FacilitySoundLibrary
extends RefCounted

const RATE := 22050
static var ambience_cache: Dictionary = {}

static func hum(frequency: float) -> AudioStreamWAV:
	return _wave(2.0, true, func(t: float, i: int) -> float:
		var tone := sin(TAU * frequency * t) * 0.36 + sin(TAU * frequency * 2.0 * t) * 0.12
		var air := (_noise(i / 4) + _noise(i / 7 + 1301)) * 0.05
		return tone + air)

static func ambience(zone: String) -> AudioStreamWAV:
	if ambience_cache.has(zone): return ambience_cache[zone]
	var hz := 46.0
	var vent := 0.20
	var electric := 0.10
	var machine := 0.05
	match zone:
		"security": hz = 60.0; vent = 0.08; electric = 0.28; machine = 0.02
		"generator": hz = 48.0; vent = 0.11; electric = 0.16; machine = 0.26
		"maintenance": hz = 44.0; vent = 0.24; electric = 0.03; machine = 0.10
		"airlock": hz = 40.0; vent = 0.17; electric = 0.05; machine = 0.02
		"storage": hz = 46.0; vent = 0.12; electric = 0.04; machine = 0.03
		"observation": hz = 42.0; vent = 0.10; electric = 0.03; machine = 0.02
		"communications": hz = 60.0; vent = 0.08; electric = 0.20; machine = 0.02
	var stream := _wave(2.0, true, func(t: float, i: int) -> float:
		var electrical := sin(TAU * hz * t) * 0.24 + sin(TAU * hz * 2.0 * t) * 0.08
		var ventilation := (_noise(i / 3) + _noise(i / 11 + 1729)) * 0.25
		var mechanical := sin(TAU * (hz * 0.5) * t) * (0.6 + 0.2 * sin(TAU * 0.5 * t))
		return electrical * electric + ventilation * vent + mechanical * machine)
	ambience_cache[zone] = stream
	return stream

static func relay() -> AudioStreamWAV:
	return _wave(0.14, false, func(t: float, i: int) -> float:
		var envelope := pow(maxf(1.0 - t / 0.14, 0.0), 2.8)
		return (sin(TAU * 145.0 * t) * 0.42 + _noise(i) * 0.48) * envelope)

static func motor() -> AudioStreamWAV:
	return _wave(1.15, false, func(t: float, i: int) -> float:
		var envelope := minf(t / 0.11, 1.0) * minf((1.15 - t) / 0.22, 1.0)
		var rotating := sin(TAU * (66.0 + t * 9.0) * t) * 0.38
		var bearings := sin(TAU * (134.0 + t * 6.0) * t) * 0.17
		return (rotating + bearings + _noise(i / 2) * 0.1) * maxf(envelope, 0.0))

static func pressure() -> AudioStreamWAV:
	return _wave(2.0, false, func(t: float, i: int) -> float:
		var attack := minf(t / 0.18, 1.0)
		var release := minf((2.0 - t) / 0.52, 1.0)
		var hiss := _noise(i) * 0.32 + _noise(i / 7 + 403) * 0.25
		return hiss * maxf(minf(attack, release), 0.0))

static func step(surface: StringName, variant: int = 0) -> AudioStreamWAV:
	var frequency := 68.0 if surface == &"concrete" else (190.0 if surface == &"metal" else 135.0)
	frequency *= [0.98, 1.0, 1.025][posmod(variant, 3)]
	var noise_level := 0.38 if surface == &"concrete" else (0.22 if surface == &"metal" else 0.52)
	return _wave(0.17, false, func(t: float, i: int) -> float:
		var envelope := pow(maxf(1.0 - t / 0.17, 0.0), 3.2)
		return (sin(TAU * frequency * t) * (1.0 - noise_level) + _noise(i + variant * 7919) * noise_level) * envelope)

static func _wave(seconds: float, loop: bool, sample: Callable) -> AudioStreamWAV:
	var count := maxi(int(seconds * RATE), 1)
	var bytes := PackedByteArray(); bytes.resize(count * 2)
	for i in count:
		var value := clampf(float(sample.call(float(i) / RATE, i)), -1.0, 1.0)
		var pcm := int(value * 19000.0)
		bytes[i * 2] = pcm & 255
		bytes[i * 2 + 1] = (pcm >> 8) & 255
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = RATE
	stream.stereo = false
	stream.data = bytes
	if loop:
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		stream.loop_begin = 0
		stream.loop_end = count
	return stream

static func _noise(index: int) -> float:
	var value := (index * 1103515245 + 12345) & 0x7fffffff
	return float(value % 2048) / 1024.0 - 1.0

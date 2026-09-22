class_name FacilitySoundLibrary
extends RefCounted

const RATE := 22050

static func hum(frequency: float) -> AudioStreamWAV:
	return _wave(1.0, true, func(t: float, _i: int) -> float:
		return sin(TAU * frequency * t) * 0.52 + sin(TAU * frequency * 2.0 * t) * 0.18 + sin(TAU * frequency * 0.5 * t) * 0.08)

static func relay() -> AudioStreamWAV:
	return _wave(0.13, false, func(t: float, i: int) -> float:
		var envelope := pow(maxf(1.0 - t / 0.13, 0.0), 2.8)
		return (sin(TAU * 145.0 * t) * 0.42 + _noise(i) * 0.58) * envelope)

static func motor() -> AudioStreamWAV:
	return _wave(0.58, false, func(t: float, i: int) -> float:
		var envelope := minf(t / 0.06, 1.0) * minf((0.58 - t) / 0.16, 1.0)
		return (sin(TAU * 72.0 * t) * 0.55 + sin(TAU * 138.0 * t) * 0.25 + _noise(i) * 0.12) * maxf(envelope, 0.0))

static func step(surface: StringName) -> AudioStreamWAV:
	var frequency := 68.0 if surface == &"concrete" else (190.0 if surface == &"metal" else 135.0)
	var noise_level := 0.38 if surface == &"concrete" else (0.22 if surface == &"metal" else 0.52)
	return _wave(0.17, false, func(t: float, i: int) -> float:
		var envelope := pow(maxf(1.0 - t / 0.17, 0.0), 3.2)
		return (sin(TAU * frequency * t) * (1.0 - noise_level) + _noise(i) * noise_level) * envelope)

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

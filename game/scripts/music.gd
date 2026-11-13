extends RefCounted

# Original 24-bar handheld loop: three phrases with a busier bass and chip drums.
const SAMPLE_RATE: int = 22050
const BPM: float = 132.0
const MELODY: Array[int] = [
	76, 0, 79, 0, 83, 79, 0, 74,
	76, 0, 79, 83, 81, 0, 79, 0,
	72, 0, 76, 0, 79, 76, 0, 71,
	72, 0, 76, 79, 78, 0, 74, 0,
	69, 0, 72, 0, 76, 72, 0, 67,
	69, 0, 72, 76, 74, 0, 72, 0,
	71, 0, 74, 0, 78, 74, 0, 81,
	79, 0, 78, 0, 74, 0, 71, 0,
	# Answer: climb into a brighter register, then settle back toward the theme.
	79, 83, 86, 83, 79, 0, 76, 79,
	83, 0, 81, 79, 78, 74, 71, 0,
	76, 79, 84, 79, 76, 0, 72, 76,
	79, 0, 78, 76, 74, 71, 67, 0,
	76, 81, 84, 81, 76, 0, 72, 76,
	81, 79, 76, 72, 74, 0, 76, 0,
	78, 81, 83, 81, 78, 0, 74, 78,
	81, 79, 78, 74, 71, 0, 74, 0,
	# Return: denser variations and a short turnaround into the opening.
	76, 79, 83, 79, 86, 83, 79, 74,
	76, 0, 79, 83, 81, 79, 78, 74,
	72, 76, 79, 76, 84, 79, 76, 71,
	72, 0, 76, 79, 78, 76, 74, 71,
	69, 72, 76, 72, 81, 76, 72, 67,
	69, 0, 72, 76, 79, 76, 74, 72,
	71, 74, 78, 74, 81, 78, 74, 71,
	79, 78, 74, 71, 74, 78, 83, 0,
]
const ROOTS: Array[int] = [
	40, 40, 36, 36, 33, 33, 35, 35,
	40, 35, 36, 31, 33, 33, 35, 35,
	40, 40, 36, 36, 33, 33, 35, 35,
]

static func frequency(note: int) -> float:
	return 440.0 * pow(2.0, float(note - 69) / 12.0)

static func build() -> AudioStreamWAV:
	var step_seconds: float = 30.0 / BPM
	var count: int = roundi(MELODY.size() * step_seconds * SAMPLE_RATE)
	var data := PackedByteArray()
	data.resize(count * 2)
	var rng := RandomNumberGenerator.new()
	rng.seed = 1128
	for step: int in range(MELODY.size()):
		var first: int = roundi(step * step_seconds * SAMPLE_RATE)
		var end: int = roundi((step + 1) * step_seconds * SAMPLE_RATE)
		var lead_hz: float = frequency(MELODY[step])
		var bass_note: int = ROOTS[step / 8] + (12 if step % 2 == 1 else 0)
		var bass_hz: float = frequency(bass_note)
		for i: int in range(first, end):
			var t: float = float(i - first) / SAMPLE_RATE
			var lead_env: float = minf(t / 0.006, 1.0) * clampf((step_seconds * 0.78 - t) / 0.035, 0.0, 1.0)
			var phase: float = TAU * lead_hz * t
			# A few pulse harmonics retain the chip character without harsh aliasing.
			var lead: float = (sin(phase) + sin(phase * 3.0) / 3.0 + sin(phase * 5.0) / 5.0) * 0.22 * lead_env if MELODY[step] > 0 else 0.0
			var bass_env: float = minf(t / 0.008, 1.0) * clampf((step_seconds * 0.80 - t) / 0.035, 0.0, 1.0)
			var triangle: float = 1.0 - 4.0 * absf(fposmod(bass_hz * t, 1.0) - 0.5)
			var bass: float = triangle * 0.29 * bass_env
			var hat_env: float = minf(t / 0.002, 1.0) * pow(maxf(0.0, 1.0 - t / 0.035), 2.0)
			var hat: float = rng.randf_range(-1.0, 1.0) * hat_env * (0.07 if step % 2 else 0.035)
			var drum: float = 0.0
			if step % 4 == 0:
				# Integrated falling pitch gives a short, quiet chip kick.
				var kick_phase: float = TAU * (58.0 * t + 50.0 * 0.025 * (1.0 - exp(-t / 0.025)))
				drum = sin(kick_phase) * minf(t / 0.003, 1.0) * pow(maxf(0.0, 1.0 - t / 0.09), 2.0) * 0.13
			elif step % 4 == 2:
				drum = rng.randf_range(-1.0, 1.0) * minf(t / 0.003, 1.0) * pow(maxf(0.0, 1.0 - t / 0.065), 2.0) * 0.10
			data.encode_s16(i * 2, roundi((lead + bass + hat + drum) * 32767.0))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.data = data
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	stream.loop_end = count
	return stream

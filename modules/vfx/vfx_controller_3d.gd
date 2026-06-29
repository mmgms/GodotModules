extends Node
class_name VfxController3D
## controls multiple gpu particles, can call emit once and subscribe to all_particles finished or start and stop

@export var gpu_particles: Array[GPUParticles3D]

signal all_particle_finished

var _finished = 0
func emit_once():
	_finished = 0
	for particle in gpu_particles:
		particle.emitting = true
		if not particle.is_connected("finished", _on_finished):
			particle.finished.connect(_on_finished)
		
func start():
	for particle in gpu_particles:
		particle.emitting = true
		
func stop():
	for particle in gpu_particles:
		particle.emitting = true

func _on_finished():
	_finished += 1
	if _finished == gpu_particles.size():
		all_particle_finished.emit()
	

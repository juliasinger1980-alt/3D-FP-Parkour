extends Area3D

@onready var spawnpoint: Node3D = $"../../Spawnpoint"

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		body.global_position = spawnpoint.global_position

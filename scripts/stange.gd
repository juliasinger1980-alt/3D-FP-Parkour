extends Node3D

@onready var area: Area3D = $Area3D
@onready var stange: CSGCylinder3D = $CSGCylinder3D

func _ready() -> void:
	area.body_entered.connect(_on_area_entered)

func _on_area_entered(body):
	if body.is_in_group("player"):
		EventBus.swing_triggered.emit(stange)

## Base class for all pickup items.
class_name ItemBase
extends Area2D


@export var item_name: String = "Item"
@export var item_category: GameEnums.ItemCategory = GameEnums.ItemCategory.POTION


func _ready() -> void:
	connect("body_entered", _on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		use(body as Player)
		queue_free()


func use(player: Player) -> void:
	"""Override in subclass."""
	pass

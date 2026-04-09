# SkinBase.gd — Base class all skins extend
extends RefCounted

var whip_t: float = 0.0
var react_t: float = 0.0
var idle_t: float = 0.0
var is_animating: bool = false

func update(delta: float) -> void:
	idle_t += delta * 1.2
	if is_animating:
		whip_t = min(whip_t + delta * 4.0, 1.0)
		react_t = min(react_t + delta * 4.0, 1.0)
		if whip_t >= 1.0:
			whip_t = min(whip_t + delta * 3.0, 2.0)
			if whip_t >= 2.0:
				is_animating = false
				whip_t = 0.0
				react_t = 0.0

func trigger() -> void:
	is_animating = true
	whip_t = 0.0
	react_t = 0.0

func draw(_canvas: Node2D, _w: float, _h: float) -> void:
	pass  # Override in each skin

func cubic_bezier(p0: Vector2, p1: Vector2, p2: Vector2, p3: Vector2, t: float) -> Vector2:
	var u := 1.0 - t
	return u*u*u*p0 + 3*u*u*t*p1 + 3*u*t*t*p2 + t*t*t*p3

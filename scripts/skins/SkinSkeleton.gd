# SkinSkeleton.gd — Spooky skeleton rattling bones on every input
extends "res://scripts/skins/SkinBase.gd"

const C_BONE    := Color(0.92, 0.90, 0.82)
const C_DARK    := Color(0.12, 0.10, 0.15)
const C_GLOW    := Color(0.20, 0.95, 0.40)
const C_ORANGE  := Color(0.95, 0.50, 0.10)
const C_LABEL   := Color(0.20, 0.95, 0.40)

func draw(canvas: Node2D, w: float, h: float) -> void:
	canvas.draw_string(ThemeDB.fallback_font, Vector2(w/2.0, 18),
		"☠  RATTLING  ☠", HORIZONTAL_ALIGNMENT_CENTER, -1, 13, C_LABEL)
	_draw_skeleton(canvas, Vector2(w/2.0, h/2.0 + 10))

func _draw_skeleton(c: Node2D, pos: Vector2) -> void:
	var rattle := sin(idle_t * 12.0) * (3.0 if is_animating else 0.5)
	var p := pos + Vector2(rattle, 0)

	# ── Pelvis ──
	c.draw_arc(p+Vector2(0,25), 18, 0, TAU, 16, C_BONE, 4.0)

	# ── Spine ──
	for i in range(5):
		var sy := -10.0 + i * 12.0
		var sx := sin(idle_t * 8.0 + i * 0.5) * (1.5 if is_animating else 0.3)
		c.draw_circle(p+Vector2(sx, sy), 5, C_BONE)
		if i > 0:
			c.draw_line(p+Vector2(sin(idle_t*8+(i-1)*0.5)*(1.5 if is_animating else 0.3), -10+(i-1)*12),
						p+Vector2(sx, sy), C_BONE, 3.0)

	# ── Ribcage ──
	for i in range(3):
		var ry := -8.0 + i * 8.0
		c.draw_arc(p+Vector2(0,ry), 16, PI*0.1, PI*0.9, 8, C_BONE, 3.0)
		c.draw_arc(p+Vector2(0,ry), 16, PI*1.1, PI*1.9, 8, C_BONE, 3.0)

	# ── Arms rattling ──
	var arm_rattle := sin(idle_t * 15.0) * (8.0 if is_animating else 1.0)
	# Left arm
	c.draw_line(p+Vector2(-16,-5), p+Vector2(-32,8+arm_rattle), C_BONE, 4.0)
	c.draw_line(p+Vector2(-32,8+arm_rattle), p+Vector2(-40,22), C_BONE, 3.0)
	_draw_bony_hand(c, p+Vector2(-40,22), -1)
	# Right arm
	c.draw_line(p+Vector2(16,-5), p+Vector2(32,8-arm_rattle), C_BONE, 4.0)
	c.draw_line(p+Vector2(32,8-arm_rattle), p+Vector2(40,22), C_BONE, 3.0)
	_draw_bony_hand(c, p+Vector2(40,22), 1)

	# ── Legs ──
	var leg_r := sin(idle_t * 10.0) * (4.0 if is_animating else 0.5)
	c.draw_line(p+Vector2(-10,35), p+Vector2(-14+leg_r,58), C_BONE, 4.0)
	c.draw_line(p+Vector2(10,35),  p+Vector2(14-leg_r,58),  C_BONE, 4.0)
	c.draw_line(p+Vector2(-14+leg_r,58), p+Vector2(-12,72), C_BONE, 3.5)
	c.draw_line(p+Vector2(14-leg_r,58),  p+Vector2(12,72),  C_BONE, 3.5)
	# Feet bones
	c.draw_line(p+Vector2(-12,72), p+Vector2(-22,75), C_BONE, 3.0)
	c.draw_line(p+Vector2(12,72),  p+Vector2(22,75),  C_BONE, 3.0)

	# ── Skull ──
	var hp := p + Vector2(0, -52)
	c.draw_circle(hp, 26, C_BONE)
	c.draw_circle(hp, 26, C_DARK, false, 1.5)
	# Cheekbones
	c.draw_circle(hp+Vector2(-18,6), 6, C_BONE)
	c.draw_circle(hp+Vector2(18,6),  6, C_BONE)
	# Eye sockets
	c.draw_circle(hp+Vector2(-10,-5), 9, C_DARK)
	c.draw_circle(hp+Vector2(10,-5),  9, C_DARK)
	# Glowing eyes
	var glow_intensity := 0.7 + sin(idle_t * 3.0) * 0.3
	var glow_col := C_ORANGE if is_animating else C_GLOW
	c.draw_circle(hp+Vector2(-10,-5), 6, Color(glow_col, glow_intensity))
	c.draw_circle(hp+Vector2(10,-5),  6, Color(glow_col, glow_intensity))
	# Nose cavity
	c.draw_line(hp+Vector2(-3,6), hp+Vector2(3,6), C_DARK, 4.0)
	# Teeth grin
	for i in range(6):
		var tx := -10.0 + i * 4.0
		c.draw_rect(Rect2(hp+Vector2(tx,14), Vector2(3,5)), C_BONE, true)
		c.draw_line(hp+Vector2(tx,14), hp+Vector2(tx,19), C_DARK, 1.0)

	# Floating bones on react
	if is_animating:
		for i in range(3):
			var ang := idle_t * 4.0 + i * TAU / 3.0
			var bp := p + Vector2(cos(ang)*55, sin(ang)*40 - 20)
			var ba := sinf(react_t * PI)
			c.draw_line(bp, bp+Vector2(10,4), Color(C_BONE,ba), 3.0)
			c.draw_circle(bp, 4*ba, Color(C_BONE,ba))
			c.draw_circle(bp+Vector2(10,4), 4*ba, Color(C_BONE,ba))

func _draw_bony_hand(c: Node2D, pos: Vector2, side: int) -> void:
	for i in range(3):
		var fx := side * (i * 4.0 - 4.0)
		c.draw_line(pos+Vector2(fx,0), pos+Vector2(fx,8), C_BONE, 2.0)
		c.draw_circle(pos+Vector2(fx,8), 2.5, C_BONE)

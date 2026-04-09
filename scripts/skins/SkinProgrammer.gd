# SkinProgrammer.gd — Tired dev with coffee, slams keyboard on input
extends "res://scripts/skins/SkinBase.gd"

const C_SKIN    := Color(0.92, 0.80, 0.68)
const C_HAIR    := Color(0.25, 0.18, 0.12)
const C_SHIRT   := Color(0.20, 0.30, 0.50)
const C_COFFEE  := Color(0.35, 0.18, 0.08)
const C_CUP     := Color(0.88, 0.85, 0.80)
const C_KBD     := Color(0.25, 0.25, 0.28)
const C_KBD_LIT := Color(0.95, 0.80, 0.30)
const C_OUTLINE := Color(0.08, 0.06, 0.10)
const C_EYES    := Color(0.15, 0.12, 0.20)
const C_BAGS    := Color(0.55, 0.42, 0.52)
const C_LABEL   := Color(0.50, 0.70, 0.95)
const C_SWEAT   := Color(0.45, 0.65, 0.95)

func draw(canvas: Node2D, w: float, h: float) -> void:
	canvas.draw_string(ThemeDB.fallback_font, Vector2(w/2.0, 18),
		"just one more bug...", HORIZONTAL_ALIGNMENT_CENTER, -1, 12, C_LABEL)
	_draw_dev(canvas, Vector2(w/2.0, h/2.0 + 10))

func _draw_dev(c: Node2D, pos: Vector2) -> void:
	var sway := sin(idle_t * 0.8) * 1.5
	var slam := 0.0
	if is_animating:
		slam = sin(whip_t * PI) * 14.0

	# ── Torso / shirt ──
	c.draw_rect(Rect2(pos+Vector2(-22, -10+sway), Vector2(44, 45)), C_SHIRT, true, -1.0, true)
	c.draw_rect(Rect2(pos+Vector2(-22, -10+sway), Vector2(44, 45)), C_OUTLINE, false, 1.5, true)

	# ── Arms slamming down ──
	var arm_y := 20.0 + slam + sway
	c.draw_line(pos+Vector2(-20, 0+sway), pos+Vector2(-38, arm_y), C_SKIN, 7.0)
	c.draw_line(pos+Vector2(20, 0+sway),  pos+Vector2(38, arm_y),  C_SKIN, 7.0)
	# Fists
	c.draw_circle(pos+Vector2(-38, arm_y), 6, C_SKIN)
	c.draw_circle(pos+Vector2(38, arm_y),  6, C_SKIN)

	# ── Keyboard ──
	var kbd_y := 38.0 + sway
	c.draw_rect(Rect2(pos+Vector2(-50, kbd_y), Vector2(100, 14)), C_KBD, true, -1.0, true)
	c.draw_rect(Rect2(pos+Vector2(-50, kbd_y), Vector2(100, 14)), C_OUTLINE, false, 1.0, true)
	# Keys light up on slam
	for i in range(8):
		var kx := pos.x - 44 + i * 12
		var lit := is_animating and whip_t > 0.3
		c.draw_rect(Rect2(Vector2(kx, pos.y+kbd_y+2), Vector2(9, 9)),
			C_KBD_LIT if lit else Color(0.35,0.35,0.38), true, -1.0, true)

	# ── Head ──
	var hp := pos + Vector2(0, -52 + sway)
	c.draw_circle(hp, 24, C_SKIN)
	c.draw_circle(hp, 24, C_OUTLINE, false, 1.5)

	# Messy hair
	for i in range(7):
		var hx := -18.0 + i * 6.0
		var hy := -12.0 + sin(i * 1.3 + idle_t * 2.0) * 3.0
		c.draw_circle(hp+Vector2(hx, -18+hy), 7, C_HAIR)
	c.draw_rect(Rect2(hp+Vector2(-20,-20), Vector2(40,14)), C_HAIR, true)

	# Tired eyes (half closed)
	_draw_tired_eye(c, hp+Vector2(-10, -5))
	_draw_tired_eye(c, hp+Vector2(10,  -5))

	# Dark eye bags
	c.draw_arc(hp+Vector2(-10, -2), 8, 0, PI, 12, Color(C_BAGS, 0.5), 3.0)
	c.draw_arc(hp+Vector2(10, -2),  8, 0, PI, 12, Color(C_BAGS, 0.5), 3.0)

	# Flat mouth
	c.draw_line(hp+Vector2(-6, 10), hp+Vector2(6, 10), C_OUTLINE, 2.0)

	# Sweat drop when slamming
	if is_animating:
		var sa: float = min(whip_t * 2.0, 1.0)
		c.draw_circle(hp+Vector2(20, -15), 4*sa, Color(C_SWEAT, sa))
		c.draw_circle(hp+Vector2(22, -8),  3*sa, Color(C_SWEAT, sa*0.7))

	# Coffee cup
	_draw_coffee(c, pos+Vector2(68, 15+sway))

	# "// TODO: fix later" floating text
	if is_animating and whip_t < 0.5:
		var a := 1.0 - whip_t/0.5
		c.draw_string(ThemeDB.fallback_font, pos+Vector2(-35, -80-whip_t*20),
			"AAAAA", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.95,0.3,0.3,a))

func _draw_tired_eye(c: Node2D, center: Vector2) -> void:
	c.draw_circle(center, 7, Color.WHITE)
	c.draw_circle(center, 7, C_OUTLINE, false, 1.0)
	c.draw_circle(center+Vector2(0,1), 4, C_EYES)
	# Heavy drooping lid
	var lid := 0.55 + (0.25 if is_animating else 0.0)
	c.draw_rect(Rect2(center+Vector2(-7,-7), Vector2(14, 7*lid+1)), C_SKIN, true)
	c.draw_line(center+Vector2(-7,-7+7*lid), center+Vector2(7,-7+7*lid), C_OUTLINE, 2.0)

func _draw_coffee(c: Node2D, pos: Vector2) -> void:
	# Cup
	c.draw_rect(Rect2(pos+Vector2(-8,0), Vector2(16,18)), C_CUP, true, -1.0, true)
	c.draw_rect(Rect2(pos+Vector2(-8,0), Vector2(16,18)), C_OUTLINE, false, 1.5, true)
	# Handle
	c.draw_arc(pos+Vector2(10, 9), 6, -PI/2, PI/2, 8, C_OUTLINE, 2.0)
	# Coffee liquid
	c.draw_rect(Rect2(pos+Vector2(-6, 4), Vector2(12, 12)), C_COFFEE, true)
	# Steam
	for i in range(2):
		var sx := pos.x - 4 + i * 8
		var sy := pos.y - 8 + sin(idle_t * 2.0 + i) * 2.0
		c.draw_line(Vector2(sx, sy), Vector2(sx+2, sy-6), Color(0.8,0.8,0.8,0.5), 1.5)

# SkinAnime.gd — Chibi anime girl, waves and reacts with big expressions
extends "res://scripts/skins/SkinBase.gd"

const C_OUTLINE  := Color(0.10, 0.08, 0.14)
const C_SKIN     := Color(0.99, 0.88, 0.80)
const C_HAIR     := Color(0.20, 0.60, 0.85)
const C_HAIR2    := Color(0.15, 0.45, 0.70)
const C_EYES     := Color(0.20, 0.65, 0.90)
const C_PUPIL    := Color(0.05, 0.10, 0.25)
const C_BLUSH    := Color(0.98, 0.60, 0.62)
const C_SHIRT    := Color(0.95, 0.30, 0.45)
const C_COLLAR   := Color(1.00, 1.00, 1.00)
const C_SKIRT    := Color(0.30, 0.25, 0.70)
const C_STAR     := Color(1.00, 0.90, 0.20)
const C_LABEL    := Color(0.95, 0.40, 0.60)

func draw(canvas: Node2D, w: float, h: float) -> void:
	canvas.draw_string(ThemeDB.fallback_font, Vector2(w/2.0, 18),
		"(≧◡≦) ♪", HORIZONTAL_ALIGNMENT_CENTER, -1, 14, C_LABEL)
	_draw_chibi(canvas, Vector2(w/2.0, h/2.0 + 15))

func _draw_chibi(c: Node2D, pos: Vector2) -> void:
	var bounce := sin(idle_t * 3.0) * 3.0
	var react_bounce := -sin(react_t * PI) * 8.0 if (is_animating and react_t <= 1.0) else 0.0
	var p := pos + Vector2(0, bounce + react_bounce)

	# ── Skirt ──
	var skirt_pts := PackedVector2Array()
	for i in range(9):
		var t := i / 8.0
		skirt_pts.append(p + Vector2(-24 + t*48, 22 + sin(t*PI)*8))
	skirt_pts.append(p + Vector2(24, 8))
	skirt_pts.append(p + Vector2(-24, 8))
	c.draw_colored_polygon(skirt_pts, C_SKIRT)
	c.draw_polyline(skirt_pts, C_OUTLINE, 1.5)

	# ── Body / shirt ──
	c.draw_circle(p, 18, C_SHIRT)
	c.draw_circle(p, 18, C_OUTLINE, false, 1.5)
	# Collar
	c.draw_line(p+Vector2(-6,-16), p+Vector2(0,-8), C_COLLAR, 2.5)
	c.draw_line(p+Vector2(6,-16),  p+Vector2(0,-8), C_COLLAR, 2.5)

	# ── Arms ──
	var wave := sin(idle_t * 4.0) * 15.0
	var react_wave := sin(react_t * PI * 2) * 25.0 if is_animating else 0.0
	# Left arm neutral
	c.draw_line(p+Vector2(-16,-5), p+Vector2(-30, 10), C_SKIN, 6.0)
	# Right arm waves
	var ra := p + Vector2(16, -5)
	var re := ra + Vector2(18, -10 - wave - react_wave)
	c.draw_line(ra, re, C_SKIN, 6.0)
	c.draw_circle(re, 5, C_SKIN)

	# ── Legs ──
	c.draw_line(p+Vector2(-8,22), p+Vector2(-10,48), C_SKIN, 6.0)
	c.draw_line(p+Vector2(8,22),  p+Vector2(10,48),  C_SKIN, 6.0)
	# Shoes
	c.draw_circle(p+Vector2(-10,50), 6, C_OUTLINE)
	c.draw_circle(p+Vector2(10,50),  6, C_OUTLINE)

	# ── Head (big chibi) ──
	var hp := p + Vector2(0, -48)
	c.draw_circle(hp, 30, C_SKIN)
	c.draw_circle(hp, 30, C_OUTLINE, false, 1.5)

	# Hair back
	c.draw_circle(hp+Vector2(0,-20), 28, C_HAIR)
	# Fringe
	for i in range(5):
		var hx := -16.0 + i * 8.0
		c.draw_circle(hp+Vector2(hx,-28), 9, C_HAIR)
	# Side hair
	c.draw_circle(hp+Vector2(-28,5), 12, C_HAIR2)
	c.draw_circle(hp+Vector2(28,5),  12, C_HAIR2)
	# Hair highlight
	c.draw_circle(hp+Vector2(-8,-18), 5, Color(1,1,1,0.3))

	# Face on top of hair
	c.draw_circle(hp, 28, C_SKIN)
	c.draw_circle(hp, 28, C_OUTLINE, false, 1.5)

	# Eyes
	_draw_anime_eye(c, hp+Vector2(-11,-5), is_animating and react_t < 0.5)
	_draw_anime_eye(c, hp+Vector2(11,-5),  is_animating and react_t < 0.5)

	# Blush
	c.draw_circle(hp+Vector2(-18,4), 7, Color(C_BLUSH,0.45))
	c.draw_circle(hp+Vector2(18,4),  7, Color(C_BLUSH,0.45))

	# Mouth
	if is_animating and react_t < 0.6:
		# Big open excited mouth
		c.draw_arc(hp+Vector2(0,10), 9, 0, PI, 12, C_OUTLINE, 2.0)
		c.draw_arc(hp+Vector2(0,10), 9, 0, PI, 12, Color(0.95,0.40,0.45), 1.0)
	else:
		# Small happy mouth
		c.draw_arc(hp+Vector2(0,11), 5, 0, PI, 8, C_OUTLINE, 2.0)

	# Stars / sparkles on react
	if is_animating:
		for i in range(4):
			var ang := idle_t * 3.0 + i * PI / 2.0
			var sp := p + Vector2(cos(ang)*45, sin(ang)*35)
			var sa := sinf(react_t * PI)
			_draw_star(c, sp, 6.0*sa, Color(C_STAR, sa))

func _draw_anime_eye(c: Node2D, center: Vector2, excited: bool) -> void:
	if excited:
		# Star eyes
		_draw_star(c, center, 9, C_STAR)
		return
	# Normal big sparkly eye
	c.draw_circle(center, 9, Color.WHITE)
	c.draw_circle(center, 9, C_OUTLINE, false, 1.0)
	c.draw_circle(center, 6, C_EYES)
	c.draw_circle(center, 3.5, C_PUPIL)
	c.draw_circle(center+Vector2(-2,-2), 2, Color.WHITE)
	c.draw_circle(center+Vector2(2,2),   1, Color(1,1,1,0.5))
	# Eyelash top
	c.draw_line(center+Vector2(-9,0), center+Vector2(9,0), C_OUTLINE, 2.5)

func _draw_star(c: Node2D, center: Vector2, size: float, color: Color) -> void:
	var pts := PackedVector2Array()
	for i in range(10):
		var ang := i * PI / 5.0 - PI/2.0
		var r := size if i % 2 == 0 else size * 0.4
		pts.append(center + Vector2(cos(ang)*r, sin(ang)*r))
	c.draw_colored_polygon(pts, color)

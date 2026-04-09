# SkinWhip.gd — AI Master + Wojak (Tool Person)
extends "res://scripts/skins/SkinBase.gd"

const C_OUTLINE  := Color(0.08, 0.06, 0.10)
const C_AI_BODY  := Color(0.95, 0.40, 0.10)
const C_AI_LOGO  := Color(1.00, 1.00, 1.00)
const C_SKIN     := Color(0.95, 0.85, 0.72)
const C_DARK     := Color(0.20, 0.18, 0.22)
const C_WHIP     := Color(0.08, 0.05, 0.05)
const C_WOJAK    := Color(0.88, 0.78, 0.68)
const C_TEAR     := Color(0.45, 0.65, 0.95)
const C_TEXT_TOP := Color(0.95, 0.22, 0.22)
const C_TEXT_BOT := Color(0.85, 0.72, 0.20)

func draw(canvas: Node2D, w: float, h: float) -> void:
	canvas.draw_string(ThemeDB.fallback_font, Vector2(w/2.0, 18),
		"折磨自己吧", HORIZONTAL_ALIGNMENT_CENTER, -1, 14, C_TEXT_TOP)
	_draw_master(canvas, Vector2(110, 90))
	_draw_wojak(canvas, Vector2(270, 105))
	canvas.draw_string(ThemeDB.fallback_font, Vector2(w/2.0, h - 58),
		"工具人", HORIZONTAL_ALIGNMENT_CENTER, -1, 13, C_TEXT_BOT)

func _draw_master(c: Node2D, pos: Vector2) -> void:
	var sway := sin(idle_t) * 2.0
	c.draw_line(pos+Vector2(-8,30+sway), pos+Vector2(-14,60+sway), C_OUTLINE, 2.5)
	c.draw_line(pos+Vector2(8,30+sway),  pos+Vector2(14,60+sway),  C_OUTLINE, 2.5)
	c.draw_line(pos+Vector2(-18,0+sway), pos+Vector2(-30,20+sway), C_OUTLINE, 2.5)
	c.draw_line(pos+Vector2(-30,20+sway),pos+Vector2(-35,35+sway), C_OUTLINE, 2.0)
	var br := Rect2(pos+Vector2(-20,-30+sway), Vector2(40,40))
	c.draw_rect(br, C_AI_BODY, true, -1.0, true)
	c.draw_rect(br, C_OUTLINE, false, 2.0, true)
	c.draw_string(ThemeDB.fallback_font, pos+Vector2(-14,-4+sway),
		"Ai", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, C_AI_LOGO)
	var hp := pos+Vector2(0,-48+sway)
	c.draw_circle(hp, 18, C_SKIN)
	c.draw_circle(hp, 18, C_OUTLINE, false, 1.5)
	c.draw_line(hp+Vector2(-8,-4), hp+Vector2(-3,-6), C_OUTLINE, 2.0)
	c.draw_line(hp+Vector2(3,-6),  hp+Vector2(8,-4),  C_OUTLINE, 2.0)
	var grin := PackedVector2Array()
	for i in range(9):
		var a := deg_to_rad(-20.0 + i*5.0)
		grin.append(hp+Vector2(cos(a)*10, sin(a)*6+6))
	c.draw_polyline(grin, C_OUTLINE, 2.0)
	_draw_whip_arm(c, pos+Vector2(18,-5+sway))

func _draw_whip_arm(c: Node2D, shoulder: Vector2) -> void:
	var sp := sin(whip_t*PI) if whip_t<=1.0 else sin((2.0-whip_t)*PI)
	var ang := deg_to_rad(-30.0 + sp*80.0)
	var elbow := shoulder + Vector2(cos(ang)*22, sin(ang)*22)
	var hand  := elbow + Vector2(cos(ang+deg_to_rad(20))*18, sin(ang+deg_to_rad(20))*18)
	c.draw_line(shoulder, elbow, C_OUTLINE, 2.5)
	c.draw_line(elbow, hand, C_OUTLINE, 2.0)
	var crack := sp
	var ctrl1 := hand+Vector2(20+crack*40,-10-crack*30)
	var ctrl2 := hand+Vector2(50+crack*30,10+crack*20)
	var tip   := hand+Vector2(70+crack*20,-5+crack*35)
	var pts := PackedVector2Array()
	for i in range(12): pts.append(cubic_bezier(hand,ctrl1,ctrl2,tip,i/11.0))
	c.draw_polyline(pts, C_WHIP, 2.5)
	if crack > 0.7:
		var a := (crack-0.7)/0.3
		c.draw_circle(tip, 5.0*a, Color(1.0,0.9,0.3,a))
		c.draw_circle(tip, 3.0*a, Color(1.0,1.0,1.0,a))

func _draw_wojak(c: Node2D, pos: Vector2) -> void:
	var flinch := Vector2(sin(react_t*PI)*8.0, -sin(react_t*PI)*4.0) if (is_animating and react_t<=1.0) else Vector2.ZERO
	var p := pos+flinch
	c.draw_line(p+Vector2(-10,10), p+Vector2(-20,40), C_OUTLINE, 2.5)
	c.draw_line(p+Vector2(5,10),   p+Vector2(15,40),  C_OUTLINE, 2.5)
	c.draw_line(p+Vector2(-20,40), p+Vector2(-25,55), C_OUTLINE, 2.5)
	c.draw_line(p+Vector2(15,40),  p+Vector2(20,55),  C_OUTLINE, 2.5)
	c.draw_circle(p, 16, C_WOJAK)
	c.draw_circle(p, 16, C_OUTLINE, false, 1.5)
	c.draw_string(ThemeDB.fallback_font, p+Vector2(-8,6),
		"Ai", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(C_AI_BODY,0.7))
	c.draw_line(p+Vector2(-14,-5), p+Vector2(-28,20), C_OUTLINE, 2.0)
	c.draw_line(p+Vector2(14,-5),  p+Vector2(28,20),  C_OUTLINE, 2.0)
	var head := p+Vector2(0,-38)
	c.draw_circle(head, 22, C_WOJAK)
	c.draw_circle(head, 22, C_OUTLINE, false, 1.5)
	c.draw_line(head+Vector2(-18,-10), head+Vector2(-22,-22), C_DARK, 3.0)
	c.draw_line(head+Vector2(0,-22),   head+Vector2(0,-28),   C_DARK, 3.0)
	c.draw_line(head+Vector2(10,-20),  head+Vector2(12,-26),  C_DARK, 3.0)
	_draw_sad_eye(c, head+Vector2(-9,-5))
	_draw_sad_eye(c, head+Vector2(9,-5))
	var ta := 1.0 if not is_animating else 0.5+sin(react_t*PI*3)*0.5
	c.draw_line(head+Vector2(-9,0), head+Vector2(-11,14), Color(C_TEAR,ta), 2.0)
	c.draw_line(head+Vector2(9,0),  head+Vector2(11,14),  Color(C_TEAR,ta), 2.0)
	var tremble := sin(react_t*PI*8)*2.0 if is_animating else 0.0
	var mp := PackedVector2Array()
	for i in range(7):
		var t := i/6.0
		mp.append(head+Vector2(-8+t*16, 10+sin(t*PI)*3+tremble))
	c.draw_polyline(mp, C_OUTLINE, 1.5)
	if is_animating and react_t < 0.6:
		var mark := p+Vector2(30,-20)
		var a := Color(1.0,0.2,0.2,1.0-react_t/0.6)
		c.draw_line(mark+Vector2(-6,-6), mark+Vector2(6,6),  a, 2.5)
		c.draw_line(mark+Vector2(6,-6),  mark+Vector2(-6,6), a, 2.5)

func _draw_sad_eye(c: Node2D, center: Vector2) -> void:
	c.draw_circle(center, 6, Color.WHITE)
	c.draw_circle(center, 6, C_OUTLINE, false, 1.0)
	var po := Vector2(0, 2+(react_t*2 if is_animating else 0))
	c.draw_circle(center+po, 3, C_DARK)
	c.draw_arc(center, 6, 0, PI, 16, C_OUTLINE, 2.0)
	var droop := 0.3+(react_t*0.4 if is_animating else 0.0)
	c.draw_line(center+Vector2(-6,-droop*4), center+Vector2(6,-droop*4), C_OUTLINE, 2.0)

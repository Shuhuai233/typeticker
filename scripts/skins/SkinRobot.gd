# SkinRobot.gd — Mechanical robot with blinking lights and servo arms
extends "res://scripts/skins/SkinBase.gd"

const C_METAL   := Color(0.55, 0.60, 0.68)
const C_METAL2  := Color(0.38, 0.42, 0.50)
const C_DARK    := Color(0.12, 0.12, 0.16)
const C_LED_G   := Color(0.20, 0.95, 0.35)
const C_LED_R   := Color(0.95, 0.20, 0.20)
const C_LED_B   := Color(0.20, 0.60, 0.95)
const C_SCREEN  := Color(0.05, 0.15, 0.30)
const C_OUTLINE := Color(0.08, 0.08, 0.12)
const C_SPARK   := Color(0.95, 0.85, 0.20)
const C_LABEL   := Color(0.20, 0.60, 0.95)

func draw(canvas: Node2D, w: float, h: float) -> void:
	canvas.draw_string(ThemeDB.fallback_font, Vector2(w/2.0, 18),
		"SYS: INPUT DETECTED", HORIZONTAL_ALIGNMENT_CENTER, -1, 11, C_LED_G)
	_draw_robot(canvas, Vector2(w/2.0, h/2.0 + 10))

func _draw_robot(c: Node2D, pos: Vector2) -> void:
	var hum := sin(idle_t * 6.0) * 1.0  # subtle hum vibration
	var p := pos + Vector2(hum, 0)

	# ── Legs / treads ──
	c.draw_rect(Rect2(p+Vector2(-20,42), Vector2(14,16)), C_METAL2, true, -1.0, true)
	c.draw_rect(Rect2(p+Vector2(6,42),   Vector2(14,16)), C_METAL2, true, -1.0, true)
	c.draw_rect(Rect2(p+Vector2(-22,54), Vector2(18,6)), C_DARK, true)
	c.draw_rect(Rect2(p+Vector2(4,54),   Vector2(18,6)), C_DARK, true)
	# Tread lines
	for i in range(4):
		c.draw_line(p+Vector2(-22+i*4,54), p+Vector2(-22+i*4,60), C_METAL, 1.5)
		c.draw_line(p+Vector2(4+i*4,54),   p+Vector2(4+i*4,60),   C_METAL, 1.5)

	# ── Torso ──
	c.draw_rect(Rect2(p+Vector2(-24,-10), Vector2(48,52)), C_METAL, true, -1.0, true)
	c.draw_rect(Rect2(p+Vector2(-24,-10), Vector2(48,52)), C_OUTLINE, false, 2.0, true)
	# Panel lines
	c.draw_line(p+Vector2(-24,10), p+Vector2(24,10), C_METAL2, 1.5)
	c.draw_line(p+Vector2(0,-10),  p+Vector2(0,42),  C_METAL2, 1.0)

	# Chest screen
	c.draw_rect(Rect2(p+Vector2(-14,0), Vector2(28,22)), C_SCREEN, true, -1.0, true)
	c.draw_rect(Rect2(p+Vector2(-14,0), Vector2(28,22)), C_LED_B, false, 1.0, true)
	# Screen content: counter bars
	var bar_count := mini(torture_count_display() % 8, 8)
	for i in range(8):
		var bh := 4.0 + sin(idle_t * 3.0 + i) * 3.0
		var bc := C_LED_G if i < bar_count else Color(C_LED_G, 0.2)
		c.draw_rect(Rect2(p+Vector2(-12+i*3, 20-bh), Vector2(2, bh)), bc, true)

	# Chest LEDs
	var led_blink := fmod(idle_t, 1.0) > 0.5
	c.draw_circle(p+Vector2(-18,28), 3, C_LED_R if (is_animating and led_blink) else Color(C_LED_R,0.3))
	c.draw_circle(p+Vector2(-10,28), 3, C_LED_G if led_blink else Color(C_LED_G,0.3))
	c.draw_circle(p+Vector2(-2,28),  3, C_LED_B if not led_blink else Color(C_LED_B,0.3))

	# ── Arms ──
	_draw_robot_arm(c, p, -1)
	_draw_robot_arm(c, p, 1)

	# ── Head ──
	var hp := p + Vector2(0, -52)
	# Neck
	c.draw_rect(Rect2(p+Vector2(-8,-14), Vector2(16,10)), C_METAL2, true, -1.0, true)
	# Head box
	c.draw_rect(Rect2(hp+Vector2(-26,-22), Vector2(52,44)), C_METAL, true, -1.0, true)
	c.draw_rect(Rect2(hp+Vector2(-26,-22), Vector2(52,44)), C_OUTLINE, false, 2.0, true)
	# Antenna
	c.draw_line(hp+Vector2(0,-22), hp+Vector2(0,-36), C_METAL2, 2.5)
	var ant_col := C_LED_R if is_animating else Color(lerp(C_LED_G, C_LED_R, sin(idle_t*2)*0.5+0.5), 1.0)
	c.draw_circle(hp+Vector2(0,-38), 5, ant_col)
	# Eye screens
	_draw_robot_eye(c, hp+Vector2(-12,-5))
	_draw_robot_eye(c, hp+Vector2(12,-5))
	# Mouth speaker grille
	for i in range(5):
		c.draw_line(hp+Vector2(-10+i*5,12), hp+Vector2(-10+i*5,18), C_METAL2, 1.5)
	c.draw_rect(Rect2(hp+Vector2(-12,10), Vector2(24,10)), C_DARK, false, 1.0, true)
	# Side panels / ears
	c.draw_rect(Rect2(hp+Vector2(-32,-8), Vector2(6,16)), C_METAL2, true, -1.0, true)
	c.draw_rect(Rect2(hp+Vector2(26,-8),  Vector2(6,16)), C_METAL2, true, -1.0, true)

	# Sparks on input
	if is_animating:
		for i in range(5):
			var ang := idle_t * 8.0 + i * TAU / 5.0
			var sr := 35.0 + sin(idle_t*10+i)*10.0
			var sp := p + Vector2(cos(ang)*sr, sin(ang)*sr - 20)
			var sa: float = sin(react_t * PI)
			c.draw_line(sp, sp+Vector2(cos(ang+0.5)*6, sin(ang+0.5)*6),
				Color(C_SPARK, sa), 2.0)

func _draw_robot_arm(c: Node2D, pos: Vector2, side: int) -> void:
	var servo := sin(idle_t * 4.0) * 5.0
	var slam  := sin(whip_t * PI) * 20.0 if is_animating else 0.0
	var ax := side * 24.0
	# Upper arm
	c.draw_rect(Rect2(pos+Vector2(ax if side>0 else ax-10,-5), Vector2(10, 22+servo+slam)), C_METAL2, true, -1.0, true)
	c.draw_rect(Rect2(pos+Vector2(ax if side>0 else ax-10,-5), Vector2(10, 22+servo+slam)), C_OUTLINE, false, 1.0, true)
	# Joint
	var jy := pos.y + 17 + servo + slam
	c.draw_circle(Vector2(pos.x + ax + (5 if side>0 else -5), jy), 5, C_METAL)
	# Forearm
	c.draw_rect(Rect2(Vector2(pos.x+ax+(0 if side>0 else -8), jy), Vector2(8,16)), C_METAL, true, -1.0, true)
	# Claw
	var cy := jy + 16
	c.draw_line(Vector2(pos.x+ax+2,cy), Vector2(pos.x+ax+2+side*8,cy+6), C_METAL2, 2.5)
	c.draw_line(Vector2(pos.x+ax+6,cy), Vector2(pos.x+ax+6+side*4,cy+6), C_METAL2, 2.5)
	# LED on arm
	var led_on := fmod(idle_t + (0.5 if side > 0 else 0.0), 1.0) > 0.5
	c.draw_circle(Vector2(pos.x+ax+4,pos.y+2), 2, C_LED_B if led_on else Color(C_LED_B,0.2))

func _draw_robot_eye(c: Node2D, center: Vector2) -> void:
	c.draw_rect(Rect2(center+Vector2(-8,-6), Vector2(16,12)), C_SCREEN, true, -1.0, true)
	c.draw_rect(Rect2(center+Vector2(-8,-6), Vector2(16,12)), C_LED_B, false, 1.0, true)
	if is_animating:
		# Angry red X
		c.draw_line(center+Vector2(-5,-4), center+Vector2(5,4), C_LED_R, 2.0)
		c.draw_line(center+Vector2(5,-4),  center+Vector2(-5,4), C_LED_R, 2.0)
	else:
		# Normal scanning line
		var scan := fmod(idle_t * 2.0, 1.0)
		c.draw_line(center+Vector2(-6,-4+scan*8), center+Vector2(6,-4+scan*8),
			Color(C_LED_G, 0.8), 1.5)

var torture_count: int = 0

func torture_count_display() -> int:
	return torture_count

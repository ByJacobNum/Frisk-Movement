extends CharacterBody2D
# Speeds
const SPEED = 100.0 # Speed Normal # Old Speed: 100.0
const WALK_SPEED_GLITCH = 146.0 # Walk Glitch # Old Speed: 150.0
@onready var ray_cast_2d: RayCast2D = $RayCast2D
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
var last_direction = Vector2.DOWN
var horizontal_priority = ""
var down_up_priority = false
var player := self
var last_player_position: Vector2
# Direction that controls the animation.
var animation_priority_action = ""
var animation_priority = Vector2.DOWN
# Walk Glitch state.
var walk_glitch_frame = false
var is_moving = false
# Current Speed
var current_speed = SPEED
func _physics_process(_delta: float) -> void:
	var up_pressed = Input.is_action_pressed("ui_up")
	var down_pressed = Input.is_action_pressed("ui_down")
	var left_pressed = Input.is_action_pressed("ui_left")
	var right_pressed = Input.is_action_pressed("ui_right")

	var any_pressed = up_pressed or down_pressed or left_pressed or right_pressed
	
	# Horizontal priority.
	if Input.is_action_just_pressed("ui_left"):
		horizontal_priority = "ui_left"
	elif Input.is_action_just_pressed("ui_right"):
		horizontal_priority = "ui_right"

	if not left_pressed and not right_pressed:
		horizontal_priority = ""
	elif left_pressed and not right_pressed:
		horizontal_priority = "ui_left"
	elif right_pressed and not left_pressed:
		horizontal_priority = "ui_right"

	# Special case: Down first, then Up.
	if not down_pressed:
		down_up_priority = false
	elif down_pressed and Input.is_action_just_pressed("ui_up"):
		down_up_priority = true

	var direction = Vector2.ZERO

	if down_up_priority and up_pressed and down_pressed:
		direction.y = -1
	elif up_pressed:
		direction.y = -1
	elif down_pressed:
		direction.y = 1

	if left_pressed and right_pressed:
		if horizontal_priority == "ui_left":
			direction.x = -1
		else:
			direction.x = 1
	elif left_pressed:
		direction.x = -1
	elif right_pressed:
		direction.x = 1

	direction = direction.normalized()

	var previous_position = global_position

	velocity = direction * current_speed
	move_and_slide()

	var has_collision = get_slide_collision_count() > 0
	var ceiling_blocked = false

	for i in range(get_slide_collision_count()):
		var collision = get_slide_collision(i)

		if collision.get_normal().y > 0.7:
			ceiling_blocked = true
			break

	# Detect lateral walls using the RayCast.
	var original_ray_target = ray_cast_2d.target_position
	var lateral_wall = false

	if left_pressed and (not right_pressed or horizontal_priority == "ui_left"):
		ray_cast_2d.target_position = Vector2.LEFT * 20
	elif right_pressed:
		ray_cast_2d.target_position = Vector2.RIGHT * 20

	if left_pressed or right_pressed:
		ray_cast_2d.force_raycast_update()

		if ray_cast_2d.is_colliding():
			var wall_normal = ray_cast_2d.get_collision_normal()
			lateral_wall = abs(wall_normal.x) > 0.7

	ray_cast_2d.target_position = original_ray_target

	if up_pressed and down_pressed and ceiling_blocked:
		walk_glitch_frame = not walk_glitch_frame
		animated_sprite_2d.play("walk_glitch")
		ray_cast_2d.target_position = last_direction * 20
		current_speed = WALK_SPEED_GLITCH
		return

	current_speed = SPEED

	if not any_pressed:
		animation_priority_action = ""
	elif animation_priority_action != "" and not Input.is_action_pressed(animation_priority_action):
		animation_priority_action = ""

	if left_pressed and right_pressed:
		animation_direction_horizontal()

	if has_collision:
		if left_pressed and right_pressed:
			animation_priority_action = horizontal_priority
			animation_priority = Vector2.LEFT if horizontal_priority == "ui_left" else Vector2.RIGHT
		elif left_pressed:
			animation_priority_action = "ui_left"
			animation_priority = Vector2.LEFT
		elif right_pressed:
			animation_priority_action = "ui_right"
			animation_priority = Vector2.RIGHT
		elif up_pressed and down_pressed and down_up_priority:
			animation_priority_action = "ui_up"
			animation_priority = Vector2.UP
		elif up_pressed:
			animation_priority_action = "ui_up"
			animation_priority = Vector2.UP
		elif down_pressed:
			animation_priority_action = "ui_down"
			animation_priority = Vector2.DOWN
	else:
		if animation_priority_action == "ui_up" and up_pressed:
			animation_priority = Vector2.UP
		elif animation_priority_action == "ui_down" and down_pressed:
			animation_priority = Vector2.DOWN
		elif left_pressed and right_pressed:
			animation_priority_action = horizontal_priority
			animation_priority = Vector2.LEFT if horizontal_priority == "ui_left" else Vector2.RIGHT
		elif left_pressed:
			animation_priority_action = "ui_left"
			animation_priority = Vector2.LEFT
		elif right_pressed:
			animation_priority_action = "ui_right"
			animation_priority = Vector2.RIGHT
		elif up_pressed and down_pressed and down_up_priority:
			animation_priority_action = "ui_up"
			animation_priority = Vector2.UP
		elif up_pressed:
			animation_priority_action = "ui_up"
			animation_priority = Vector2.UP
		elif down_pressed:
			animation_priority_action = "ui_down"
			animation_priority = Vector2.DOWN

	var animation_direction = animation_priority if any_pressed else Vector2.ZERO

	if down_up_priority and up_pressed and down_pressed:
		if Input.is_action_just_pressed("ui_left"):
			animation_direction = Vector2.LEFT
		else:
			if left_pressed:
					if not down_pressed and not up_pressed:
						animation_direction = Vector2.LEFT
					elif up_pressed and not down_pressed:
						animation_direction = Vector2.UP
			elif right_pressed:
					if not down_pressed and not up_pressed:
						animation_direction = Vector2.RIGHT
					elif up_pressed and not down_pressed:
						if down_pressed and up_pressed:
							animation_direction = Vector2.UP
						elif down_pressed and not up_pressed:
							animation_direction = Vector2.RIGHT
			else:
					animation_direction = Vector2.UP
	elif lateral_wall and left_pressed and (not right_pressed or horizontal_priority == "ui_left"):
		if up_pressed:
			animation_direction = Vector2.UP
		elif down_pressed:
			animation_direction = Vector2.DOWN
		else:
			animation_direction = Vector2.LEFT
	elif left_pressed or right_pressed:
		if not (not has_collision and animation_priority_action in ["ui_up", "ui_down"]):
			if left_pressed and right_pressed:
				animation_direction = Vector2.LEFT if horizontal_priority == "ui_left" else Vector2.RIGHT
			elif left_pressed:
				animation_direction = Vector2.LEFT
			else:
				animation_direction = Vector2.RIGHT
	elif has_collision and any_pressed:
		if up_pressed:
			animation_direction = Vector2.UP
		elif down_pressed:
			animation_direction = Vector2.DOWN

	if animation_direction != Vector2.ZERO:
		last_direction = animation_direction
		if has_collision:
			animation_priority = animation_direction
	ray_cast_2d.target_position = last_direction * 20

	var actual_movement = global_position - previous_position
	var has_moved = actual_movement.length() > 0.1

	if direction != Vector2.ZERO and has_moved:
		is_moving = true
		if animation_direction == Vector2.RIGHT:
			if has_collision:
				if down_pressed:
					if up_pressed:
						if lateral_wall:
							animated_sprite_2d.play("walk_up")
						else:
							animated_sprite_2d.play("walk_right")
					else:
						if lateral_wall:
							animated_sprite_2d.play("walk_down")
						else:
							animated_sprite_2d.play("walk_right")
				elif up_pressed:
					if down_pressed:
						if lateral_wall:
							animated_sprite_2d.play("walk_down")
						else:
							animated_sprite_2d.play("walk_right")						
					else:
						if lateral_wall:
							animated_sprite_2d.play("walk_up")
						else:
							animated_sprite_2d.play("walk_right")
				else:
					animated_sprite_2d.play("walk_right")
			else:
				animated_sprite_2d.play("walk_right")
		elif animation_direction == Vector2.LEFT:
			if left_pressed and up_pressed and not down_pressed:
				if horizontal_priority and horizontal_priority == "ui_left":
					if has_collision:
						if up_pressed:
							if lateral_wall:
								animated_sprite_2d.play("walk_up")
							else:
								animated_sprite_2d.play("walk_left")
					animated_sprite_2d.play("walk_left")
				else:
					animated_sprite_2d.play("walk_up")
			else:	
				if up_pressed:
					if lateral_wall:
						animated_sprite_2d.play("walk_up")
					else:
						animated_sprite_2d.play("walk_left")
				else:
					animated_sprite_2d.play("walk_left")
		elif animation_direction == Vector2.DOWN:
			if right_pressed and up_pressed:
				animated_sprite_2d.play("walk_up")
			else:
				if left_pressed and up_pressed:
					animated_sprite_2d.play("walk_up")
				else:
					animated_sprite_2d.play("walk_down")
		elif animation_direction == Vector2.UP:
			animated_sprite_2d.play("walk_up")
	else:
		is_moving = false			
		if last_direction == Vector2.RIGHT:
			animated_sprite_2d.play("idle_right")
		elif last_direction == Vector2.LEFT:
			animated_sprite_2d.play("idle_left")
		elif last_direction == Vector2.DOWN:
			animated_sprite_2d.play("idle_down")
		else:
			animated_sprite_2d.play("idle_up")
func animation_direction_horizontal() -> void:
	if Input.is_action_just_pressed("ui_left"):
		horizontal_priority = "ui_left"
	elif Input.is_action_just_pressed("ui_right"):
		horizontal_priority = "ui_right"
func _ready() -> void:
	# FPS
	Engine.max_fps = 30

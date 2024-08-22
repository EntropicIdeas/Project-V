extends CharacterBody2D

# Constants for the states
enum State {IDLE, RUN, DASH, JUMP, FALL}

# Variables for the different states
var state = State.IDLE

# Movement variables
var speed := 50
var run_speed := 100
var dash_speed := 150
var jump_force := -200
var gravity := 500
var acceleration := 20
var deceleration := 20

# Jump and air variables
var jump_time := 0.2
var max_jump_time := 0.5  # Maximum time the jump can be extended
var hang_time := 0.1
var coyote_time := 0.2
var air_resistance := 0.95

# Timers for coyote and jump buffering
var coyote_timer = 0.0
var jump_buffer_timer = 0.0

# Input tracking
var is_jump_pressed = false
var is_dash_pressed = false
var jump_timer = 0.0

# Smooth movement variables
var target_velocity = Vector2.ZERO

# Animations
@onready var anim_sprite = $AnimatedSprite2D as AnimatedSprite2D


func _ready():
	pass

func _process(delta):
	handle_input()
	update_state(delta)
	update_velocity(delta)
	update_animation()

func handle_input():
	# Handle movement input
	target_velocity.x = 0
	if Input.is_action_pressed("move_right"):
		target_velocity.x = run_speed if state == State.RUN else speed
	elif Input.is_action_pressed("move_left"):
		target_velocity.x = -run_speed if state == State.RUN else -speed

	# Handle dash input
	if Input.is_action_just_pressed("dash"):
		is_dash_pressed = true

	# Handle jump input
	if Input.is_action_just_pressed("jump"):
		is_jump_pressed = true
		jump_buffer_timer = jump_time
		jump_timer = 0.0  # Reset jump timer when jump starts

	if Input.is_action_just_released("jump"):
		is_jump_pressed = false

func update_state(delta):
	match state:
		State.IDLE:
			if target_velocity.x != 0:
				state = State.RUN
			elif is_jump_pressed and coyote_timer > 0:
				state = State.JUMP
				velocity.y = jump_force
				is_jump_pressed = false
				coyote_timer = 0
			elif is_dash_pressed:
				state = State.DASH
				is_dash_pressed = false

		State.RUN:
			if target_velocity.x == 0:
				state = State.IDLE
			elif is_jump_pressed and coyote_timer > 0:
				state = State.JUMP
				velocity.y = jump_force
				is_jump_pressed = false
				coyote_timer = 0
			elif is_dash_pressed:
				state = State.DASH
				is_dash_pressed = false

		State.DASH:
			velocity.x = dash_speed if target_velocity.x > 0 else -dash_speed
			state = State.IDLE

		State.JUMP:
			jump_timer += delta
			if velocity.y >= 0:
				state = State.FALL
			elif is_jump_pressed and jump_timer < max_jump_time:
				velocity.y = lerp(velocity.y, jump_force, jump_timer / max_jump_time)

		State.FALL:
			if is_on_floor():
				state = State.IDLE
			elif is_jump_pressed and jump_buffer_timer > 0:
				state = State.JUMP
				velocity.y = jump_force
				is_jump_pressed = false
				jump_buffer_timer = 0

	if is_on_floor():
		coyote_timer = coyote_time
	else:
		coyote_timer -= delta

	jump_buffer_timer -= delta

func update_velocity(delta):
	# Apply gravity
	if state != State.DASH:
		velocity.y += gravity * delta

	# Apply acceleration and deceleration
	if target_velocity.x != 0:
		velocity.x = lerp(velocity.x, float(target_velocity.x), acceleration * delta)
	else:
		velocity.x = lerp(velocity.x, 0.0, deceleration * delta)

	# Apply air resistance if in the air
	if state in [State.JUMP, State.FALL]:
		velocity.x *= air_resistance

	move_and_slide()

func update_animation():
	# Flip the sprite based on direction
	if target_velocity.x > 0:
		anim_sprite.scale.x = 1
	elif target_velocity.x < 0:
		anim_sprite.scale.x = -1

	match state:
		State.IDLE:
			anim_sprite.play("Idle")
		State.RUN:
			anim_sprite.play("Run")
		State.DASH:
			anim_sprite.play("Dash")
		State.JUMP:
			anim_sprite.play("Jump")
		State.FALL:
			anim_sprite.play("Fall")

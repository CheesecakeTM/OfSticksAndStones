class_name Crosshair
extends CenterContainer

# Crosshair color
@export var crosshair_color: Color = Color.WHITE
@export var dot_radius: float = 2.0

# References
@onready var top = %top
@onready var bottom = %bottom
@onready var right = %right
@onready var left = %left
@onready var lines = $lines

# Called when the node enters the scene tree for the first time.
func _ready():
	
	# Draws everything in the _draw() function
	queue_redraw()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	
	# Colors the crosshair
	top.default_color = crosshair_color
	bottom.default_color = crosshair_color
	right.default_color = crosshair_color
	left.default_color = crosshair_color
	
	# Hides/shows the crosshair if player sprints/walks
	lines.visible = false if StateController.is_sprinting else true

func _draw():
	
	# Draws a dot with our presets
	draw_circle(Vector2(0, 0), dot_radius, crosshair_color)

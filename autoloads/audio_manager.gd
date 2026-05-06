extends Node

# ---------------------------------------------------------
# 1. SIGNALS (What does this script shout to other scenes?)
# ---------------------------------------------------------

# ---------------------------------------------------------
# 2. ENUMS AND CONSTANTS (Fixed values)
# ---------------------------------------------------------

# ---------------------------------------------------------
# 3. EXPORTED VARIABLES (Those that appear in the right-side Editor Inspector)
# ---------------------------------------------------------

# ---------------------------------------------------------
# 4. PUBLIC VARIABLES (Can be read/modified by other scripts)
# ---------------------------------------------------------

# ---------------------------------------------------------
# 5. PRIVATE VARIABLES (Prefixed with "_"; used only inside this script)
# ---------------------------------------------------------

# ---------------------------------------------------------
# 6. ONREADY VARIABLES (Links to the UI / Node Tree)
# ---------------------------------------------------------
@onready var music_player: AudioStreamPlayer = $MusicPlayer
@onready var sfx_player: AudioStreamPlayer = $SFXPlayer

# ---------------------------------------------------------
# 7. GODOT ENGINE FUNCTIONS (The built-in ones)
# ---------------------------------------------------------

# ---------------------------------------------------------
# 8. PUBLIC FUNCTIONS (Called by you from other scripts)
# ---------------------------------------------------------
func play_music(stream: AudioStream, fade_duration: float = 1.0) -> void:
	if music_player.stream == stream and music_player.playing:
		return
		
	music_player.stream = stream
	music_player.volume_db = -40.0
	music_player.play()
	
	var tween: Tween = create_tween()
	tween.tween_property(music_player, "volume_db", 0.0, fade_duration)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_OUT)

func stop_music(fade_duration: float = 1.0) -> void:
	if not music_player.playing:
		return
		
	var tween: Tween = create_tween()
	tween.tween_property(music_player, "volume_db", -40.0, fade_duration)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_IN)
		
	tween.tween_callback(music_player.stop)

func play_sfx(stream: AudioStream) -> void:
	sfx_player.stream = stream
	sfx_player.play()

# ---------------------------------------------------------
# 9. PRIVATE FUNCTIONS (Prefixed with "_", used only internally here)
# ---------------------------------------------------------

# ---------------------------------------------------------
# 10. SIGNAL CALLBACKS (What happens when buttons/timers trigger)
# ---------------------------------------------------------

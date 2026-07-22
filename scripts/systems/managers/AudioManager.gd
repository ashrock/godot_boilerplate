# File: scripts/systems/managers/AudioManager.gd
# DOCU: Manages game audio playback with pooling and volume control
# Provides SFX pooling and music crossfade transitions
# Last Updated At: 2026-07-22
# @author Godot Boilerplate
extends Node

# ==================== AUDIO PLAYERS ====================
var _sfx_player_pool: Array[AudioStreamPlayer] = []
var _music_player: AudioStreamPlayer
var _music_player_fade: AudioStreamPlayer  # For crossfading

const SFX_POOL_SIZE: int = 16

# ==================== VOLUME SETTINGS ====================
var master_volume: float = 1.0
var sfx_volume: float = 1.0
var music_volume: float = 0.7

# ==================== INITIALIZATION ====================
func _ready() -> void:
	_initializeSfxPool()
	_initializeMusicPlayers()
	print("AudioManager: Initialized with %d SFX players" % SFX_POOL_SIZE)

func _initializeSfxPool() -> void:
	for i in range(SFX_POOL_SIZE):
		var player = AudioStreamPlayer.new()
		player.bus = "SFX"
		add_child(player)
		_sfx_player_pool.append(player)

func _initializeMusicPlayers() -> void:
	_music_player = AudioStreamPlayer.new()
	_music_player.bus = "Music"
	add_child(_music_player)

	_music_player_fade = AudioStreamPlayer.new()
	_music_player_fade.bus = "Music"
	add_child(_music_player_fade)

# ==================== SFX PLAYBACK ====================
# DOCU: Play a sound effect
# @param sfx_name: Name of the SFX file (without extension)
# @param volume_db: Volume in decibels (default: 0.0)
# @return: AudioStreamPlayer - The player used, or null if none available
# Last Updated At: 2026-07-22
# @author Godot Boilerplate
func playSfx(sfx_name: String, volume_db: float = 0.0) -> AudioStreamPlayer:
	var player = _getAvailableSfxPlayer()
	if not player:
		push_warning("AudioManager: No available SFX players")
		return null

	var stream = _loadSfxStream(sfx_name)
	if not stream:
		push_error("AudioManager: Failed to load SFX: %s" % sfx_name)
		return null

	player.stream = stream
	player.volume_db = volume_db + linear_to_db(sfx_volume * master_volume)
	player.play()
	return player

# DOCU: Play a sound effect at a 3D position (if using 3D audio)
# @param sfx_name: Name of the SFX file
# @param position: 3D position to play from
# @param volume_db: Volume in decibels
# Last Updated At: 2026-07-22
# @author Godot Boilerplate
func playSfxAtPosition(sfx_name: String, position: Vector3, volume_db: float = 0.0) -> void:
	# For 2D games, ignore position
	# For 3D games, implement AudioStreamPlayer3D pooling
	playSfx(sfx_name, volume_db)

# ==================== MUSIC PLAYBACK ====================
# DOCU: Play music with optional crossfade
# @param music_name: Name of the music file
# @param fade_duration: Crossfade duration in seconds (0 = instant)
# Last Updated At: 2026-07-22
# @author Godot Boilerplate
func playMusic(music_name: String, fade_duration: float = 1.0) -> void:
	var stream = _loadMusicStream(music_name)
	if not stream:
		push_error("AudioManager: Failed to load music: %s" % music_name)
		return

	if fade_duration <= 0.0 or not _music_player.playing:
		# Instant switch
		_music_player.stream = stream
		_music_player.volume_db = linear_to_db(music_volume * master_volume)
		_music_player.play()
	else:
		# Crossfade
		_crossfadeMusic(stream, fade_duration)

# DOCU: Stop music with optional fade out
# @param fade_duration: Fade out duration in seconds (0 = instant)
# Last Updated At: 2026-07-22
# @author Godot Boilerplate
func stopMusic(fade_duration: float = 1.0) -> void:
	if fade_duration <= 0.0:
		_music_player.stop()
		return

	var tween = create_tween()
	tween.tween_property(_music_player, "volume_db", -80.0, fade_duration)
	tween.tween_callback(_music_player.stop)

# ==================== VOLUME CONTROL ====================
# DOCU: Set master volume
# @param volume: Volume level (0.0 to 1.0)
# Last Updated At: 2026-07-22
# @author Godot Boilerplate
func setMasterVolume(volume: float) -> void:
	master_volume = clamp(volume, 0.0, 1.0)
	_updateMusicVolume()

# DOCU: Set SFX volume
# @param volume: Volume level (0.0 to 1.0)
# Last Updated At: 2026-07-22
# @author Godot Boilerplate
func setSfxVolume(volume: float) -> void:
	sfx_volume = clamp(volume, 0.0, 1.0)

# DOCU: Set music volume
# @param volume: Volume level (0.0 to 1.0)
# Last Updated At: 2026-07-22
# @author Godot Boilerplate
func setMusicVolume(volume: float) -> void:
	music_volume = clamp(volume, 0.0, 1.0)
	_updateMusicVolume()

# ==================== PRIVATE HELPERS ====================
func _getAvailableSfxPlayer() -> AudioStreamPlayer:
	for player in _sfx_player_pool:
		if not player.playing:
			return player
	return null

func _loadSfxStream(sfx_name: String) -> AudioStream:
	# Try common audio formats
	var extensions = ["wav", "ogg", "mp3"]
	for ext in extensions:
		var path = "res://assets/sounds/sfx/%s.%s" % [sfx_name, ext]
		if ResourceLoader.exists(path):
			return load(path) as AudioStream
	return null

func _loadMusicStream(music_name: String) -> AudioStream:
	var extensions = ["ogg", "mp3", "wav"]
	for ext in extensions:
		var path = "res://assets/sounds/music/%s.%s" % [music_name, ext]
		if ResourceLoader.exists(path):
			return load(path) as AudioStream
	return null

func _crossfadeMusic(new_stream: AudioStream, duration: float) -> void:
	# Swap players
	var temp = _music_player
	_music_player = _music_player_fade
	_music_player_fade = temp

	# Start new music at zero volume
	_music_player.stream = new_stream
	_music_player.volume_db = -80.0
	_music_player.play()

	# Crossfade
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(_music_player, "volume_db", linear_to_db(music_volume * master_volume), duration)
	tween.tween_property(_music_player_fade, "volume_db", -80.0, duration)
	tween.chain().tween_callback(_music_player_fade.stop)

func _updateMusicVolume() -> void:
	if _music_player:
		_music_player.volume_db = linear_to_db(music_volume * master_volume)

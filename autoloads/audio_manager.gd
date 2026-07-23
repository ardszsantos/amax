extends Node

# Autoload global de audio (registrado em project.godot como "Audio").
# Centraliza TODO o som do jogo: efeitos (SFX) e musica de fundo (OST).
#
# Quem chama nunca mexe com arquivo nem com player -- so pede pelo nome:
#     Audio.play_sfx("click")
#     Audio.play_sfx("swipe")
# A musica toca sozinha, estilo Minecraft: faixa -> silencio -> faixa (sem loop).

# ============================================================
# >>> EDITÁVEL: catalogo de efeitos sonoros (nome -> arquivo).
# Pra um som novo (ex.: compra), solte o arquivo em assets/sfx, some uma linha
# aqui e chame Audio.play_sfx("compra") de onde a acao acontece.
# ============================================================
const SFX := {
	"click": preload("res://assets/sfx/click.mp3"),
	"swipe": preload("res://assets/sfx/swipe.mp3"),
}

# ============================================================
# >>> EDITÁVEL: playlist da OST. Toca uma faixa, faz silencio, toca outra --
# nunca em loop continuo. Pra somar musicas (ost3...), solte o arquivo e
# adicione uma linha aqui.
# Cada faixa tem um "trim_db" pra NORMALIZAR o loudness entre elas (medido com
# ffmpeg: ost1 -22.6 LUFS, ost2 -17.3 LUFS). O trim iguala as duas pela mais
# baixa (so atenua, nunca amplifica -> sem risco de estouro); o quao suave fica
# no geral e o MUSIC_VOLUME_DB.
# IMPORTANTE: cada faixa importada com loop=false (senao nunca "termina" e o
# silencio nunca comeca).
# ============================================================
const MUSIC_TRACKS := [
	{ "stream": preload("res://assets/sfx/aura-ost1.mp3"), "trim_db": 0.0 },
	{ "stream": preload("res://assets/sfx/aura-ost2.mp3"), "trim_db": -5.3 },
]

# >>> EDITÁVEL: volumes em decibeis (0 = original; negativo = mais baixo).
const SFX_VOLUME_DB := 0.0
# Volume GERAL da musica, aplicado por cima do trim de cada faixa.
# Mais negativo = mais suave.
const MUSIC_VOLUME_DB := -8.0

# >>> EDITÁVEL: fade suave de entrada e saida de cada faixa (segundos), pra
# nao entrar nem cortar seco.
const MUSIC_FADE := 2.5
const _MUSIC_SILENCE_DB := -60.0

# >>> EDITÁVEL: janela de SILENCIO (segundos) entre uma faixa e a proxima.
# O tempo e sorteado nesse intervalo pra nao ficar mecanico.
const MUSIC_GAP_MIN := 40.0
const MUSIC_GAP_MAX := 90.0
# >>> EDITÁVEL: espera antes da PRIMEIRA faixa quando o jogo abre.
const MUSIC_INITIAL_DELAY := 4.0

# >>> EDITÁVEL: quantos SFX podem soar AO MESMO TEMPO sem se cortarem.
# Num clicker os cliques se sobrepoem, entao vale ter algumas "vozes".
const SFX_VOICES := 6

var _sfx_players: Array[AudioStreamPlayer] = []
var _sfx_rr := 0
var _music_player: AudioStreamPlayer
var _last_track := -1
var _music_tween: Tween

func _ready() -> void:
	for _i in SFX_VOICES:
		var p := AudioStreamPlayer.new()
		p.volume_db = SFX_VOLUME_DB
		add_child(p)
		_sfx_players.append(p)

	_music_player = AudioStreamPlayer.new()
	_music_player.volume_db = _MUSIC_SILENCE_DB
	add_child(_music_player)
	_music_player.finished.connect(_on_music_finished)

	if not MUSIC_TRACKS.is_empty():
		_schedule_next_track(MUSIC_INITIAL_DELAY)

# ----------------------------- SFX -----------------------------

func play_sfx(sfx_name: String) -> void:
	var stream: AudioStream = SFX.get(sfx_name)
	if stream == null:
		push_warning("Audio.play_sfx: SFX desconhecido '%s'" % sfx_name)
		return
	var player := _next_sfx_player()
	player.stream = stream
	player.play()

# Prefere uma voz livre; se todas estiverem tocando, reusa em rodizio
# (corta o som mais antigo -- aceitavel pra efeitos curtos).
func _next_sfx_player() -> AudioStreamPlayer:
	for p in _sfx_players:
		if not p.playing:
			return p
	var p := _sfx_players[_sfx_rr]
	_sfx_rr = (_sfx_rr + 1) % _sfx_players.size()
	return p

# -------------------- Musica (estilo Minecraft) --------------------

func _on_music_finished() -> void:
	_schedule_next_track(randf_range(MUSIC_GAP_MIN, MUSIC_GAP_MAX))

func _schedule_next_track(delay: float) -> void:
	await get_tree().create_timer(delay).timeout
	_play_random_track()

func _play_random_track() -> void:
	if MUSIC_TRACKS.is_empty():
		return
	var idx := 0
	# Com mais de uma faixa, evita repetir a mesma duas vezes seguidas.
	if MUSIC_TRACKS.size() > 1:
		idx = randi() % MUSIC_TRACKS.size()
		while idx == _last_track:
			idx = randi() % MUSIC_TRACKS.size()
	_last_track = idx

	var track = MUSIC_TRACKS[idx]
	var target_db: float = MUSIC_VOLUME_DB + track.trim_db
	_music_player.stream = track.stream
	# Fade-in: comeca no silencio e sobe suave ate o volume-alvo da faixa.
	_music_player.volume_db = _MUSIC_SILENCE_DB
	_music_player.play()
	_fade_music_to(target_db)
	# Fade-out no finalzinho da faixa (comeca MUSIC_FADE antes do fim).
	_schedule_fade_out(track.stream)

# Tween suave do volume da musica ate to_db (mata o fade anterior, se houver).
func _fade_music_to(to_db: float) -> void:
	if _music_tween and _music_tween.is_valid():
		_music_tween.kill()
	_music_tween = create_tween()
	_music_tween.tween_property(_music_player, "volume_db", to_db, MUSIC_FADE)

# Espera ate perto do fim da faixa e faz o fade-out, se ela ainda for a atual.
func _schedule_fade_out(stream: AudioStream) -> void:
	var length := stream.get_length()
	var wait := length - MUSIC_FADE
	if length <= 0.0 or wait <= 0.0:
		return
	await get_tree().create_timer(wait).timeout
	if _music_player.stream == stream and _music_player.playing:
		_fade_music_to(_MUSIC_SILENCE_DB)

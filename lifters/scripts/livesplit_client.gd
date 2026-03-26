# TCP client for LiveSplit Server. Sends commands like startorsplit, reset, setgametime.
extends Node

var _tcp: StreamPeerTCP = StreamPeerTCP.new()
var _host: String = "127.0.0.1"
var _port: int = 16834
var _connected: bool = false
var _enabled: bool = false
var _reconnect_timer: float = 0.0
const RECONNECT_INTERVAL: float = 5.0

signal connected
signal disconnected

func setup(config: Node) -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if config.get_setting("autosplit.enabled"):
		_host = config.get_setting("autosplit.livesplit_host")
		_port = config.get_setting("autosplit.livesplit_port")
		_enabled = true
		print("Lifters LiveSplit: Connecting to ", _host, ":", _port, "...")
		_tcp.connect_to_host(_host, _port)

func _process(delta: float) -> void:
	if not _enabled:
		return
	_tcp.poll()
	var status = _tcp.get_status()

	match status:
		StreamPeerTCP.STATUS_NONE:
			if _connected:
				_connected = false
				disconnected.emit()
				print("Lifters LiveSplit: Disconnected.")
			# Auto-reconnect
			_reconnect_timer += delta
			if _reconnect_timer >= RECONNECT_INTERVAL:
				_reconnect_timer = 0.0
				_tcp.connect_to_host(_host, _port)

		StreamPeerTCP.STATUS_CONNECTING:
			pass

		StreamPeerTCP.STATUS_CONNECTED:
			if not _connected:
				_connected = true
				_reconnect_timer = 0.0
				connected.emit()
				print("Lifters LiveSplit: Connected!")

		StreamPeerTCP.STATUS_ERROR:
			if _connected:
				_connected = false
				disconnected.emit()
			_tcp.disconnect_from_host()
			_reconnect_timer = 0.0

func send_command(cmd: String) -> void:
	if _connected:
		_tcp.put_data((cmd + "\r\n").to_utf8_buffer())

func start_or_split() -> void:
	send_command("startorsplit")

func start_timer() -> void:
	send_command("starttimer")

func reset() -> void:
	send_command("reset")

func set_game_time(seconds: float) -> void:
	var total_ms := int(seconds * 1000.0)
	var ms := total_ms % 1000
	var s := (total_ms / 1000) % 60
	var m := (total_ms / 60000) % 60
	var h := total_ms / 3600000
	send_command("setgametime %d:%02d:%02d.%03d" % [h, m, s, ms])

func pause_game_time() -> void:
	send_command("pausegametime")

func unpause_game_time() -> void:
	send_command("unpausegametime")

func is_connected_to_livesplit() -> bool:
	return _connected

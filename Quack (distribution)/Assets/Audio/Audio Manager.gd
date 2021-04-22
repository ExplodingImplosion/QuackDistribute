extends Node

# Plays a sound. The AudioStreamPlayer node will be added to the `parent`
# specified as parameter.
func play(parent: Node, stream: AudioStreamSample, volume = 0.0, max_vol = 6.0, pitch_scale = 1.0):
	var audio_stream_player = AudioStreamPlayer3D.new()
	
	parent.add_child(audio_stream_player)
	
	audio_stream_player.bus = "Master"
	audio_stream_player.stream = stream
	audio_stream_player.unit_db = volume
	audio_stream_player.pitch_scale = pitch_scale * Engine.get_time_scale()
	audio_stream_player.play()
	audio_stream_player.connect("finished", audio_stream_player, "queue_free")

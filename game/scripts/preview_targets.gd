extends SceneTree

# Visual QA at the real gameplay pixel scale; does not change encounter tuning.
const Main = preload("res://scripts/main.gd")
var game: Node3D

func _initialize() -> void:
	call_deferred("show_targets")

func show_targets() -> void:
	game = Main.new()
	root.add_child(game)
	game.sound.muted = true
	game.set_physics_process(false)
	game.reset_run(true, 123)
	game.message.visible = false
	var legend: Label = game.label_at(Vector2(46, 320), 14, Color.WHITE)
	legend.text = "ART PREVIEW / 5 TIERS\nSCORE        FLEET\nFIXED CREW   SCALED EMBLEM"
	game.add_child(legend)
	for tier: int in range(5):
		var z: float = -23.0 + tier * 6.0
		game.spawn_target(-2.8, z, 1, 20 * (tier + 1), SquadRules.target_reward(1, tier), tier)
		game.spawn_target(2.8, z, 0, 5 * (tier + 1), SquadRules.target_reward(0, tier), tier)
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	var capture: Image = root.get_texture().get_image()
	capture.save_png(ProjectSettings.globalize_path("res://../artifacts/enemy-tiers.png"))
	print("Saved artifacts/enemy-tiers.png")
	if "--capture" in OS.get_cmdline_user_args():
		game.free()
		quit()

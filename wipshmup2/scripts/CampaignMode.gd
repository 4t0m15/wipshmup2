extends GameMode
class_name CampaignMode

# CampaignMode - Standard campaign progression
# 8 stages with increasing difficulty

func _init() -> void:
	super._init()
	mode_name = "Campaign"
	mode_description = "Complete all 8 stages in order"
	is_endless = false
	has_bosses = true
	has_stages = true
	max_stage = 8
	starting_lives = 3
	starting_bombs = 3
	difficulty_scaling = 1.0
	score_multiplier = 1.0

func _setup_mode() -> void:
	"""Setup campaign mode"""
	print("[CampaignMode] Setting up campaign mode")
	
	# Set stage progression
	stage_progression = [1, 2, 3, 4, 5, 6, 7, 8]
	current_stage = 0  # Will be incremented to 1 in get_next_stage()
	
	# Reset difficulty
	difficulty_scaling = 1.0
	
	# Apply campaign-specific settings
	_apply_campaign_settings()

func _apply_campaign_settings() -> void:
	"""Apply campaign-specific settings"""
	# Set rank manager to campaign mode
	if RankManager and RankManager.has_method("set_mode"):
		RankManager.set_mode("campaign")
	
	# Set item drop rates for campaign
	if ItemDropManager and ItemDropManager.has_method("set_mode"):
		ItemDropManager.set_mode("campaign")

func get_stage_info(stage_number: int) -> Dictionary:
	"""Get information about a specific stage"""
	var stage = StageTemplateManager.get_stage_by_number(stage_number)
	if not stage:
		return {}
	
	return {
		"stage_name": stage.stage_name,
		"wave_count": stage.get_wave_count(),
		"has_boss": stage.has_boss(),
		"boss_name": stage.boss_encounter.boss_name if stage.has_boss() else ""
	}

func get_progress() -> Dictionary:
	"""Get campaign progress"""
	return {
		"current_stage": current_stage,
		"max_stage": max_stage,
		"progress_percent": float(current_stage) / float(max_stage) * 100.0,
		"stages_completed": current_stage - 1
	}

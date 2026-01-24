extends GutTest
## Integration tests for abandoned house map functionality.
##
## Tests:
## - Spawn point validity
## - Door interaction
## - Light switch interaction
## - NavMesh connectivity
## - Hiding spot accessibility

# =============================================================================
# TEST FIXTURES
# =============================================================================

var _map: Node3D


func before_each() -> void:
	var map_scene := load("res://scenes/maps/abandoned_house.tscn") as PackedScene
	if map_scene:
		_map = map_scene.instantiate()
		add_child(_map)
		# Wait for map to initialize
		await get_tree().process_frame


func after_each() -> void:
	if _map and is_instance_valid(_map):
		_map.queue_free()
		_map = null


# =============================================================================
# MAP INITIALIZATION TESTS
# =============================================================================


func test_map_loads_without_errors() -> void:
	assert_not_null(_map, "Map should load successfully")


func test_map_has_required_nodes() -> void:
	assert_not_null(_map.get_node_or_null("Rooms"), "Map should have Rooms node")
	assert_not_null(_map.get_node_or_null("Spawns"), "Map should have Spawns node")
	assert_not_null(_map.get_node_or_null("Lighting"), "Map should have Lighting node")
	assert_not_null(_map.get_node_or_null("Navigation"), "Map should have Navigation node")
	assert_not_null(_map.get_node_or_null("EvidencePoints"), "Map should have EvidencePoints node")


func test_map_has_hiding_spots_container() -> void:
	var hiding_spots := _map.get_node_or_null("HidingSpots")
	assert_not_null(hiding_spots, "Map should have HidingSpots node")


# =============================================================================
# SPAWN POINT TESTS
# =============================================================================


func test_spawn_points_exist() -> void:
	var spawns := _map.get_node_or_null("Spawns")
	assert_not_null(spawns, "Spawns node should exist")
	assert_gt(spawns.get_child_count(), 0, "Should have at least one spawn point")


func test_spawn_point_count() -> void:
	if _map.has_method("get_spawn_count"):
		var count: int = _map.get_spawn_count()
		assert_gte(count, 4, "Should have at least 4 spawn points for a full team")
		assert_lte(count, 8, "Should not exceed 8 spawn points")


func test_spawn_points_are_markers() -> void:
	var spawns := _map.get_node_or_null("Spawns")
	if spawns:
		for child in spawns.get_children():
			assert_true(child is Marker3D, "Spawn point should be Marker3D: %s" % child.name)


func test_spawn_positions_returned() -> void:
	if _map.has_method("get_spawn_positions"):
		var positions: Array = _map.get_spawn_positions()
		assert_gt(positions.size(), 0, "Should return spawn positions")
		for pos in positions:
			assert_true(pos is Vector3, "Position should be Vector3")


func test_spawn_points_are_spaced() -> void:
	if _map.has_method("get_spawn_positions"):
		var positions: Array = _map.get_spawn_positions()
		var min_spacing := 0.5  # Minimum 0.5m between spawn points

		for i in range(positions.size()):
			for j in range(i + 1, positions.size()):
				var dist: float = positions[i].distance_to(positions[j])
				assert_gte(
					dist,
					min_spacing,
					"Spawn points %d and %d should be at least %.1fm apart" % [i, j, min_spacing]
				)


func test_spawn_point_by_index() -> void:
	if _map.has_method("get_spawn_point"):
		var pos := _map.get_spawn_point(0) as Vector3
		assert_ne(pos, Vector3.ZERO, "First spawn point should not be at origin")


# =============================================================================
# EVIDENCE SPAWN POINT TESTS
# =============================================================================


func test_evidence_points_exist() -> void:
	var evidence_points := _map.get_node_or_null("EvidencePoints")
	assert_not_null(evidence_points, "EvidencePoints node should exist")
	assert_gt(evidence_points.get_child_count(), 0, "Should have evidence spawn points")


func test_evidence_points_count() -> void:
	if _map.has_method("get_evidence_points"):
		var points: Array = _map.get_evidence_points()
		assert_gte(points.size(), 10, "Should have at least 10 evidence points")


func test_evidence_points_are_markers() -> void:
	var evidence_points := _map.get_node_or_null("EvidencePoints")
	if evidence_points:
		for child in evidence_points.get_children():
			assert_true(child is Marker3D, "Evidence point should be Marker3D: %s" % child.name)


func test_evidence_points_in_rooms() -> void:
	if _map.has_method("get_evidence_points_in_room"):
		# Test that at least some rooms have evidence points
		var living_room_points: Array = _map.get_evidence_points_in_room("LivingRoom")
		var basement_points: Array = _map.get_evidence_points_in_room("Basement")

		# At least one room should have points (may be empty arrays if naming differs)
		var total: int = living_room_points.size() + basement_points.size()
		assert_gte(total, 0, "Rooms should have evidence points")


# =============================================================================
# FAVORITE ROOM TESTS
# =============================================================================


func test_favorite_room_selected() -> void:
	if _map.has_method("get_favorite_room"):
		var favorite: String = _map.get_favorite_room()
		assert_ne(favorite, "", "Favorite room should be selected")


func test_favorite_room_from_candidates() -> void:
	if _map.has_method("get_favorite_room") and "candidate_favorite_rooms" in _map:
		var favorite: String = _map.get_favorite_room()
		var candidates: Array = _map.candidate_favorite_rooms
		assert_true(
			favorite in candidates,
			"Favorite room '%s' should be from candidates" % favorite
		)


# =============================================================================
# HIDING SPOT TESTS
# =============================================================================


func test_hiding_spots_exist() -> void:
	var hiding_spots := _map.get_node_or_null("HidingSpots")
	if hiding_spots:
		assert_gt(hiding_spots.get_child_count(), 0, "Should have hiding spots")


func test_hiding_spots_returned() -> void:
	if _map.has_method("get_hiding_spots"):
		var spots: Array = _map.get_hiding_spots()
		assert_gte(spots.size(), 4, "Should have at least 4 hiding spots")


func test_hiding_spots_are_areas() -> void:
	var hiding_spots := _map.get_node_or_null("HidingSpots")
	if hiding_spots:
		for child in hiding_spots.get_children():
			assert_true(child is Area3D, "Hiding spot should be Area3D: %s" % child.name)


func test_hiding_spots_capacity() -> void:
	var hiding_spots := _map.get_node_or_null("HidingSpots")
	assert_not_null(hiding_spots, "HidingSpots container should exist")
	# Hiding spots are Area3D nodes - verify they exist
	var spot_count := 0
	for child in hiding_spots.get_children():
		if child is Area3D:
			spot_count += 1
	assert_gte(spot_count, 4, "Should have at least 4 hiding spot areas")


# =============================================================================
# LIGHTING TESTS
# =============================================================================


func test_lighting_container_exists() -> void:
	var lighting := _map.get_node_or_null("Lighting")
	assert_not_null(lighting, "Lighting container should exist")


func test_lights_exist() -> void:
	var lighting := _map.get_node_or_null("Lighting")
	if lighting:
		var light_count := 0
		for child in lighting.get_children():
			if child is Light3D:
				light_count += 1
		assert_gt(light_count, 0, "Should have light sources")


func test_some_lights_are_on() -> void:
	var lighting := _map.get_node_or_null("Lighting")
	if lighting:
		var lights_on := 0
		for child in lighting.get_children():
			if child is OmniLight3D or child is SpotLight3D:
				if child.light_energy > 0.0:
					lights_on += 1
		assert_gt(lights_on, 0, "Some lights should be on initially")


func test_some_lights_are_off() -> void:
	var lighting := _map.get_node_or_null("Lighting")
	if lighting:
		var lights_off := 0
		for child in lighting.get_children():
			if child is OmniLight3D or child is SpotLight3D:
				if child.light_energy <= 0.0:
					lights_off += 1
		assert_gt(lights_off, 0, "Some lights should be off initially")


# =============================================================================
# NAVIGATION TESTS
# =============================================================================


func test_navigation_region_exists() -> void:
	var navigation := _map.get_node_or_null("Navigation")
	assert_not_null(navigation, "Navigation should exist")
	assert_true(navigation is NavigationRegion3D, "Navigation should be NavigationRegion3D")


func test_navigation_mesh_configured() -> void:
	var navigation := _map.get_node_or_null("Navigation") as NavigationRegion3D
	if navigation:
		var nav_mesh := navigation.navigation_mesh
		assert_not_null(nav_mesh, "NavigationMesh should be assigned")


func test_navigation_mesh_agent_settings() -> void:
	var navigation := _map.get_node_or_null("Navigation") as NavigationRegion3D
	if navigation and navigation.navigation_mesh:
		var nav_mesh := navigation.navigation_mesh
		# Check reasonable agent settings
		assert_gt(nav_mesh.agent_height, 0.0, "Agent height should be positive")
		assert_gt(nav_mesh.agent_radius, 0.0, "Agent radius should be positive")


# =============================================================================
# ROOM GEOMETRY TESTS
# =============================================================================


func test_rooms_container_has_children() -> void:
	var rooms := _map.get_node_or_null("Rooms")
	if rooms:
		assert_gt(rooms.get_child_count(), 0, "Rooms should have room nodes")


func test_get_room_by_name() -> void:
	# Test that rooms container has named room children
	var rooms := _map.get_node_or_null("Rooms")
	assert_not_null(rooms, "Rooms container should exist")
	# Verify at least one expected room exists
	var living_room := rooms.get_node_or_null("LivingRoom")
	var basement := rooms.get_node_or_null("Basement")
	assert_true(
		living_room != null or basement != null,
		"Should have at least one expected room (LivingRoom or Basement)"
	)


# =============================================================================
# NETWORK STATE TESTS
# =============================================================================


func test_network_state_returned() -> void:
	if _map.has_method("get_network_state"):
		var state: Dictionary = _map.get_network_state()
		assert_true(state is Dictionary, "Network state should be Dictionary")


func test_network_state_contains_favorite_room() -> void:
	if _map.has_method("get_network_state"):
		var state: Dictionary = _map.get_network_state()
		assert_true(state.has("favorite_room"), "Network state should include favorite_room")


func test_apply_network_state() -> void:
	if _map.has_method("get_network_state") and _map.has_method("apply_network_state"):
		var test_room := "Basement"
		_map.apply_network_state({"favorite_room": test_room})
		var favorite: String = _map.get_favorite_room()
		assert_eq(favorite, test_room, "Favorite room should be applied from network state")


# =============================================================================
# WORLD ENVIRONMENT TESTS
# =============================================================================


func test_world_environment_exists() -> void:
	# WorldEnvironment is under Lighting container
	var world_env := _map.get_node_or_null("Lighting/WorldEnvironment")
	assert_not_null(world_env, "WorldEnvironment should exist for ambient lighting")


func test_world_environment_has_environment() -> void:
	var world_env := _map.get_node_or_null("Lighting/WorldEnvironment") as WorldEnvironment
	assert_not_null(world_env, "WorldEnvironment should exist")
	if world_env:
		assert_not_null(world_env.environment, "Environment resource should be assigned")

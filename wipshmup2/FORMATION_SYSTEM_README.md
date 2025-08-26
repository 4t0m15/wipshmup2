# Formation Flying System Documentation

## Overview

The Formation Flying System adds realistic military-style formations to the 1942-style shoot 'em up game. This system allows enemies to fly in coordinated formations, break formation for attacks, and rejoin dynamically, creating more tactical and visually impressive enemy encounters.

## Core Components

### 1. FormationManager (Singleton)
- **Location**: `scripts/FormationManager.gd`
- **Purpose**: Central coordinator for all formations in the game
- **Features**:
  - Creates and manages formation instances
  - Updates all formations each frame
  - Handles formation patterns and positioning
  - Manages formation lifecycle (create/dissolve)

### 2. FormationLeader
- **Location**: `scripts/FormationLeader.gd`
- **Purpose**: Specialized enemy that leads formations and issues commands
- **Features**:
  - Acts as formation coordinator
  - Issues tactical commands to formation members
  - Different leadership styles (Aggressive, Defensive, Evasive)
  - Manages formation integrity and rallying

### 3. EscortFighter
- **Location**: `scripts/EscortFighter.gd`
- **Purpose**: Intelligent escort enemies that protect formations
- **Features**:
  - Follows formation leaders
  - Breaks formation to engage threats
  - Returns to formation after engagement
  - Provides protective escort behavior

### 4. Enhanced ClassicEnemy
- **Location**: `scripts/ClassicEnemy.gd` (updated)
- **Purpose**: Base enemy with formation capabilities
- **Features**:
  - Can join existing formations
  - Dynamic formation break/rejoin mechanics
  - Formation-aware movement and behavior

## Formation Patterns

### Available Patterns
- **LINE_HORIZONTAL**: Straight horizontal line
- **LINE_VERTICAL**: Vertical line (for entry)
- **V_FORMATION**: Classic V formation
- **DIAMOND**: Diamond pattern
- **ECHELON_LEFT**: Staggered left formation
- **ECHELON_RIGHT**: Staggered right formation
- **CIRCLE**: Circular formation
- **COLUMN**: Column formation

### Pattern Usage
```gdscript
# Create a V-formation
formation_id = formation_manager.create_formation(leader, FormationManager.FormationPattern.V_FORMATION)
```

## Formation Types

### 1. Fighter Squad
- **Leader**: FormationFighter
- **Members**: Classic TYPE01 fighters
- **Pattern**: V_FORMATION
- **Behavior**: Coordinated attack runs, breaks for individual engagements

### 2. Bomber Escort
- **Leader**: FormationBomber
- **Escorts**: EscortFighter instances
- **Pattern**: LINE_HORIZONTAL for escorts, independent for bomber
- **Behavior**: Bomber drops payloads while escorts provide protection

### 3. Naval Patrol
- **Leader**: Destroyer (TYPE04)
- **Members**: Additional destroyers or submarines
- **Pattern**: LINE_HORIZONTAL or ECHELON
- **Behavior**: Patrol patterns, surface attacks from submarines

### 4. Mixed Fleet
- **Combination**: Multiple formation types
- **Pattern**: Coordinated multi-unit attacks
- **Behavior**: Complex tactical scenarios

## Stage Integration

### Formation Spawning Functions

```gdscript
# Spawn a fighter formation
_spawn_fighter_formation(position, member_count)

# Spawn a bomber with escorts
_spawn_bomber_escort_formation(position, escort_count)

# Spawn a defensive turret line
_spawn_defensive_line(position, turret_count)

# Spawn formation waves
_spawn_formation_wave("fighter_squad", count, base_position)
_spawn_formation_wave("bomber_escort", count, base_position)
_spawn_formation_wave("mixed_fleet", count, base_position)
```

### Stage Examples

#### Stage 1: Basic Formation Introduction
```gdscript
# Simple V-formations
_spawn_formation_wave("fighter_squad", 2, Vector2(rect.size.x * 0.3, -20))

# Ground defense
_spawn_defensive_line(Vector2(0, 140), 3)

# Bomber escort formations
_spawn_formation_wave("bomber_escort", 1, Vector2(rect.size.x * 0.5, -30))
```

#### Stage 2: Advanced Tactics
```gdscript
# Flanking maneuvers
_spawn_formation_wave("fighter_squad", 1, Vector2(-30, 30))   # Left flank
_spawn_formation_wave("fighter_squad", 1, Vector2(rect.size.x + 30, 30))  # Right flank

# Echelon attacks
for i in range(3):
    _spawn_formation_wave("fighter_squad", 1, Vector2(-20 + i * 40, -15 - i * 20))
```

## Enemy Behavior States

### Formation States
- **FORMATION**: Maintaining formation position
- **BREAKING**: Transitioning to independent action
- **ENGAGING**: Actively engaging player
- **RETURNING**: Returning to formation
- **SCREENING**: Screening ahead of formation

### Leadership Styles
- **Aggressive**: Pushes formation forward, commands frequent attacks
- **Defensive**: Maintains tight formation, prioritizes protection
- **Evasive**: Spreads formation for safety, avoids direct confrontation

## Dynamic Combat Mechanics

### Formation Breaking
Enemies can break formation to:
- Engage the player directly
- Perform dive attacks
- Intercept threats to the formation
- Execute tactical maneuvers

### Formation Rejoining
After independent action, enemies will:
- Attempt to return to formation
- Rally to the formation leader
- Resume coordinated behavior

### Escort Behavior
Escort fighters will:
- Maintain protective positions around the formation
- Break off to engage threats
- Screen for the main formation
- Provide covering fire

## Usage Examples

### Creating a Custom Formation

```gdscript
# 1. Create formation leader
var leader = FORMATION_FIGHTER.instantiate()
leader.global_position = Vector2(160, -50)
leader.formation_pattern = FormationManager.FormationPattern.V_FORMATION
_connect_enemy_signals(leader)
get_node("GameViewport/Enemies").add_child(leader)

# 2. Add wingmen
for i in range(2):
    var wingman = TYPE01.instantiate()
    wingman.global_position = leader.global_position + Vector2(i * 50, 20)
    _connect_enemy_signals(wingman)
    get_node("GameViewport/Enemies").add_child(wingman)
    leader.add_formation_member(wingman)
```

### Advanced Formation Tactics

```gdscript
# Create a complex mixed formation
_spawn_formation_wave("mixed_fleet", 2, Vector2(100, -30))

# Add defensive elements
_spawn_defensive_line(Vector2(0, 140), 4)

# Create flanking maneuvers
_spawn_formation_wave("fighter_squad", 1, Vector2(-50, 20))
_spawn_formation_wave("fighter_squad", 1, Vector2(370, 20))
```

## Performance Considerations

### Optimization Tips
- Formation updates are processed once per frame via FormationManager
- Large formations (8+ members) may impact performance
- Consider using formation patterns appropriate to screen size
- Escorts have higher performance cost due to AI complexity

### Recommended Formation Sizes
- **Small**: 2-4 members (best performance)
- **Medium**: 5-7 members (balanced)
- **Large**: 8+ members (higher performance cost)

## Configuration

### Formation Parameters
- **Spacing**: Distance between formation members (default: 40px)
- **Speed**: Formation movement speed (default: 60px/s)
- **Command Interval**: How often leaders issue commands (default: 3s)
- **Break Distance**: Distance escorts maintain from leader (default: 80px)

### Enemy-Specific Tuning
```gdscript
# Adjust formation behavior per enemy type
formation_fighter.formation_spacing = 45.0
formation_fighter.leadership_style = 0  # Aggressive
formation_fighter.max_formation_members = 4

bomber_formation.formation_spacing = 60.0
bomber_formation.leadership_style = 1  # Defensive
```

## Troubleshooting

### Common Issues

1. **Formations Not Appearing**
   - Check FormationManager is initialized in StageController
   - Verify formation leader is properly instantiated
   - Ensure formation pattern is valid

2. **Escorts Not Following**
   - Confirm escort leader is set correctly
   - Check formation ID consistency
   - Verify escort AI is not in independent mode

3. **Performance Issues**
   - Reduce formation sizes
   - Increase command intervals
   - Limit simultaneous formations

### Debug Information
Enable debug prints in StageController to see formation status:
```gdscript
print("Formation created: ", formation_id)
print("Formation members: ", formation.get_member_count())
```

## Future Enhancements

### Planned Features
- **Multi-leader formations**: Multiple leaders coordinating
- **Dynamic formation reshaping**: Change patterns during combat
- **Player formation flying**: Allow player to have wingmen
- **Advanced AI tactics**: More sophisticated formation behaviors
- **Visual formation indicators**: Show formation status to player

This formation system transforms the game from simple enemy waves into tactical aerial combat scenarios, providing a much more engaging and authentic 1942-style experience.

## wipshmup2 - a shmup game inspired by Cho Ren Sha 68K, 1942, the TouHou Project series and Galaga/Galaxian.

Credits: Harrison Allen for the base of my own CRT shader which is very heavily modified from his which can be found @ (https://godotshaders.com/shader/crt-with-luminance-preservation/)

Kody Gentry for the base of my own dithering "shader" (my version isn't really a shader more of an effect) which can be found @ (https://github.com/kodygentry/godot-dot-shader)

"saavane" for the background music (the music is under the pixabay license (https://pixabay.com/service/license-summary/)) it can be found @ (https://pixabay.com/music/synthwave-retro-waves-139640/)

controls: arrow keys to move x to deploy bomb and space to shoot

## Architecture

```
┌────────────────────────────────────────────────────────────────────────────────────────┐
│                                    GODOT ENGINE                                        │
│                                                                                        │
│  ┌─────────────────────────────────────────────────────────────────────────────────┐   │
│  │                              MAIN SCENE (Main.gd)                               │   │
│  │                            Game Loop & Coordination                             │   │
│  │                                                                                 │   │
│  │  ┌────────────────────┐  ┌─────────────────────┐  ┌─────────────────────┐       │   │
│  │  │   GameViewport     │  │        HUD          │  │    Post-Processing  │       │   │
│  │  │   (320x180)        │  │   (CanvasLayer)     │  │     Pipeline        │       │   │
│  │  │                    │  │                     │  │                     │       │   │
│  │  │  ┌──────────────┐  │  │  ┌───────────────┐  │  │  ┌───────────────┐  │       │   │
│  │  │  │   PLAYER     │  │  │  │  Score/Lives  │  │  │  │   Dither      │  │       │   │
│  │  │  │ (Player.gd)  │  │  │  │  FPS Counter  │  │  │  │   Shader      │  │       │   │
│  │  │  │              │  │  │  │  Game Over    │  │  │  │               │  │       │   │
│  │  │  │ ┌─────────┐  │  │  │  │  Popups       │  │  │  │       ▼       │  │       │   │
│  │  │  │ │Movement │  │  │  │  └───────────────┘  │  │  │   CRT Shader  │  │       │   │
│  │  │  │ │Shooting │  │  │  │                     │  │  └───────────────┘  │       │   │
│  │  │  │ │Hit Det. │  │  │  │                     │  │                     │       │   │
│  │  │  │ │Invuln.  │  │  │  │                     │  │                     │       │   │
│  │  │  │ └─────────┘  │  │  │                     │  │                     │       │   │
│  │  │  └──────────────┘  │  │                     │  │                     │       │   │
│  │  │                    │  │                     │  │                     │       │   │
│  │  │  ┌──────────────┐  │  │                     │  │                     │       │   │
│  │  │  │   ENEMIES    │  │  │                     │  │                     │       │   │
│  │  │  │ Container    │  │  │                     │  │                     │       │   │
│  │  │  │              │  │  │                     │  │                     │       │   │
│  │  │  │ ┌─────────┐  │  │  │                     │  │                     │       │   │
│  │  │  │ │ Enemy   │  │  │  │                     │  │                     │       │   │
│  │  │  │ │Instances│  │  │  │                     │  │                     │       │   │
│  │  │  │ │(13 Types)│ │  │  │                     │  │                     │       │   │
│  │  │  │ │+ Bosses │  │  │  │                     │  │                     │       │   │
│  │  │  │ └─────────┘  │  │  │                     │  │                     │       │   │
│  │  │  └──────────────┘  │  │                     │  │                     │       │   │
│  │  │                    │  │                     │  │                     │       │   │
│  │  │  ┌──────────────┐  │  │                     │  │                     │       │   │
│  │  │  │   BULLETS    │  │  │                     │  │                     │       │   │
│  │  │  │ Container    │  │  │                     │  │                     │       │   │
│  │  │  │              │  │  │                     │  │                     │       │   │
│  │  │  │ ┌─────────┐  │  │  │                     │  │                     │       │   │
│  │  │  │ │ Player  │  │  │  │                     │  │                     │       │   │
│  │  │  │ │Bullets  │  │  │  │                     │  │                     │       │   │
│  │  │  │ │& Enemy  │  │  │  │                     │  │                     │       │   │
│  │  │  │ │Bullets  │  │  │  │                     │  │                     │       │   │
│  │  │  │ └─────────┘  │  │  │                     │  │                     │       │   │
│  │  │  └──────────────┘  │  │                     │  │                     │       │   │
│  │  └────────────────────┘  └─────────────────────┘  └─────────────────────┘       │   │
│  └─────────────────────────────────────────────────────────────────────────────────┘   │
└────────────────────────────────────────────────────────────────────────────────────────┘

┌───────────────────────────────────────────────────────────────────────────────────────┐
│                                 AUTOLOAD SYSTEMS                                      │
│                              (Global Singletons)                                      │
│                                                                                       │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐                        │
│  │  AudioManager   │  │  RankManager    │  │ DifficultyConfig│                        │
│  │   (Audio.gd)    │  │  (Rank.gd)      │  │   (Config.gd)   │                        │
│  │                 │  │                 │  │                 │                        │
│  │ ┌─────────────┐ │  │ ┌─────────────┐ │  │ ┌─────────────┐ │                        │
│  │ │Procedural   │ │  │ │Dynamic      │ │  │ │Configurable │ │                        │
│  │ │Sound Effects│ │  │ │Difficulty   │ │  │ │Parameters   │ │                        │
│  │ │Generation   │ │  │ │Scaling      │ │  │ │for Game     │ │                        │
│  │ │             │ │  │ │             │ │  │ │Balance      │ │                        │
│  │ │• Beeps      │ │  │ │• Speed      │ │  │ │             │ │                        │
│  │ │• Boops      │ │  │ │• HP         │ │  │ │• Min/Max    │ │                        │
│  │ │• Explosions │ │  │ │• Bullet     │ │  │ │  Rank       │ │                        │
│  │ │• Extends    │ │  │ │  Speed      │ │  │ │• Multiplier │ │                        │
│  │ └─────────────┘ │  │ │• Pattern    │ │  │ │  Caps       │ │                        │
│  └─────────────────┘  │ │  Density    │ │  │ └─────────────┘ │                        │
│                       │ └─────────────┘ │  └─────────────────┘                        │
│                       └─────────────────┘                                             │
└───────────────────────────────────────────────────────────────────────────────────────┘

┌───────────────────────────────────────────────────────────────────────────────────────┐
│                               GAME SYSTEMS LAYER                                      │
│                                                                                       │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐   │
│  │ StageController │  │BulletPatterns   │  │FormationManager │  │   BossBase      │   │
│  │ (StageCtrl.gd)  │  │(Patterns.gd)    │  │(Formation.gd)   │  │  (Boss.gd)      │   │
│  │                 │  │                 │  │                 │  │                 │   │
│  │ ┌─────────────┐ │  │ ┌─────────────┐ │  │ ┌─────────────┐ │  │ ┌─────────────┐ │   │
│  │ │Stage        │ │  │ │Static       │ │  │ │Enemy        │ │  │ │Multi-Phase  │ │   │
│  │ │Progression  │ │  │ │Bullet       │ │  │ │Formation    │ │  │ │Boss Logic   │ │   │
│  │ │& Enemy      │ │  │ │Pattern      │ │  │ │Coordination │ │  │ │             │ │   │
│  │ │Spawning     │ │  │ │Functions    │ │  │ │             │ │  │ │• HP Phases  │ │   │
│  │ │             │ │  │ │             │ │  │ │• V-Formation│ │  │ │• Pattern    │ │   │
│  │ │• 8 Stages   │ │  │ │• Rings      │ │  │ │• Diamond    │ │  │ │  Changes    │ │   │
│  │ │• Wave Types │ │  │ │• Fans       │ │  │ │• Echelon    │ │  │ │• Signals    │ │   │
│  │ │• Boss Fights│ │  │ │• Sweeps     │ │  │ │• Circle     │ │  │ │             │ │   │
│  │ │• Formations │ │  │ │• Beams      │ │  │ │• Line       │ │  │ └─────────────┘ │   │
│  │ └─────────────┘ │  │ │• Cross      │ │  │ └─────────────┘ │  └─────────────────┘   │
│  └─────────────────┘  │ │  Patterns   │ │  └─────────────────┘                        │
│                       │ └─────────────┘ │                                             │
│                       └─────────────────┘                                             │
└───────────────────────────────────────────────────────────────────────────────────────┘
```

## Data Flow

```

     ┌─────────────┐              ┌──────────────┐              ┌─────────────┐
     │   INPUT     │              │   GAME       │              │   OUTPUT    │
     │             │              │   STATE      │              │             │
     │ ┌─────────┐ │   signals    │              │   updates    │ ┌─────────┐ │
     │ │Movement │ ├──────────────┤ ┌──────────┐ ├──────────────┤ │Visual   │ │
     │ │Keys     │ │              │ │Lives     │ │              │ │Elements │ │
     │ └─────────┘ │              │ │Score     │ │              │ └─────────┘ │
     │             │              │ │Bombs     │ │              │             │
     │ ┌─────────┐ │              │ │Game Over │ │              │ ┌─────────┐ │
     │ │Shooting │ ├──────────────┤ │Rank      │ ├──────────────┤ │Audio    │ │
     │ │(Accept) │ │              │ └──────────┘ │              │ │Effects  │ │
     │ └─────────┘ │              │              │              │ └─────────┘ │
     │             │              │ ┌──────────┐ │              │             │
     │ ┌─────────┐ │              │ │Player    │ │              │ ┌─────────┐ │
     │ │Bomb     │ ├──────────────┤ │Position  │ ├──────────────┤ │Shader   │ │
     │ │(X Key)  │ │              │ │Enemy     │ │              │ │Effects  │ │
     │ └─────────┘ │              │ │Positions │ │              │ └─────────┘ │
     │             │              │ │Bullet    │ │              │             │
     │ ┌─────────┐ │              │ │Positions │ │              │             │
     │ │Focus    │ ├──────────────┤ └──────────┘ │              │             │
     │ │(Shift)  │ │              │              │              │             │
     │ └─────────┘ │              └──────────────┘              │             │
     └─────────────┘                                            └─────────────┘
```

## Collision System

```

                    ┌────────────────────────────────────────┐
                    │            COLLISION GROUPS            │
                    │                                        │
                    │  ┌─────────────┐   ┌─────────────┐     │
                    │  │   PLAYER    │   │   ENEMY     │     │
                    │  │             │   │             │     │
                    │  │ ┌─────────┐ │   │ ┌─────────┐ │     │
                    │  │ │Hurtbox  │ │   │ │Body     │ │     │
                    │  │ │(Area2D) │ │   │ │(Area2D) │ │     │
                    │  │ └─────────┘ │   │ └─────────┘ │     │
                    │  └─────────────┘   └─────────────┘     │
                    │         │                 │            │
                    │         │     COLLISION   │            │
                    │         └─────────────────┘            │
                    │                                        │
                    │  ┌─────────────┐   ┌─────────────┐     │
                    │  │PLAYER_BULLET│   │ENEMY_BULLET │     │
                    │  │             │   │             │     │
                    │  │ ┌─────────┐ │   │ ┌─────────┐ │     │
                    │  │ │Hitbox   │ │   │ │Hitbox   │ │     │
                    │  │ │(Area2D) │ │   │ │(Area2D) │ │     │
                    │  │ └─────────┘ │   │ └─────────┘ │     │
                    │  └─────────────┘   └─────────────┘     │
                    │         │                 │            │
                    │         │   COLLISION     │            │
                    │         └─────────────────┘            │
                    └────────────────────────────────────────┘
```

## Signal Flow Chart

```

    Player.hit ──────────────────────► Main._on_player_hit()
       │                                       │
       ▼                                       ▼
   Lives Decrease                        Audio Effect
                                              │
    Enemy.killed ────────────────────► StageController.enemy_killed
       │                                       │
       ▼                                       ▼
   Points Award ──────────────────────► Main._on_enemy_killed()
       │                                       │
       ▼                                       ▼
   Score Update                           RankManager Update

    Boss.defeated ───────────────────► StageController.boss_defeated
       │                                       │
       ▼                                       ▼
   Stage Progress                         HUD Popup

    Engine.get_frames_per_second() ──────► HUD._process()
                                              │
                                              ▼
                                        FPS Display (000 format)
```

## Enemy Behavior Types

```

    ┌──────────────────────────────────────────────────────────────────────────────────┐
    │                               REGULAR ENEMIES                                    │
    │                                                                                  │
    │  Type 01: Straight Aimed     │ Type 02: Sine Fan       │ Type 03: Zigzag Shotgun │
    │  Type 04: Diagonal Left Ring │ Type 05: Diagonal Right │ Type 06: Dive Aimed     │
    │  Type 07: Chaser Drone       │ Type 08: Heavy Bomber   │ Type 09: Weaving Inter. │
    │  Type 10: Diving Assault     │ Type 11: Patrol Gunship │ Type 12: Kamikaze Strike│
    │  Type 13: Formation Leader   │                         │                         │
    │                                                                                  │
    │                               FORMATION TYPES                                    │
    │                                                                                  │
    │  Formation Fighter           │ Formation Bomber        │ Escort Fighter          │
    │                                                                                  │
    │                                 BOSS TYPES                                       │
    │                                                                                  │
    │  Gliath      │ Type0       │ Iron Casket    │ Graf Zeppelin  │ Fortress          │
    │  Cross Sinker│ Blockade    │ FGR            │ BB             │                   │
    └──────────────────────────────────────────────────────────────────────────────────┘
```

## Rendering Pipeline

```

    Game Content (320x180) --> GameViewport
                                     │
                                     ▼
                              Dither Shader ──► PostDitherViewport  
                                     │                    │
                                     ▼                    ▼
                               Black & White         CRT Shader
                               High Contrast              │
                                     │                    ▼
                                     └------------► What you see (final output)
```

---

### Core Infrastructure

```
┌────────────────────────────────────────────────────────────────────────────────────────┐
│                              EVENT-DRIVEN ARCHITECTURE                                 │
│                                                                                        │
│  ┌─────────────────────────────────────────────────────────────────────────────────┐   │
│  │                              AUTOLOAD SYSTEMS                                   │   │
│  │                              (Global Singletons)                               │   │
│  │                                                                                 │   │
│  │  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────┐ │   │
│  │  │   EventBus      │  │   GameState     │  │ EntityFactory   │  │ConfigManager│ │   │
│  │  │ (Event System)  │  │ (Game State)   │  │ (Spawn System)  │  │(Config Mgmt)│ │   │
│  │  │                 │  │                 │  │                 │  │             │ │   │
│  │  │ ┌─────────────┐ │  │ ┌─────────────┐ │  │ ┌─────────────┐ │  │ ┌─────────┐ │ │   │
│  │  │ │Game Events  │ │  │ │Player State │ │  │ │Player Spawn │ │  │ │JSON/CFG │ │ │   │
│  │  │ │Combat Events│ │  │ │Game Flow    │ │  │ │Enemy Spawn  │ │  │ │Hot Reload│ │ │   │
│  │  │ │Visual Events│ │  │ │Streak System│ │  │ │Bullet Spawn │ │  │ │External  │ │ │   │
│  │  │ │Audio Events │ │  │ │State Events │ │  │ │Object Pool  │ │  │ │Configs   │ │ │   │
│  │  │ └─────────────┘ │  │ └─────────────┘ │  │ └─────────────┘ │  │ └─────────┘ │ │   │
│  │  └─────────────────┘  └─────────────────┘  └─────────────────┘  └─────────────┘ │   │
│  │                                                                                 │   │
│  │  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────┐ │   │
│  │  │EnemyTemplateMgr │  │BossTemplateMgr  │  │StageTemplateMgr │  │GameModeMgr  │ │   │
│  │  │(Enemy Data)     │  │(Boss Data)      │  │(Stage Data)     │  │(Mode Mgmt)  │ │   │
│  │  │                 │  │                 │  │                 │  │             │ │   │
│  │  │ ┌─────────────┐ │  │ ┌─────────────┐ │  │ ┌─────────────┐ │  │ ┌─────────┐ │ │   │
│  │  │ │Enemy Types  │ │  │ │Boss Phases  │ │  │ │Stage Defs   │ │  │ │Campaign│ │ │   │
│  │  │ │Behaviors    │ │  │ │Transitions  │ │  │ │Wave Defs    │ │  │ │Endless  │ │ │   │
│  │  │ │Templates    │ │  │ │Visual FX    │ │  │ │Boss Encount │ │  │ │Boss Rush│ │ │   │
│  │  │ │Data-Driven  │ │  │ │Data-Driven  │ │  │ │Data-Driven  │ │  │ │Practice │ │ │   │
│  │  │ └─────────────┘ │  │ └─────────────┘ │  │ └─────────────┘ │  │ └─────────┘ │ │   │
│  │  └─────────────────┘  └─────────────────┘  └─────────────────┘  └─────────────┘ │   │
│  └─────────────────────────────────────────────────────────────────────────────────┘   │
└────────────────────────────────────────────────────────────────────────────────────────┘
```

### Specialized Systems

```
┌───────────────────────────────────────────────────────────────────────────────────────┐
│                               SPECIALIZED SYSTEMS                                     │
│                                                                                       │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐   │
│  │PlayerController │  │ CombatSystem    │  │VisualEffectsSys │  │RankPressureSys  │   │
│  │ (Input/Move)    │  │ (Damage/Logic)  │  │ (Screen FX)     │  │ (Rank Pressure) │   │
│  │                 │  │                 │  │                 │  │                 │   │
│  │ ┌─────────────┐ │  │ ┌─────────────┐ │  │ ┌─────────────┐ │  │ ┌─────────────┐ │   │
│  │ │Movement     │ │  │ │Damage Calc  │ │  │ │Screen Shake │ │  │ │Background   │ │   │
│  │ │Shooting     │ │  │ │Hit Detection│ │  │ │Hit Stop     │ │  │ │Tinting      │ │   │
│  │ │Bomb Logic   │ │  │ │Combat Events│ │  │ │Flash Effects│ │  │ │Continuous   │ │   │
│  │ │Input Handle │ │  │ │Streak Logic │ │  │ │Explosions   │ │  │ │Shake        │ │   │
│  │ └─────────────┘ │  │ └─────────────┘ │  │ └─────────────┘ │  │ └─────────────┘ │   │
│  └─────────────────┘  └─────────────────┘  └─────────────────┘  └─────────────────┘   │
└───────────────────────────────────────────────────────────────────────────────────────┘
```

### Component-Based Enemy System

```
┌───────────────────────────────────────────────────────────────────────────────────────┐
│                            ENEMY BEHAVIOR COMPONENTS                                 │
│                                                                                       │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐   │
│  │MovementBehavior │  │ AttackBehavior  │  │StraightDownBeh  │  │AimedShotBeh    │   │
│  │ (Base Class)    │  │ (Base Class)     │  │ (Movement)      │  │ (Attack)       │   │
│  │                 │  │                 │  │                 │  │                 │   │
│  │ ┌─────────────┐ │  │ ┌─────────────┐ │  │ ┌─────────────┐ │  │ ┌─────────────┐ │   │
│  │ │Speed        │ │  │ │Fire Rate    │ │  │ │Simple Down  │ │  │ │Player Aim   │ │   │
│  │ │Direction    │ │  │ │Bullet Speed │ │  │ │Movement     │ │  │ │Lead Target  │ │   │
│  │ │Acceleration │ │  │ │Damage       │ │  │ │             │ │  │ │             │ │   │
│  │ │Rank Scaling │ │  │ │Patterns     │ │  │ │             │ │  │ │             │ │   │
│  │ └─────────────┘ │  │ └─────────────┘ │  │ └─────────────┘ │  │ └─────────────┘ │   │
│  └─────────────────┘  └─────────────────┘  └─────────────────┘  └─────────────────┘   │
│                                                                                       │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐   │
│  │SineWaveBehavior │  │ZigzagBehavior   │  │DiveBehavior     │  │FanBehavior      │   │
│  │ (Movement)      │  │ (Movement)      │  │ (Movement)      │  │ (Attack)        │   │
│  │                 │  │                 │  │                 │  │                 │   │
│  │ ┌─────────────┐ │  │ ┌─────────────┐ │  │ ┌─────────────┐ │  │ ┌─────────────┐ │   │
│  │ │Wave Motion  │ │  │ │Zigzag Path  │ │  │ │Dive & Level │ │  │ │Fan Pattern  │ │   │
│  │ │Amplitude    │ │  │ │Amplitude    │ │  │ │Speed Change │ │  │ │Angle Spread │ │   │
│  │ │Frequency    │ │  │ │Frequency    │ │  │ │Distance     │ │  │ │Bullet Count │ │   │
│  │ │             │ │  │ │             │ │  │ │             │ │  │ │             │ │   │
│  │ └─────────────┘ │  │ └─────────────┘ │  │ └─────────────┘ │  │ └─────────────┘ │   │
│  └─────────────────┘  └─────────────────┘  └─────────────────┘  └─────────────────┘   │
└───────────────────────────────────────────────────────────────────────────────────────┘
```

### Data-Driven Content Creation

```
┌───────────────────────────────────────────────────────────────────────────────────────┐
│                            DATA-DRIVEN CONTENT SYSTEM                                │
│                                                                                       │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐   │
│  │EnemyTemplate    │  │BossTemplate     │  │StageDefinition  │  │GameMode         │   │
│  │ (Enemy Data)    │  │ (Boss Data)     │  │ (Stage Data)    │  │ (Mode Data)     │   │
│  │                 │  │                 │  │                 │  │                 │   │
│  │ ┌─────────────┐ │  │ ┌─────────────┐ │  │ ┌─────────────┐ │  │ ┌─────────────┐ │   │
│  │ │Type Name    │ │  │ │Boss Name    │ │  │ │Stage Name   │ │  │ │Mode Name    │ │   │
│  │ │HP/Points    │ │  │ │Max HP       │ │  │ │Wave Defs    │ │  │ │Description  │ │   │
│  │ │Speed        │ │  │ │Phases       │ │  │ │Boss Encounter│ │  │ │Rules        │ │   │
│  │ │Behaviors    │ │  │ │Visual FX    │ │  │ │Background   │ │  │ │Progression  │ │   │
│  │ │Properties   │ │  │ │Transitions  │ │  │ │Music        │ │  │ │Scoring      │ │   │
│  │ └─────────────┘ │  │ └─────────────┘ │  │ └─────────────┘ │  │ └─────────────┘ │   │
│  └─────────────────┘  └─────────────────┘  └─────────────────┘  └─────────────────┘   │
└───────────────────────────────────────────────────────────────────────────────────────┘
```

### Game Mode System

```
┌───────────────────────────────────────────────────────────────────────────────────────┐
│                               GAME MODE SYSTEM                                       │
│                                                                                       │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐   │
│  │CampaignMode     │  │EndlessMode      │  │BossRushMode     │  │PracticeMode     │   │
│  │ (8 Stages)      │  │ (Infinite)      │  │ (Boss Only) │  │ (Specific)      │   │
│  │                 │  │                 │  │                 │  │                 │   │
│  │ ┌─────────────┐ │  │ ┌─────────────┐ │  │ ┌─────────────┐ │  │ ┌─────────────┐ │   │
│  │ │Linear Prog  │ │  │ │Loop Stages  │ │  │ │Boss Sequence│ │  │ │Stage Select  │ │   │
│  │ │8 Stages     │ │  │ │Difficulty   │ │  │ │Boss Scaling │ │  │ │Boss Select   │ │   │
│  │ │Boss Fights  │ │  │ │Scaling      │ │  │ │Health Boost │ │  │ │Infinite Lives│ │   │
│  │ │Progression  │ │  │ │Endless      │ │  │ │Damage Boost │ │  │ │Slow Motion   │ │   │
│  │ └─────────────┘ │  │ └─────────────┘ │  │ └─────────────┘ │  │ └─────────────┘ │   │
│  └─────────────────┘  └─────────────────┘  └─────────────────┘  └─────────────────┘   │
└───────────────────────────────────────────────────────────────────────────────────────┘
```

### Event Flow Architecture

```
┌───────────────────────────────────────────────────────────────────────────────────────┐
│                              EVENT FLOW SYSTEM                                       │
│                                                                                       │
│  ┌─────────────────┐              ┌─────────────────┐              ┌─────────────┐   │
│  │   INPUT         │              │   EVENTBUS     │              │   SYSTEMS   │   │
│  │                 │              │                 │              │             │   │
│  │ ┌─────────────┐ │   events    │ ┌─────────────┐ │   events    │ ┌─────────┐ │   │
│  │ │Player Input │ ├─────────────► │ │Game Events │ ├─────────────► │ │Combat  │ │   │
│  │ │Movement     │ │              │ │Combat Evts │ │              │ │Visual   │ │   │
│  │ │Shooting     │ │              │ │Visual Evts │ │              │ │Audio    │ │   │
│  │ │Bomb         │ │              │ │Audio Evts  │ │              │ │Rank     │ │   │
│  │ └─────────────┘ │              │ └─────────────┘ │              │ └─────────┘ │   │
│  └─────────────────┘              └─────────────────┘              └─────────────┘   │
└───────────────────────────────────────────────────────────────────────────────────────┘
```

### Development Velocity Improvements

```
┌───────────────────────────────────────────────────────────────────────────────────────┐
│                            DEVELOPMENT VELOCITY                                       │
│                                                                                       │
│  TASK                    BEFORE        AFTER         IMPROVEMENT                     │
│  ──────────────────────────────────────────────────────────────────────────────────── │
│  New Enemy Type         30 minutes    5 minutes     6x faster                       │
│  New Stage              45 minutes    10 minutes    4.5x faster                     │
│  New Game Mode          Not possible   30 minutes    New capability                   │
│  Debug Signal Issue     20 minutes     5 minutes     4x faster                       │
│  Add Visual Effect      Find location  Subscribe    10x easier                       │
│  Modify Game Balance    Edit code      Edit config  5x easier                        │
└───────────────────────────────────────────────────────────────────────────────────────┘
```

### File Structure

```
scripts/
├─ autoload/              # Centralized Singletons
│  ├─ EventBus.gd        # Event system
│  ├─ GameState.gd       # Game state management
│  ├─ EntityFactory.gd   # Entity spawning
│  ├─ EnemyTemplateManager.gd    # Enemy templates
│  ├─ BossTemplateManager.gd     # Boss templates
│  ├─ StageTemplateManager.gd   # Stage templates
│  ├─ GameModeManager.gd        # Game mode management
│  └─ ConfigManager.gd          # Configuration management
├─ systems/               # Game Systems
│  ├─ CombatSystem.gd    # Combat logic
│  ├─ VisualEffectsSystem.gd    # Visual effects
│  └─ RankPressureSystem.gd     # Rank pressure
├─ controllers/           # Input Handlers
│  └─ PlayerController.gd       # Player input
├─ components/           # Reusable Behaviors
│  └─ behaviors/
│     ├─ MovementBehavior.gd    # Base movement
│     ├─ AttackBehavior.gd      # Base attack
│     ├─ StraightDownBehavior.gd
│     ├─ SineWaveBehavior.gd
│     ├─ ZigzagBehavior.gd
│     ├─ DiveBehavior.gd
│     ├─ AimedShotBehavior.gd
│     ├─ FanBehavior.gd
│     └─ RingBehavior.gd
├─ stages/               # Stage Definitions
│  ├─ StageDefinition.gd # Stage data
│  ├─ WaveDefinition.gd  # Wave data
│  └─ BossEncounter.gd   # Boss encounter data
├─ data/                 # Templates and Definitions
│  ├─ EnemyTemplate.gd   # Enemy template
│  ├─ BossTemplate.gd    # Boss template
│  └─ BossPhase.gd       # Boss phase data
└─ [Game Modes]          # Game Mode Classes
   ├─ GameMode.gd        # Base game mode
   ├─ CampaignMode.gd    # Campaign mode
   ├─ EndlessMode.gd     # Endless mode
   ├─ BossRushMode.gd    # Boss rush mode
   └─ PracticeMode.gd    # Practice mode
```

*Thanks for reading! :)*

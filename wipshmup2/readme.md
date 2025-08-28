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
│  │  │  │ (Player.gd)  │  │  │  │  TPS Counter  │  │  │  │   Shader      │  │       │   │
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
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐   │
│  │  AudioManager   │  │  RankManager    │  │ DifficultyConfig│  │  TickManager    │   │
│  │   (Audio.gd)    │  │  (Rank.gd)      │  │   (Config.gd)   │  │  (Tick.gd)      │   │
│  │                 │  │                 │  │                 │  │                 │   │
│  │ ┌─────────────┐ │  │ ┌─────────────┐ │  │ ┌─────────────┐ │  │ ┌─────────────┐ │   │
│  │ │Procedural   │ │  │ │Dynamic      │ │  │ │Configurable │ │  │ │Performance  │ │   │
│  │ │Sound Effects│ │  │ │Difficulty   │ │  │ │Parameters   │ │  │ │Timing       │ │   │
│  │ │Generation   │ │  │ │Scaling      │ │  │ │for Game     │ │  │ │System       │ │   │
│  │ │             │ │  │ │             │ │  │ │Balance      │ │  │ │             │ │   │
│  │ │• Beeps      │ │  │ │• Speed      │ │  │ │             │ │  │ │• Time       │ │   │
│  │ │• Boops      │ │  │ │• HP         │ │  │ │• Min/Max    │ │  │ │• Delta      │ │   │
│  │ │• Explosions │ │  │ │• Bullet     │ │  │ │  Rank       │ │  │ │• Caching    │ │   │
│  │ │• Extends    │ │  │ │  Speed      │ │  │ │• Multiplier │ │  │ │             │ │   │
│  │ └─────────────┘ │  │ │• Pattern    │ │  │ │  Caps       │ │  │ └─────────────┘ │   │
│  └─────────────────┘  │ │  Density    │ │  │ └─────────────┘ │  └─────────────────┘   │
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

    TickManager.tick ────────────────► HUD._on_tick()
                                              │
                                              ▼
                                        TPS Display
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

*Thanks for reading! :)*
# CC & Displacement System Guide

## Status Effect Types

### Hard CC (full agency removal)
| Effect | Icon | Duration | Breaks On | Notes |
|--------|------|----------|-----------|-------|
| Stun | flash_off | Timed | — | Cannot act |
| Freeze | ac_unit | Timed | — | Cannot act or move |
| Sleep | bedtime | 4-8s | Any damage | Target regens HP; caster gains mana regen bonus |
| Charm | favorite_border | 2-4s | Expiry/cleanse | Forced walk toward caster; "heartbreak" slows nearby allies |
| Polymorph | pets | 5-6s | Any damage | Critter form, movement only; spirit trail on minimap |
| Suppress | lock | 2.5-3.5s | Caster takes damage | Mutual lockdown on caster AND target; uncleansable |
| Banish | remove_circle | 2.5-3s | Expiry only | Phased out: invulnerable + untargetable; cooldowns tick 3x |
| Airborne | flight | Physics-based | Landing | Launched upward; juggle follow-ups extend air time |
| Fear | warning | 3s | — | Forced fleeing |
| Knockdown | accessibility | 1-2s | — | Stun + interrupt composite |

### Soft CC (restricted agency)
| Effect | Icon | Duration | Notes |
|--------|------|----------|-------|
| Daze | blur_on | 3-4s | 50% slow + damage interrupts casts + resets melee combo |
| Disorient | explore_off | 4s | WASD remapped randomly every 1.5s; camera sway; ability input delayed |
| Grounded | downloading | 4-6s | Blocks dashes/flight/teleports; +20% nature damage taken |
| Nearsight | visibility_off | 5s | Minimap dark; nameplates hidden; CC overlay suppressed |
| Slow | speed | Varies | Reduced movement speed |
| Root | park | 2-4s | Cannot move but can act |
| Silence | volume_off | 2s | Cannot use abilities |
| Taunt | record_voice_over | 4s | Forced basic-attack on taunter; damage to taunter reduced 25% |

### Displacement (instant positional)
| Effect | Notes |
|--------|-------|
| Knockback | Push in caster's facing direction; wall slam = bonus damage + 1s stun |
| Grip | Pull toward caster (fraction of distance) |
| Scatter | AoE knockback from center point; strength falls off with distance |
| Gravity Well | Persistent pull toward anchor; bends nearby projectiles |

## Diminishing Returns

CC effects are grouped into DR categories. Within an 18s window, successive CC of the same category has reduced duration:

| Application | Duration Multiplier |
|-------------|-------------------|
| 1st | 100% |
| 2nd | 50% |
| 3rd | 25% |
| 4th+ | Immune (0%) |

**DR Categories:**
- **Stun**: stun, knockdown, airborne
- **Incapacitate**: sleep, polymorph, banish, charm
- **Root**: root, grounded
- **Silence**: silence, suppress
- **Disorient**: fear, disorient, daze

Counter resets after 18s with no new application of that category.

## Airborne Physics

- Launch velocity: `v = sqrt(2 * gravity * height)` where height = ability strength
- Gravity: 12.0 units/s^2 (reduced slightly during strong wind)
- Fall damage: `(peakHeight - 4.0) * 5.0` damage on landing (only if peak > 4.0)
- Juggle window: 0.5s after landing where relaunches get +30% height
- Already-airborne targets: velocity is ADDED (not replaced) for combo extension

## Terrain-Enhanced Knockback

When knockback displaces a unit along terrain:
- **Wall slam** (terrain rise > 2.0 units): Stop displacement, deal `force * 0.5` bonus damage, apply 1s stun
- **Cliff launch** (terrain drop > 3.0 units): Convert to airborne state with horizontal momentum

## Gravity Well

- Pulls all units within radius toward anchor point
- Pull strength falls off linearly with distance from center
- Units can walk away but at reduced speed
- Wells expire after their duration; registered via `GravityWellSystem.add()`

## Stance-CC Interactions

Each stance modifies how CC is applied and received. All values are in `cc_config.json` under `stanceInteractions`.

| Stance | Offensive | Defensive | Drawback |
|--------|-----------|-----------|----------|
| Cadence | On-beat CC gets +25% duration | Being hard-CC'd resets Groove to 0 | — |
| Tempest | CC outside cancel chain: -15% duration | Incoming hard CC: -20% duration | — |
| Warden | Predator's Eye CC: +40% duration | Strafe gives 15% soft CC resist chance | Grounded disables directional bonuses |
| Crucible | CC costs 2 Heat; 0-Heat CC: +50% duration | CC pauses Heat decay | Trapped at high Heat while CC'd |
| Momentum | Displacement force +5%/stack; max-stack juggle +0.5s | CC causes 3x stack decay | — |
| Pressure | CC builds +50% bonus pressure; Break ignores DR | CC causes 3x pressure decay | Displacement resets pressure to 50% |
| Flux | Transition window CC: +30% duration | Stance switch cleanses one soft CC | Stagnation: +25% incoming CC duration |

## Config Files

- `assets/data/cc_config.json` — All CC tuning values
- `lib/game3d/state/cc_config.dart` — Dart config class with dot-notation getters
- `lib/game3d/systems/cc_diminishing_returns.dart` — DR tracking
- `lib/game3d/systems/cc_behavior_system.dart` — Per-frame CC behaviors
- `lib/game3d/systems/airborne_system.dart` — Airborne physics
- `lib/game3d/systems/gravity_well_system.dart` — Gravity well management

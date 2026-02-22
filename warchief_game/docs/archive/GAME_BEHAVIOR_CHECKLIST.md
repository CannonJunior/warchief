# Warchief Game - Behavior Checklist

This checklist documents the current game behavior to verify no regressions during refactoring.

**Date Created**: 2025-11-01
**Branch**: refactor/modular-architecture
**Purpose**: Ensure all functionality works before and after each refactoring phase

---

## How to Use This Checklist

1. ✅ Test all items BEFORE starting a refactoring phase
2. ✅ Test all items AFTER completing a refactoring phase
3. ❌ If any item fails, stop and fix before proceeding
4. 📝 Add notes for any unexpected behavior

---

## Core Game Loop

- [ ] Game loads without errors
- [ ] Game renders at stable framerate (check console for FPS)
- [ ] Canvas displays correctly in browser
- [ ] Game loop continues running (frameCount incrementing)

---

## Player Controls

### Movement
- [ ] W key: Player moves forward
- [ ] S key: Player moves backward
- [ ] A key: Player rotates left
- [ ] D key: Player rotates right
- [ ] Q key: Player strafes left
- [ ] E key: Player strafes right
- [ ] Player stops when keys released
- [ ] Player can't move through terrain boundaries

### Jumping
- [ ] Spacebar: Player jumps
- [ ] Double jump works (press space twice)
- [ ] Gravity pulls player back down
- [ ] Player lands correctly on ground
- [ ] Jump height is consistent

### Camera
- [ ] J key: Camera rotates left
- [ ] L key: Camera rotates right
- [ ] I key: Camera moves up
- [ ] K key: Camera moves down
- [ ] N key: Camera zooms in
- [ ] M key: Camera zooms out
- [ ] Camera follows player smoothly

---

## Player Abilities

### Ability 1: Sword (Melee)
- [ ] 1 key activates sword attack
- [ ] Sword appears in front of player
- [ ] Sword disappears after 0.3 seconds
- [ ] Sword damages monster when in range (2.0 units)
- [ ] Sword damages player when in range
- [ ] Sword damages allies when in range
- [ ] Cooldown prevents spam (visible on ability button)
- [ ] Impact effect appears on hit

### Ability 2: Fireball (Ranged)
- [ ] 2 key launches fireball
- [ ] Fireball travels in correct direction
- [ ] Fireball damages monster on collision
- [ ] Fireball disappears after hit or timeout
- [ ] Cooldown works correctly (3 seconds)
- [ ] Impact effect appears on collision

### Ability 3: Heal
- [ ] 3 key activates heal
- [ ] Green heal effect appears on player
- [ ] Player health increases by 20
- [ ] Cooldown works correctly (10 seconds)
- [ ] Heal effect disappears after animation

---

## Monster AI

### Basic AI
- [ ] Monster spawns at correct position (18, 0.6, 18)
- [ ] Monster makes decisions every 2 seconds
- [ ] Monster moves toward player when far away
- [ ] Monster uses abilities when in range
- [ ] Monster direction indicator (green triangle) visible

### Monster Abilities
- [ ] Dark Strike (melee) damages player when close
- [ ] Shadow Bolt (projectile) launches and travels
- [ ] Shadow Bolt damages player on hit
- [ ] Dark Healing restores monster health (+25 HP)
- [ ] All abilities respect cooldowns

### Monster Death
- [ ] Monster health decreases when hit
- [ ] Monster doesn't move when health = 0
- [ ] Monster doesn't use abilities when dead

---

## Ally System

### Ally Management
- [ ] "+ Ally" button creates new ally
- [ ] Allies spawn near player position
- [ ] Allies have random ability assignment (sword/fireball/heal)
- [ ] "- Ally" button removes last ally
- [ ] Ally count displays correctly
- [ ] Maximum of N allies supported without crash

### Ally AI
- [ ] Allies make decisions every 3 seconds
- [ ] Allies move toward player when far
- [ ] Allies move toward monster to attack
- [ ] Allies retreat when low health
- [ ] Allies use abilities automatically
- [ ] No direction triangle on allies (removed in recent update)

### Ally Abilities
- [ ] Ally with sword attacks monster in melee range
- [ ] Ally with fireball shoots projectiles
- [ ] Ally with heal restores own health
- [ ] Ally ability cooldowns work correctly
- [ ] Manual ability activation via UI button works
- [ ] Cooldown clock animation appears on ally ability buttons

### Ally Health
- [ ] Ally health decreases when damaged
- [ ] Ally health bar displays correctly
- [ ] Ally dies when health reaches 0
- [ ] Dead allies don't move or use abilities

---

## Projectile System

### Player Fireballs
- [ ] Fireballs spawn at player position
- [ ] Fireballs travel at correct speed
- [ ] Fireballs check collision with monster
- [ ] Fireballs disappear after hit
- [ ] Fireballs disappear after 5 second timeout

### Monster Projectiles
- [ ] Shadow Bolts spawn at monster position
- [ ] Shadow Bolts target player
- [ ] Shadow Bolts damage player on collision
- [ ] Shadow Bolts disappear correctly

### Ally Projectiles
- [ ] Ally fireballs spawn correctly
- [ ] Ally fireballs target monster
- [ ] Ally fireballs damage on hit
- [ ] Multiple allies can have projectiles simultaneously

---

## Visual Effects

### Impact Effects
- [ ] Impact effects appear on all hits (player, monster, ally)
- [ ] Impact effects have correct color
- [ ] Impact effects fade out over 0.3 seconds
- [ ] Impact effects don't cause performance issues

### Heal Effects
- [ ] Green heal sphere appears on heal activation
- [ ] Heal effect positioned correctly above character
- [ ] Heal effect disappears after animation

---

## UI Elements

### Info Display (Top Right)
- [ ] Game version displays correctly
- [ ] WebGL Renderer label visible
- [ ] Settings button visible (even if not functional)

### Ally Management Panel
- [ ] Panel displays ally count
- [ ] "+ Ally" button enabled
- [ ] "- Ally" button disabled when no allies
- [ ] Panel positioned correctly

### Ally Status Display
- [ ] Each ally has a status card
- [ ] Ally health bar updates correctly
- [ ] Ally ability icon shows correct type
- [ ] Ally ability button shows cooldown
- [ ] Cooldown clock animation works

### Player Ability Bar
- [ ] Three ability buttons visible
- [ ] Ability icons/labels correct
- [ ] Cooldown visualization works
- [ ] Buttons disabled during cooldown

---

## Rendering

### Terrain
- [ ] 20x20 terrain grid renders
- [ ] Terrain tiles have correct color
- [ ] Terrain is flat and level
- [ ] No visual artifacts or z-fighting

### Characters
- [ ] Player mesh renders (blue cube)
- [ ] Monster mesh renders (purple cube)
- [ ] Ally meshes render (brighter blue cubes)
- [ ] All meshes have correct size/scale
- [ ] Player direction indicator (red triangle) visible
- [ ] Monster direction indicator (green triangle) visible

### Shadows
- [ ] Player shadow renders under player
- [ ] Shadow follows player position
- [ ] Shadow color is dark gray/black

---

## Performance

- [ ] Game runs at 60 FPS on modern browser
- [ ] No memory leaks (check browser dev tools)
- [ ] No console errors during normal gameplay
- [ ] Canvas resizes correctly with window
- [ ] Game continues running after 5+ minutes

---

## Error Handling

- [ ] Game handles Ollama being unavailable (falls back to rule-based AI)
- [ ] Game handles invalid input gracefully
- [ ] No crashes during extended play session
- [ ] WebGL context loss handled correctly (if applicable)

---

## Notes Section

Add any observations here:

```
[Date] [Phase] [Observation]
Example:
2025-11-01 Phase0 Baseline: All features working as expected
```

---

## Test Instructions

1. Open browser to http://localhost:8008
2. Open browser console (F12) to check for errors
3. Test each item systematically
4. Mark items with ✅ or ❌
5. Document any failures in Notes section
6. Do not proceed to next phase if critical items fail

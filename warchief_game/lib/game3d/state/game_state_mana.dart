part of 'game_state.dart';

extension GameStateManaExt on GameState {
  /// Regenerate mana based on current position
  void updateManaRegen(double dt) {
    if (leyLineManager == null || playerTransform == null) return;

    final pos = playerTransform!.position;
    currentManaRegenRate = leyLineManager!.calculateManaRegen(pos.x, pos.z);
    currentLeyLineInfo = leyLineManager!.getLeyLineInfo(pos.x, pos.z);

    // Check if on a power node
    isOnPowerNode = leyLineManager!.isOnPowerNode(pos.x, pos.z);

    final playerAttunements = playerManaAttunements;

    // Stance mana regen modifier and Blood Weave conversion
    final stanceManaRegenMult = activeStance.manaRegenMultiplier;
    final stanceConvertsToHeal = activeStance.convertsManaRegenToHeal;

    // Apply blue mana regeneration (Ley Lines + equipped item bonus)
    if (playerAttunements.contains(ManaColor.blue)) {
      final blueRegenBonus = playerInventory.totalEquippedStats.blueManaRegen;
      final effectiveBlueRegen = (currentManaRegenRate + blueRegenBonus) * stanceManaRegenMult;
      if (effectiveBlueRegen > 0) {
        if (stanceConvertsToHeal) {
          // Blood Weave: mana regen heals HP instead
          playerHealth = (playerHealth + effectiveBlueRegen * dt).clamp(0.0, playerMaxHealth);
        } else {
          blueMana = (blueMana + effectiveBlueRegen * dt).clamp(0.0, maxBlueMana);
        }
      }
    }

    // Apply red mana regeneration (power nodes + equipped item bonus)
    if (playerAttunements.contains(ManaColor.red)) {
      final redRegenBonus = playerInventory.totalEquippedStats.redManaRegen;
      if (isOnPowerNode) {
        currentRedManaRegenRate = (currentManaRegenRate + redRegenBonus) * stanceManaRegenMult;
        if (stanceConvertsToHeal) {
          playerHealth = (playerHealth + currentRedManaRegenRate * dt).clamp(0.0, playerMaxHealth);
        } else {
          redMana = (redMana + currentRedManaRegenRate * dt).clamp(0.0, maxRedMana);
        }
        _timeSinceLastRedManaChange = 0.0; // Power nodes pause decay
      } else {
        currentRedManaRegenRate = redRegenBonus.toDouble() * stanceManaRegenMult;

        // Apply item-based red regen even off power nodes
        if (redRegenBonus > 0) {
          final effectiveRedRegen = redRegenBonus * stanceManaRegenMult;
          if (stanceConvertsToHeal) {
            playerHealth = (playerHealth + effectiveRedRegen * dt).clamp(0.0, playerMaxHealth);
          } else {
            redMana = (redMana + effectiveRedRegen * dt).clamp(0.0, maxRedMana);
          }
          _timeSinceLastRedManaChange = 0.0;
        }

        // Red mana decay (after grace period, when not on power node and no item regen)
        if (redMana > 0 && redRegenBonus <= 0) {
          _timeSinceLastRedManaChange += dt;
          final decayDelay = globalManaConfig?.redManaDecayDelay ?? 5.0;
          if (_timeSinceLastRedManaChange >= decayDelay) {
            final decayRate = globalManaConfig?.redManaDecayRate ?? 3.0;
            redMana = (redMana - decayRate * dt).clamp(0.0, maxRedMana);
          }
        }
      }
    } else {
      currentRedManaRegenRate = 0.0;
    }

    // ===== ALLY MANA REGEN =====
    for (final ally in allies) {
      if (ally.health <= 0) continue;

      final allyPos = ally.transform.position;
      final allyBlueRegen = leyLineManager!.calculateManaRegen(allyPos.x, allyPos.z);
      final allyOnPowerNode = leyLineManager!.isOnPowerNode(allyPos.x, allyPos.z);
      final allyAttunements = (globalGameplaySettings?.attunementRequired ?? true)
          ? ally.combinedManaAttunements
          : GameState._allManaColors;
      final allyItemBlueBonus = ally.inventory.totalEquippedStats.blueManaRegen;
      final allyItemRedBonus = ally.inventory.totalEquippedStats.redManaRegen;

      // Ally blue mana regen (ley lines + item bonus) — only if blue-attuned
      if (allyAttunements.contains(ManaColor.blue)) {
        final effectiveAllyBlueRegen = allyBlueRegen + allyItemBlueBonus;
        if (effectiveAllyBlueRegen > 0) {
          ally.blueMana = (ally.blueMana + effectiveAllyBlueRegen * dt)
              .clamp(0.0, ally.maxBlueMana);
        }
      }

      // Ally red mana regen (power nodes + item bonus) — only if red-attuned
      if (allyAttunements.contains(ManaColor.red)) {
        if (allyOnPowerNode) {
          final allyRedRegen = allyBlueRegen + allyItemRedBonus;
          ally.redMana = (ally.redMana + allyRedRegen * dt)
              .clamp(0.0, ally.maxRedMana);
        } else if (allyItemRedBonus > 0) {
          ally.redMana = (ally.redMana + allyItemRedBonus * dt)
              .clamp(0.0, ally.maxRedMana);
        }
      }
    }
  }

  /// Update wind simulation and White Mana regeneration/decay.
  ///
  /// Wind exposure drives White Mana regen. When wind drops below
  /// shelterThreshold, White Mana actively decays — unlike blue mana
  /// which simply stops regenerating.
  void updateWindAndWhiteMana(double dt) {
    _windState.update(dt);

    // Also update globalWindState for other systems (movement, projectiles)
    globalWindState = _windState;

    final config = globalWindConfig;
    final exposure = _windState.exposureLevel;
    final shelterThresh = config?.shelterThreshold ?? 0.1;

    final whiteRegenBonus = playerInventory.totalEquippedStats.whiteManaRegen;

    // Wind Affinity regen multiplier (2x when active)
    final windAffinityMult = windAffinityActive ? 2.0 : 1.0;

    // Reason: derecho storms multiply white mana regen for massive gains
    final derechoManaMult = _windState.derechoManaMultiplier;

    // Stance modifiers for white mana regen
    final whiteStanceMult = activeStance.manaRegenMultiplier;
    final whiteStanceConverts = activeStance.convertsManaRegenToHeal;

    if (playerManaAttunements.contains(ManaColor.white)) {
      if (exposure >= shelterThresh) {
        // Wind is blowing — regenerate white mana (wind + item bonus)
        final regenRate = ((config?.windExposureRegen ?? 5.0) *
            exposure *
            (config?.windStrengthMultiplier ?? 1.0) +
            whiteRegenBonus) * windAffinityMult * derechoManaMult * whiteStanceMult;
        currentWhiteManaRegenRate = regenRate;
        if (whiteStanceConverts) {
          playerHealth = (playerHealth + regenRate * dt).clamp(0.0, playerMaxHealth);
        } else {
          whiteMana = (whiteMana + regenRate * dt).clamp(0.0, maxWhiteMana);
        }
      } else {
        // Sheltered — item regen still applies, but wind decay counteracts
        currentWhiteManaRegenRate = whiteRegenBonus.toDouble() * windAffinityMult * whiteStanceMult;
        if (whiteRegenBonus > 0) {
          final effectiveWhiteRegen = whiteRegenBonus * windAffinityMult * whiteStanceMult;
          if (whiteStanceConverts) {
            playerHealth = (playerHealth + effectiveWhiteRegen * dt).clamp(0.0, playerMaxHealth);
          } else {
            whiteMana = (whiteMana + effectiveWhiteRegen * dt).clamp(0.0, maxWhiteMana);
          }
        }
        if (whiteMana > 0 && whiteRegenBonus <= 0) {
          final decay = config?.decayRate ?? 0.5;
          whiteMana = (whiteMana - decay * dt).clamp(0.0, maxWhiteMana);
        }
      }
    } else {
      currentWhiteManaRegenRate = 0.0;
    }

    // ===== ALLY WHITE MANA REGEN =====
    // Allies share the global wind exposure level
    for (final ally in allies) {
      if (ally.health <= 0) continue;
      final allyAttunements = (globalGameplaySettings?.attunementRequired ?? true)
          ? ally.combinedManaAttunements
          : GameState._allManaColors;

      if (allyAttunements.contains(ManaColor.white)) {
        final allyWhiteRegenBonus = ally.inventory.totalEquippedStats.whiteManaRegen;

        if (exposure >= shelterThresh) {
          // Wind is blowing — ally regenerates white mana
          final allyRegenRate = (config?.windExposureRegen ?? 5.0) *
              exposure *
              (config?.windStrengthMultiplier ?? 1.0) +
              allyWhiteRegenBonus;
          ally.whiteMana = (ally.whiteMana + allyRegenRate * dt)
              .clamp(0.0, ally.maxWhiteMana);
        } else {
          // Sheltered — item regen still applies
          if (allyWhiteRegenBonus > 0) {
            ally.whiteMana = (ally.whiteMana + allyWhiteRegenBonus * dt)
                .clamp(0.0, ally.maxWhiteMana);
          }
          // Ally white mana decay when sheltered
          if (ally.whiteMana > 0 && allyWhiteRegenBonus <= 0) {
            final decay = config?.decayRate ?? 0.5;
            ally.whiteMana = (ally.whiteMana - decay * dt)
                .clamp(0.0, ally.maxWhiteMana);
          }
        }
      }
    }

    // Flight mana drain
    if (isFlying) {
      final drainRate = config?.flightManaDrainRate ?? 3.0;
      whiteMana = (whiteMana - drainRate * dt).clamp(0.0, maxWhiteMana);

      // Low mana descent — slowly lose altitude when mana is low
      final lowThreshold = config?.lowManaThreshold ?? 33.0;
      final minAlt = config?.minAltitudeForDescent ?? 10.0;
      if (whiteMana < lowThreshold && flightAltitude >= minAlt) {
        final descentRate = config?.lowManaDescentRate ?? 2.0;
        if (playerTransform != null) {
          playerTransform!.position.y -= descentRate * dt;
        }
      }

      // Zero mana — forced landing
      if (whiteMana <= 0) {
        endFlight();
      }
    }

    // Sovereign of the Sky buff timer
    if (sovereignBuffActive) {
      sovereignBuffTimer -= dt;
      if (sovereignBuffTimer <= 0) {
        sovereignBuffActive = false;
        sovereignBuffTimer = 0.0;
        print('[FLIGHT] Sovereign of the Sky buff expired');
      }
    }

    // Wind Affinity buff timer
    if (windAffinityActive) {
      windAffinityTimer -= dt;
      if (windAffinityTimer <= 0) {
        windAffinityActive = false;
        windAffinityTimer = 0.0;
        print('[WIND] Wind Affinity buff expired');
      }
    }

    // Wind Warp speed buff timer
    if (windWarpSpeedActive) {
      windWarpSpeedTimer -= dt;
      if (windWarpSpeedTimer <= 0) {
        windWarpSpeedActive = false;
        windWarpSpeedTimer = 0.0;
        print('[WIND] Wind Warp speed buff expired');
      }
    }
  }

  /// Update green mana regeneration based on proximity to nature sources.
  ///
  /// Green mana regenerates from three sources:
  /// 1. Standing on grass (terrain weight)
  /// 2. Proximity to other green-attuned characters (within proximityRadius)
  /// 3. Proximity to spirit beings (within spiritBeingRadius, does NOT regen self)
  void updateGreenManaRegen(double dt) {
    final config = globalManaConfig;
    if (config == null) return;

    final grassBaseRegen = config.grassBaseRegen;
    final proximityRegenPerUser = config.proximityRegenPerUser;
    final proximityRadius = config.proximityRadius;
    final spiritBeingRegenBonus = config.spiritBeingRegenBonus;
    final spiritBeingRadius = config.spiritBeingRadius;
    final decayRate = config.greenManaDecayRate;
    final decayDelay = config.greenManaDecayDelay;
    final greenRegenBonus = playerInventory.totalEquippedStats.greenManaRegen;

    final playerAttunements = playerManaAttunements;
    final hasGreen = playerAttunements.contains(ManaColor.green);

    // === WARCHIEF GREEN MANA ===
    if (hasGreen && playerTransform != null) {
      final px = playerTransform!.position.x;
      final pz = playerTransform!.position.z;

      // 1. Grass-based regen: use terrain grass weight
      double grassWeight = 0.0;
      if (infiniteTerrainManager != null && terrainHeightmap != null) {
        // Reason: Approximate grass weight from terrain height/slope without SplatMapGenerator dependency
        final height = infiniteTerrainManager!.getTerrainHeight(px, pz);
        // Grass grows at mid-heights (roughly 0.2-0.6 of terrain range)
        final normalizedHeight = ((height + 10.0) / 40.0).clamp(0.0, 1.0);
        grassWeight = (normalizedHeight > 0.15 && normalizedHeight < 0.65) ? 1.0 - ((normalizedHeight - 0.4).abs() * 3.0).clamp(0.0, 1.0) : 0.0;
      }
      final grassRegen = grassBaseRegen * grassWeight;

      // 2. Proximity regen: count green-attuned characters within range
      int proximityCount = 0;
      final proximityRadiusSq = proximityRadius * proximityRadius;
      for (final ally in allies) {
        if (ally.health <= 0) continue;
        final allyAttunements = (globalGameplaySettings?.attunementRequired ?? true)
            ? ally.combinedManaAttunements
            : GameState._allManaColors;
        if (!allyAttunements.contains(ManaColor.green)) continue;
        final dx = ally.transform.position.x - px;
        final dz = ally.transform.position.z - pz;
        if (dx * dx + dz * dz <= proximityRadiusSq) proximityCount++;
      }
      final proximityRegen = proximityCount * proximityRegenPerUser;

      // 3. Spirit being regen: count spirit beings nearby (not self)
      int spiritCount = 0;
      final spiritBeingRadiusSq = spiritBeingRadius * spiritBeingRadius;
      for (final ally in allies) {
        if (ally.health <= 0 || !ally.inSpiritForm) continue;
        final dx = ally.transform.position.x - px;
        final dz = ally.transform.position.z - pz;
        if (dx * dx + dz * dz <= spiritBeingRadiusSq) spiritCount++;
      }
      final spiritRegen = spiritCount * spiritBeingRegenBonus;

      final totalRegen = (grassRegen + proximityRegen + spiritRegen + greenRegenBonus) * activeStance.manaRegenMultiplier;
      currentGreenManaRegenRate = totalRegen;

      if (totalRegen > 0) {
        if (activeStance.convertsManaRegenToHeal) {
          playerHealth = (playerHealth + totalRegen * dt).clamp(0.0, playerMaxHealth);
        } else {
          greenMana = (greenMana + totalRegen * dt).clamp(0.0, maxGreenMana);
        }
        _timeSinceLastGreenManaSource = 0.0;
      } else {
        // Decay when no regen sources
        _timeSinceLastGreenManaSource += dt;
        if (_timeSinceLastGreenManaSource >= decayDelay && greenMana > 0) {
          greenMana = (greenMana - decayRate * dt).clamp(0.0, maxGreenMana);
        }
      }
    } else {
      currentGreenManaRegenRate = 0.0;
    }

    // === ALLY GREEN MANA ===
    for (final ally in allies) {
      if (ally.health <= 0) continue;
      final allyAttunements = (globalGameplaySettings?.attunementRequired ?? true)
          ? ally.combinedManaAttunements
          : GameState._allManaColors;
      if (!allyAttunements.contains(ManaColor.green)) continue;

      final ax = ally.transform.position.x;
      final az = ally.transform.position.z;
      final allyGreenRegenBonus = ally.inventory.totalEquippedStats.greenManaRegen;

      // Grass regen for ally
      double allyGrassWeight = 0.0;
      if (infiniteTerrainManager != null) {
        final h = infiniteTerrainManager!.getTerrainHeight(ax, az);
        final nh = ((h + 10.0) / 40.0).clamp(0.0, 1.0);
        allyGrassWeight = (nh > 0.15 && nh < 0.65) ? 1.0 - ((nh - 0.4).abs() * 3.0).clamp(0.0, 1.0) : 0.0;
      }
      final allyGrassRegen = grassBaseRegen * allyGrassWeight;

      // Proximity regen from other green characters
      int allyProxCount = 0;
      final proxRadSq = proximityRadius * proximityRadius;

      // Check warchief
      if (hasGreen && playerTransform != null) {
        final dx = playerTransform!.position.x - ax;
        final dz = playerTransform!.position.z - az;
        if (dx * dx + dz * dz <= proxRadSq) allyProxCount++;
      }
      // Check other allies
      for (final otherAlly in allies) {
        if (otherAlly == ally || otherAlly.health <= 0) continue;
        final otherAttunements = (globalGameplaySettings?.attunementRequired ?? true)
            ? otherAlly.combinedManaAttunements
            : GameState._allManaColors;
        if (!otherAttunements.contains(ManaColor.green)) continue;
        final dx = otherAlly.transform.position.x - ax;
        final dz = otherAlly.transform.position.z - az;
        if (dx * dx + dz * dz <= proxRadSq) allyProxCount++;
      }
      final allyProxRegen = allyProxCount * proximityRegenPerUser;

      // Spirit being regen (not self)
      int allySpiritCount = 0;
      final spiritRadSq = spiritBeingRadius * spiritBeingRadius;
      if (playerInSpiritForm && playerTransform != null) {
        final dx = playerTransform!.position.x - ax;
        final dz = playerTransform!.position.z - az;
        if (dx * dx + dz * dz <= spiritRadSq) allySpiritCount++;
      }
      for (final otherAlly in allies) {
        if (otherAlly == ally || otherAlly.health <= 0 || !otherAlly.inSpiritForm) continue;
        final dx = otherAlly.transform.position.x - ax;
        final dz = otherAlly.transform.position.z - az;
        if (dx * dx + dz * dz <= spiritRadSq) allySpiritCount++;
      }
      final allySpiritRegen = allySpiritCount * spiritBeingRegenBonus;

      final allyTotalRegen = allyGrassRegen + allyProxRegen + allySpiritRegen + allyGreenRegenBonus;
      if (allyTotalRegen > 0) {
        ally.greenMana = (ally.greenMana + allyTotalRegen * dt).clamp(0.0, ally.maxGreenMana);
      } else if (ally.greenMana > 0) {
        ally.greenMana = (ally.greenMana - decayRate * dt).clamp(0.0, ally.maxGreenMana);
      }
    }
  }

  /// Update black mana regeneration (comet-driven: ambient + surge + crater proximity).
  ///
  /// Three regen layers:
  ///   1. Ambient — always active (0.5/s by default)
  ///   2. Comet surge — scales with cometIntensity, up to 15/s at perihelion
  ///   3. Impact craters — bonus while standing within radius of a fresh crater
  ///
  /// When regen rate drops near zero, black mana decays slowly (like red mana).
  void updateBlackManaRegen(double dt, double playerX, double playerZ) {
    final cometState = globalCometState;
    final cometConfig = globalCometConfig;

    final playerAttunements = playerManaAttunements;

    // ── Player black mana ───────────────────────────────────────────────────
    if (playerAttunements.contains(ManaColor.black)) {
      final regenRate = cometState?.computeBlackManaRegen(playerX, playerZ)
          ?? (cometConfig?.ambientRegenRate ?? 0.5);
      currentBlackManaRegenRate = regenRate;

      if (regenRate > 0) {
        blackMana = math.min(maxBlackMana, blackMana + regenRate * dt);
      } else if (blackMana > 0) {
        // Reason: decay when comet is not influencing the area (between flybys)
        final decayRate = cometConfig?.blackManaDecayRate ?? 1.0;
        blackMana = math.max(0.0, blackMana - decayRate * dt);
      }
    } else {
      currentBlackManaRegenRate = 0.0;
    }

    // ── Ally black mana ─────────────────────────────────────────────────────
    for (final ally in allies) {
      if (ally.health <= 0) continue;
      final allyAttunements = (globalGameplaySettings?.attunementRequired ?? true)
          ? ally.combinedManaAttunements
          : GameState._allManaColors;
      if (!allyAttunements.contains(ManaColor.black)) continue;

      final ax = ally.transform.position.x;
      final az = ally.transform.position.z;
      final allyRegen = cometState?.computeBlackManaRegen(ax, az)
          ?? (cometConfig?.ambientRegenRate ?? 0.5);

      if (allyRegen > 0) {
        ally.blackMana = math.min(ally.maxBlackMana, ally.blackMana + allyRegen * dt);
      } else if (ally.blackMana > 0) {
        final decayRate = cometConfig?.blackManaDecayRate ?? 1.0;
        ally.blackMana = math.max(0.0, ally.blackMana - decayRate * dt);
      }
    }
  }
}

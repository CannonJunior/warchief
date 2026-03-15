// ignore_for_file: invalid_use_of_protected_member
part of 'duel_panel.dart';

// ── Top-level constants used only by the setup tab ────────────────────────────

const _setupGearColors = [
  Color(0xFF9E9E9E), // 0 Common     – grey
  Color(0xFF4CAF50), // 1 Uncommon   – green
  Color(0xFF2196F3), // 2 Rare       – blue
  Color(0xFF9C27B0), // 3 Epic       – purple
  Color(0xFFFF8C00), // 4 Legendary  – orange/gold
];

const _setupGearNames = ['Common', 'Uncommon', 'Rare', 'Epic', 'Legendary'];

// ==================== SETUP TAB ====================

extension _DuelPanelSetup on _DuelPanelState {
  // ── Root method (called from main file's _buildTabContent) ─────────────────

  Widget _buildSetupTab() {
    final canStart =
        _chalClasses.sublist(0, _chalPartySize).every((c) => c != null) &&
        _enemyTypes.sublist(0, _enemyPartySize).every((e) => e != null) &&
        widget.manager.phase != DuelPhase.active;

    // Sync seed fields whenever layout rebuilds.
    final chalSeed = _computeSeed(isChallenger: true);
    final enemSeed = _computeSeed(isChallenger: false);
    if (_chalSeedCtrl.text != chalSeed)  _chalSeedCtrl.text = chalSeed;
    if (_enemySeedCtrl.text != enemSeed) _enemySeedCtrl.text = enemSeed;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Side headers ──────────────────────────────────────────────────
          Row(children: [
            Expanded(child: _sideHeader('BLUE SIDE', Colors.blueAccent)),
            const SizedBox(width: 10),
            Expanded(child: _sideHeader('RED SIDE', const Color(0xFFef5350))),
          ]),
          const SizedBox(height: 8),

          // ── Party size ────────────────────────────────────────────────────
          Row(children: [
            Expanded(child: _partySizeRow(true)),
            const SizedBox(width: 10),
            Expanded(child: _partySizeRow(false)),
          ]),
          const SizedBox(height: 6),

          // ── Randomize + seed ──────────────────────────────────────────────
          Row(children: [
            Expanded(child: _randomizeRow(true)),
            const SizedBox(width: 10),
            Expanded(child: _randomizeRow(false)),
          ]),
          const SizedBox(height: 6),

          // ── Strategy ──────────────────────────────────────────────────────
          Row(children: [
            Expanded(child: _strategyRow(true)),
            const SizedBox(width: 10),
            Expanded(child: _strategyRow(false)),
          ]),
          const SizedBox(height: 6),

          // ── End condition ─────────────────────────────────────────────────
          _endConditionRow(),
          const SizedBox(height: 10),

          // ── Character slots ───────────────────────────────────────────────
          for (int i = 0; i < max(_chalPartySize, _enemyPartySize); i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: i < _chalPartySize
                        ? _slotCard(i, isChallenger: true)
                        : const SizedBox(),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: i < _enemyPartySize
                        ? _slotCard(i, isChallenger: false)
                        : const SizedBox(),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 10),

          // ── Past performance + recents (defined in duel_panel_recents.dart) ─
          _buildPastPerformance(),
          _buildRecentsSection(),
          const SizedBox(height: 10),

          // ── Start button ──────────────────────────────────────────────────
          SizedBox(
            height: 38,
            child: ElevatedButton(
              onPressed: canStart ? _doStartDuel : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: canStart ? const Color(0xFF533483) : Colors.grey[700],
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
              ),
              child: Text(
                widget.manager.phase == DuelPhase.active ? 'Duel in Progress' : 'Start Duel',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),

          if (widget.manager.phase == DuelPhase.completed) ...[
            const SizedBox(height: 10),
            Center(child: _winnerBanner(widget.manager)),
          ],
        ],
      ),
    );
  }

  // ── End condition toggle ───────────────────────────────────────────────────

  Widget _endConditionRow() {
    return Row(children: [
      const Text('Ends: ', style: TextStyle(color: Color(0xFF9e9e9e), fontSize: 10)),
      const SizedBox(width: 2),
      ...DuelEndCondition.values.map((cond) {
        final sel   = _endCondition == cond;
        final label = duelEndConditionLabels[cond]!;
        return GestureDetector(
          onTap: () => setState(() => _endCondition = cond),
          child: Container(
            margin: const EdgeInsets.only(right: 4),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: sel ? const Color(0xFF533483) : const Color(0xFF16213e),
              borderRadius: BorderRadius.circular(3),
              border: Border.all(color: sel ? const Color(0xFF533483) : Colors.white24),
            ),
            child: Text(label,
                style: TextStyle(
                  color: sel ? Colors.white : const Color(0xFF9e9e9e),
                  fontSize: 10,
                  fontWeight: sel ? FontWeight.bold : FontWeight.normal,
                )),
          ),
        );
      }),
    ]);
  }

  // ── Side header ────────────────────────────────────────────────────────────

  Widget _sideHeader(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      alignment: Alignment.center,
      child: Text(label,
          style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold,
              letterSpacing: 1.2)),
    );
  }

  // ── Party size selector (1–5 buttons) ──────────────────────────────────────

  Widget _partySizeRow(bool isChallenger) {
    final size = isChallenger ? _chalPartySize : _enemyPartySize;
    return Row(children: [
      const Text('Party: ', style: TextStyle(color: Color(0xFF9e9e9e), fontSize: 10)),
      const SizedBox(width: 4),
      ...List.generate(5, (i) {
        final n = i + 1;
        final selected = size == n;
        return GestureDetector(
          onTap: () => _setPartySize(isChallenger, n),
          child: Container(
            width: 24, height: 22,
            margin: const EdgeInsets.only(right: 3),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected ? const Color(0xFF533483) : const Color(0xFF16213e),
              borderRadius: BorderRadius.circular(3),
              border: Border.all(
                  color: selected ? const Color(0xFF533483) : Colors.white24),
            ),
            child: Text('$n',
                style: TextStyle(
                  color: selected ? Colors.white : const Color(0xFF9e9e9e),
                  fontSize: 10,
                  fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                )),
          ),
        );
      }),
    ]);
  }

  // ── Strategy dropdown ──────────────────────────────────────────────────────

  Widget _strategyRow(bool isChallenger) {
    final strategy = isChallenger ? _chalStrategy : _enemyStrategy;
    return Row(children: [
      const Text('AI: ', style: TextStyle(color: Color(0xFF9e9e9e), fontSize: 10)),
      Expanded(
        child: Container(
          height: 28,
          padding: const EdgeInsets.symmetric(horizontal: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF16213e),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: Colors.white12),
          ),
          child: DropdownButton<DuelStrategy>(
            value: strategy,
            isExpanded: true,
            underline: const SizedBox.shrink(),
            dropdownColor: const Color(0xFF16213e),
            style: const TextStyle(color: Color(0xFFe0e0e0), fontSize: 11),
            items: DuelStrategy.values.map((s) => DropdownMenuItem(
              value: s,
              child: Text(duelStrategyLabels[s]!),
            )).toList(),
            onChanged: (v) {
              if (v == null) return;
              setState(() {
                if (isChallenger) {
                  _chalStrategy = v;
                } else {
                  _enemyStrategy = v;
                }
              });
            },
          ),
        ),
      ),
    ]);
  }

  // ── Character slot card ────────────────────────────────────────────────────

  Widget _slotCard(int index, {required bool isChallenger}) {
    final borderColor = isChallenger
        ? Colors.blueAccent.withValues(alpha: 0.35)
        : const Color(0xFFef5350).withValues(alpha: 0.35);
    final selectedClass = isChallenger ? _chalClasses[index] : _enemyTypes[index];
    final gearTier      = isChallenger ? _chalGearTiers[index] : _enemyGearTiers[index];

    // Reason: filter available types to match the Abilities Codex mode so the
    // Duel Arena only offers classes that are enabled in the current scenario config.
    final codexMode = globalScenarioConfig?.abilitiesCodexMode ?? 'expanded';
    final availableTypes = DuelDefinitions.availableCombatantTypes(codexMode);

    // Reason: if the previously-selected class is no longer in the filtered list
    // (e.g. mode switched from expanded to development), treat the slot as unset
    // to prevent a Flutter assertion from a DropdownButton value not in its items.
    final validSelection = availableTypes.contains(selectedClass) ? selectedClass : null;

    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: const Color(0xFF16213e),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: borderColor),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Slot ${index + 1}',
            style: const TextStyle(color: Color(0xFF9e9e9e), fontSize: 9,
                fontWeight: FontWeight.bold, letterSpacing: 0.8)),
        const SizedBox(height: 4),
        _compactDropdown(
          value: validSelection,
          items: availableTypes,
          displayNames: DuelDefinitions.allDisplayNames,
          onChanged: (v) => setState(() {
            if (isChallenger) {
              _chalClasses[index] = v;
            } else {
              _enemyTypes[index]  = v;
            }
          }),
        ),
        const SizedBox(height: 5),

        // Gear tier row
        Row(children: [
          const Text('Gear: ', style: TextStyle(color: Color(0xFF9e9e9e), fontSize: 9)),
          ...List.generate(5, (t) {
            final selected = gearTier == t;
            final color    = _setupGearColors[t];
            return Tooltip(
              message: _setupGearNames[t],
              waitDuration: const Duration(milliseconds: 300),
              child: GestureDetector(
                onTap: () => setState(() {
                  if (isChallenger) {
                    _chalGearTiers[index] = t;
                  } else {
                    _enemyGearTiers[index] = t;
                  }
                }),
                child: Container(
                  width: 18, height: 18,
                  margin: const EdgeInsets.only(right: 3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: selected ? color : color.withValues(alpha: 0.15),
                    border: Border.all(color: color, width: selected ? 2.0 : 0.8),
                  ),
                ),
              ),
            );
          }),
          const Spacer(),
          Text(_setupGearNames[gearTier],
              style: TextStyle(color: _setupGearColors[gearTier], fontSize: 9,
                  fontWeight: FontWeight.bold)),
        ]),
      ]),
    );
  }

  // ── Compact dropdown ───────────────────────────────────────────────────────

  Widget _compactDropdown({
    required String? value,
    required List<String> items,
    required Map<String, String> displayNames,
    required void Function(String?) onChanged,
  }) {
    return Container(
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF1a1a2e),
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: Colors.white12),
      ),
      child: DropdownButton<String>(
        value: value,
        isExpanded: true,
        underline: const SizedBox.shrink(),
        dropdownColor: const Color(0xFF16213e),
        hint: const Text('Select…',
            style: TextStyle(color: Color(0xFF9e9e9e), fontSize: 11)),
        style: const TextStyle(color: Color(0xFFe0e0e0), fontSize: 11),
        items: items.map((id) => DropdownMenuItem(
          value: id,
          child: Text(displayNames[id] ?? id, overflow: TextOverflow.ellipsis),
        )).toList(),
        onChanged: onChanged,
      ),
    );
  }

  // ── Randomize + seed helpers ───────────────────────────────────────────────

  /// Row containing [Randomize] button, seed input field, and [Enter] button.
  Widget _randomizeRow(bool isChallenger) {
    final ctrl  = isChallenger ? _chalSeedCtrl : _enemySeedCtrl;
    return Row(children: [
      // Randomize button
      SizedBox(
        height: 26,
        child: ElevatedButton(
          onPressed: () => _randomizeSide(isChallenger),
          style: ElevatedButton.styleFrom(
            backgroundColor: isChallenger
                ? Colors.blueAccent.withValues(alpha: 0.25)
                : const Color(0xFFef5350).withValues(alpha: 0.25),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 6),
            minimumSize: Size.zero,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
            side: BorderSide(
                color: isChallenger
                    ? Colors.blueAccent.withValues(alpha: 0.5)
                    : const Color(0xFFef5350).withValues(alpha: 0.5)),
          ),
          child: const Text('Rnd', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold)),
        ),
      ),
      const SizedBox(width: 4),
      // Seed input field
      Expanded(
        child: SizedBox(
          height: 26,
          child: TextField(
            controller: ctrl,
            style: const TextStyle(color: Color(0xFFe0e0e0), fontSize: 10),
            decoration: InputDecoration(
              hintText: 'seed',
              hintStyle: const TextStyle(color: Color(0xFF9e9e9e), fontSize: 10),
              contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              filled: true,
              fillColor: const Color(0xFF16213e),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(3),
                  borderSide: const BorderSide(color: Colors.white12)),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(3),
                  borderSide: const BorderSide(color: Colors.white12)),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(3),
                  borderSide: const BorderSide(color: Color(0xFF533483))),
            ),
            keyboardType: TextInputType.number,
          ),
        ),
      ),
      const SizedBox(width: 4),
      // Enter (apply seed) button
      SizedBox(
        height: 26,
        child: ElevatedButton(
          onPressed: () => _applySeed(isChallenger, ctrl.text.trim()),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF533483),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 6),
            minimumSize: Size.zero,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
          ),
          child: const Text('↵', style: TextStyle(fontSize: 12)),
        ),
      ),
    ]);
  }

  /// Fill all slots on [isChallenger] side with random valid classes.
  void _randomizeSide(bool isChallenger) {
    final codexMode   = globalScenarioConfig?.abilitiesCodexMode ?? 'expanded';
    final available   = DuelDefinitions.availableCombatantTypes(codexMode);
    final rng         = Random();
    final partySize   = isChallenger ? _chalPartySize : _enemyPartySize;
    setState(() {
      for (int i = 0; i < partySize; i++) {
        final picked = available[rng.nextInt(available.length)];
        if (isChallenger) {
          while (_chalClasses.length <= i) { _chalClasses.add(null); }
          _chalClasses[i] = picked;
        } else {
          while (_enemyTypes.length <= i) { _enemyTypes.add(null); }
          _enemyTypes[i] = picked;
        }
      }
    });
  }

  /// Encode the current slot selections into a numeric seed string.
  ///
  /// Format: `partySize` (1 digit) + 2 zero-padded digits per slot where
  /// `slotVal = classIndex * 5 + gearTier`.  Returns empty string when any
  /// slot is unset.
  String _computeSeed({required bool isChallenger}) {
    final classes   = isChallenger ? _chalClasses   : _enemyTypes;
    final gears     = isChallenger ? _chalGearTiers : _enemyGearTiers;
    final partySize = isChallenger ? _chalPartySize  : _enemyPartySize;
    final allTypes  = DuelDefinitions.allCombatantTypes;
    final buf = StringBuffer()..write(partySize);
    for (int i = 0; i < partySize; i++) {
      final type = i < classes.length ? classes[i] : null;
      if (type == null) return '';
      final classIdx = allTypes.indexOf(type);
      if (classIdx < 0) return '';
      final gear     = i < gears.length ? gears[i] : 0;
      buf.write((classIdx * 5 + gear).toString().padLeft(2, '0'));
    }
    return buf.toString();
  }

  /// Decode a seed string and apply the resulting classes + gear tiers to the
  /// specified side.  Silently ignores invalid seeds.
  void _applySeed(bool isChallenger, String seed) {
    if (seed.isEmpty) return;
    final partyDigit = int.tryParse(seed[0]);
    if (partyDigit == null || partyDigit < 1 || partyDigit > 5) return;
    final expected = 1 + partyDigit * 2;
    if (seed.length != expected) return;
    final allTypes = DuelDefinitions.allCombatantTypes;
    final classes  = <String>[];
    final gears    = <int>[];
    for (int i = 0; i < partyDigit; i++) {
      final part = seed.substring(1 + i * 2, 3 + i * 2);
      final slotVal = int.tryParse(part);
      if (slotVal == null) return;
      final classIdx = slotVal ~/ 5;
      final gear     = slotVal % 5;
      if (classIdx >= allTypes.length) return;
      classes.add(allTypes[classIdx]);
      gears.add(gear);
    }
    // All slots decoded successfully — apply and resize party.
    setState(() {
      _setPartySize(isChallenger, partyDigit);
      for (int i = 0; i < partyDigit; i++) {
        if (isChallenger) {
          while (_chalClasses.length <= i)   { _chalClasses.add(null); }
          while (_chalGearTiers.length <= i) { _chalGearTiers.add(0); }
          _chalClasses[i]   = classes[i];
          _chalGearTiers[i] = gears[i];
        } else {
          while (_enemyTypes.length <= i)     { _enemyTypes.add(null); }
          while (_enemyGearTiers.length <= i) { _enemyGearTiers.add(0); }
          _enemyTypes[i]    = classes[i];
          _enemyGearTiers[i] = gears[i];
        }
      }
    });
  }

  // ── Start-duel callback ────────────────────────────────────────────────────

  void _doStartDuel() {
    final chalClasses = List<String>.from(
        _chalClasses.sublist(0, _chalPartySize).whereType<String>());
    final enemyTypes = List<String>.from(
        _enemyTypes.sublist(0, _enemyPartySize).whereType<String>());

    widget.onStartDuel(DuelSetupConfig(
      challengerClasses:   chalClasses,
      enemyTypes:          enemyTypes,
      challengerGearTiers: List<int>.from(_chalGearTiers.sublist(0, _chalPartySize)),
      enemyGearTiers:      List<int>.from(_enemyGearTiers.sublist(0, _enemyPartySize)),
      challengerStrategy:  _chalStrategy,
      enemyStrategy:       _enemyStrategy,
      endCondition:        _endCondition,
    ));
    setState(() => _tabIndex = 1);
  }
}

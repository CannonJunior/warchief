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
                if (isChallenger) _chalStrategy = v;
                else              _enemyStrategy = v;
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
          value: selectedClass,
          items: DuelDefinitions.allCombatantTypes,
          displayNames: DuelDefinitions.allDisplayNames,
          onChanged: (v) => setState(() {
            if (isChallenger) _chalClasses[index] = v;
            else              _enemyTypes[index]  = v;
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
                  if (isChallenger) _chalGearTiers[index] = t;
                  else              _enemyGearTiers[index] = t;
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

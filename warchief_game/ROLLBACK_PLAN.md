# Rollback Plan - Warchief Game Refactoring

**Branch**: refactor/modular-architecture
**Created**: 2025-11-01
**Purpose**: Define procedures for safely rolling back refactoring changes if issues arise

---

## Quick Rollback Commands

### Emergency: Discard All Changes
```bash
git checkout main
git branch -D refactor/modular-architecture
```

### Rollback to Specific Phase
```bash
# List available commits
git log --oneline

# Rollback to specific commit
git reset --hard <commit-hash>

# Or rollback by number of commits
git reset --hard HEAD~1  # Go back 1 commit
git reset --hard HEAD~3  # Go back 3 commits
```

### Rollback Single File
```bash
# Restore file from main branch
git checkout main -- lib/game3d/game3d_widget.dart

# Restore file from specific commit
git checkout <commit-hash> -- lib/models/projectile.dart
```

---

## Phase-by-Phase Rollback

### Phase 0: Preparation
**What was done**:
- Created refactor/modular-architecture branch
- Set up test structure
- Created documentation

**Rollback**:
```bash
git checkout main
# No code changes, just delete branch if needed
```

### Phase 1: Extract Models
**What will be done**:
- Create lib/models/projectile.dart
- Create lib/models/impact_effect.dart
- Create lib/models/ally.dart
- Create lib/models/ai_chat_message.dart

**Rollback**:
```bash
# Delete new files
rm lib/models/projectile.dart
rm lib/models/impact_effect.dart
rm lib/models/ally.dart
rm lib/models/ai_chat_message.dart

# Restore game3d_widget.dart
git checkout HEAD~1 -- lib/game3d/game3d_widget.dart
```

### Phase 2: Extract Configuration
**What will be done**:
- Create lib/game3d/state/game_config.dart

**Rollback**:
```bash
rm lib/game3d/state/game_config.dart
git checkout HEAD~1 -- lib/game3d/game3d_widget.dart
```

### Phase 3: Extract Game State
**What will be done**:
- Create lib/game3d/state/game_state.dart

**Rollback**:
```bash
rm lib/game3d/state/game_state.dart
git checkout HEAD~1 -- lib/game3d/game3d_widget.dart
```

### Phase 4-8: Extract Systems
**What will be done**:
- Create multiple system files

**Rollback**:
```bash
# Delete all system files
rm -rf lib/game3d/systems/

# Restore main widget
git checkout HEAD~N -- lib/game3d/game3d_widget.dart  # N = number of commits
```

---

## Testing After Rollback

After any rollback, verify game still works:

1. **Check git status**
   ```bash
   git status
   ```

2. **Run the game**
   ```bash
   flutter run -d web-server --web-port=8008
   ```

3. **Test critical paths**
   - Player movement works
   - Abilities work
   - Monster and allies function
   - No console errors

4. **Check GAME_BEHAVIOR_CHECKLIST.md**
   - Run through at least core functionality tests

---

## Common Rollback Scenarios

### Scenario 1: Compile Errors After Refactor
**Problem**: Code doesn't compile after extracting a module

**Solution**:
```bash
# Check what changed
git diff HEAD~1

# If too broken, rollback the commit
git reset --hard HEAD~1

# Fix issues, recommit
```

### Scenario 2: Game Doesn't Load
**Problem**: Black screen or crash on load

**Solution**:
```bash
# Check browser console for errors
# Identify problematic file/change

# Rollback specific file
git checkout HEAD~1 -- <problematic-file>

# Or rollback entire commit
git reset --hard HEAD~1
```

### Scenario 3: Functionality Broken
**Problem**: Feature works but behaves incorrectly

**Solution**:
```bash
# Create backup of current state
git stash

# Rollback to known good state
git reset --hard HEAD~1

# Reapply changes carefully
git stash pop

# Or manually reimplement
```

### Scenario 4: Performance Regression
**Problem**: Game runs slower after refactor

**Solution**:
```bash
# Use git bisect to find problematic commit
git bisect start
git bisect bad  # Current state is slow
git bisect good HEAD~5  # Known good state

# Test each commit git bisect gives you
# Mark as good/bad until found

git bisect reset  # When done
git revert <bad-commit>  # Revert the problematic change
```

---

##  Preventive Measures

### Before Each Phase
1. ✅ Commit all working changes
2. ✅ Run full test checklist
3. ✅ Tag commit for easy reference
   ```bash
   git tag phase-N-start
   ```

### After Each Phase
1. ✅ Verify game still works
2. ✅ Run test checklist again
3. ✅ Commit with descriptive message
4. ✅ Tag successful completion
   ```bash
   git tag phase-N-complete
   ```

### Using Tags for Rollback
```bash
# List all tags
git tag

# Rollback to specific tag
git reset --hard phase-2-complete

# Delete a tag
git tag -d phase-3-start
```

---

## Recovery Procedures

### Lost Work Recovery
If you accidentally delete uncommitted work:

```bash
# Find lost commits in reflog
git reflog

# Restore from reflog
git checkout <reflog-hash>

# Create recovery branch
git checkout -b recovery-branch
```

### Merge Conflicts
If merging back to main causes conflicts:

```bash
# Abort merge
git merge --abort

# Try rebase instead
git rebase main

# Or merge with strategy
git merge main -X theirs  # Prefer main's changes
git merge main -X ours    # Prefer our changes
```

---

## Points of No Return

### Cannot Rollback After:
1. **Force pushing to shared branch** - Coordinate with team first
2. **Deleting the refactor branch** - Make sure all changes are merged
3. **Clearing git reflog** - Reflog expires after 90 days by default

### Safe Points:
- Any committed change can be rolled back
- Stashed changes are recoverable
- Tagged commits are easy reference points

---

## Contact & Escalation

If rollback fails or causes more issues:

1. **Check git reflog** for history
2. **Don't force push** without backup
3. **Create issue** in project tracker
4. **Document** what went wrong in this file

---

## Rollback Log

Track all rollbacks here:

```
Date       | Phase | Reason                          | Resolution
-----------|-------|--------------------------------|---------------------------
2025-11-01 | N/A   | Example: Player movement broke | Rolled back, fixed import
```

---

## Final Notes

- **Always commit before major changes**
- **Test thoroughly after each phase**
- **Don't panic** - Git history is recoverable
- **Document issues** for future reference
- **Keep main branch stable** at all times

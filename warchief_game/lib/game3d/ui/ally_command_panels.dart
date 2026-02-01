import 'package:flutter/material.dart';
import '../../models/ally.dart';

/// Panel for the Attack command (T key)
class AttackCommandPanel extends StatelessWidget {
  final AllyCommand currentCommand;
  final VoidCallback onActivate;
  final int allyCount;

  const AttackCommandPanel({
    Key? key,
    required this.currentCommand,
    required this.onActivate,
    required this.allyCount,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isActive = currentCommand == AllyCommand.attack;

    return Container(
      padding: EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.8),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isActive ? Colors.red : Colors.red.withOpacity(0.5),
          width: isActive ? 2 : 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.sports_martial_arts,
                color: isActive ? Colors.red : Colors.red.withOpacity(0.7),
                size: 18,
              ),
              SizedBox(width: 6),
              Text(
                'ATTACK (T)',
                style: TextStyle(
                  color: isActive ? Colors.red : Colors.white70,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
          SizedBox(height: 6),
          Text(
            'All allies aggressively\nattack the enemy',
            style: TextStyle(
              color: Colors.white60,
              fontSize: 9,
            ),
          ),
          SizedBox(height: 8),
          InkWell(
            onTap: onActivate,
            borderRadius: BorderRadius.circular(4),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isActive ? Colors.red : Colors.red.withOpacity(0.3),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: isActive ? Colors.white : Colors.red,
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isActive ? Icons.check : Icons.play_arrow,
                    size: 14,
                    color: Colors.white,
                  ),
                  SizedBox(width: 4),
                  Text(
                    isActive ? 'ACTIVE' : 'ACTIVATE',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 4),
          Text(
            '$allyCount allies ready',
            style: TextStyle(
              color: Colors.white38,
              fontSize: 8,
            ),
          ),
        ],
      ),
    );
  }
}

/// Panel for the Follow command (F key)
class FollowCommandPanel extends StatelessWidget {
  final AllyCommand currentCommand;
  final VoidCallback onActivate;
  final int allyCount;

  const FollowCommandPanel({
    Key? key,
    required this.currentCommand,
    required this.onActivate,
    required this.allyCount,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isActive = currentCommand == AllyCommand.follow;

    return Container(
      padding: EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.8),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isActive ? Colors.green : Colors.green.withOpacity(0.5),
          width: isActive ? 2 : 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.directions_walk,
                color: isActive ? Colors.green : Colors.green.withOpacity(0.7),
                size: 18,
              ),
              SizedBox(width: 6),
              Text(
                'FOLLOW (F)',
                style: TextStyle(
                  color: isActive ? Colors.green : Colors.white70,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
          SizedBox(height: 6),
          Text(
            'All allies follow and\nstay near the player',
            style: TextStyle(
              color: Colors.white60,
              fontSize: 9,
            ),
          ),
          SizedBox(height: 8),
          InkWell(
            onTap: onActivate,
            borderRadius: BorderRadius.circular(4),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isActive ? Colors.green : Colors.green.withOpacity(0.3),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: isActive ? Colors.white : Colors.green,
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isActive ? Icons.check : Icons.play_arrow,
                    size: 14,
                    color: Colors.white,
                  ),
                  SizedBox(width: 4),
                  Text(
                    isActive ? 'ACTIVE' : 'ACTIVATE',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 4),
          Text(
            '$allyCount allies ready',
            style: TextStyle(
              color: Colors.white38,
              fontSize: 8,
            ),
          ),
        ],
      ),
    );
  }
}

/// Panel for the Hold command (G key)
class HoldCommandPanel extends StatelessWidget {
  final AllyCommand currentCommand;
  final VoidCallback onActivate;
  final int allyCount;

  const HoldCommandPanel({
    Key? key,
    required this.currentCommand,
    required this.onActivate,
    required this.allyCount,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isActive = currentCommand == AllyCommand.hold;

    return Container(
      padding: EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.8),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isActive ? Colors.orange : Colors.orange.withOpacity(0.5),
          width: isActive ? 2 : 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.front_hand,
                color: isActive ? Colors.orange : Colors.orange.withOpacity(0.7),
                size: 18,
              ),
              SizedBox(width: 6),
              Text(
                'HOLD (G)',
                style: TextStyle(
                  color: isActive ? Colors.orange : Colors.white70,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
          SizedBox(height: 6),
          Text(
            'All allies hold position\nand defend the area',
            style: TextStyle(
              color: Colors.white60,
              fontSize: 9,
            ),
          ),
          SizedBox(height: 8),
          InkWell(
            onTap: onActivate,
            borderRadius: BorderRadius.circular(4),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isActive ? Colors.orange : Colors.orange.withOpacity(0.3),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: isActive ? Colors.white : Colors.orange,
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isActive ? Icons.check : Icons.play_arrow,
                    size: 14,
                    color: Colors.white,
                  ),
                  SizedBox(width: 4),
                  Text(
                    isActive ? 'ACTIVE' : 'ACTIVATE',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 4),
          Text(
            '$allyCount allies ready',
            style: TextStyle(
              color: Colors.white38,
              fontSize: 8,
            ),
          ),
        ],
      ),
    );
  }
}

/// Combined panel showing all command buttons in a compact format
class AllyCommandBar extends StatelessWidget {
  final AllyCommand currentCommand;
  final void Function(AllyCommand) onCommandChanged;
  final int allyCount;

  const AllyCommandBar({
    Key? key,
    required this.currentCommand,
    required this.onCommandChanged,
    required this.allyCount,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.8),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.cyan, width: 2),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ALLY COMMANDS',
            style: TextStyle(
              color: Colors.cyan,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          SizedBox(height: 6),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildCommandButton(
                'T',
                'ATK',
                Colors.red,
                AllyCommand.attack,
              ),
              SizedBox(width: 4),
              _buildCommandButton(
                'F',
                'FLW',
                Colors.green,
                AllyCommand.follow,
              ),
              SizedBox(width: 4),
              _buildCommandButton(
                'G',
                'HLD',
                Colors.orange,
                AllyCommand.hold,
              ),
            ],
          ),
          SizedBox(height: 4),
          Text(
            'SHIFT+key to toggle panel',
            style: TextStyle(
              color: Colors.white30,
              fontSize: 7,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommandButton(
    String key,
    String label,
    Color color,
    AllyCommand command,
  ) {
    final isActive = currentCommand == command;

    return Tooltip(
      message: 'Press $key or click',
      child: InkWell(
        onTap: () => onCommandChanged(command),
        borderRadius: BorderRadius.circular(4),
        child: Container(
          width: 36,
          height: 32,
          decoration: BoxDecoration(
            color: isActive ? color : color.withOpacity(0.3),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: isActive ? Colors.white : color,
              width: isActive ? 2 : 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                key,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  color: isActive ? Colors.white : Colors.white70,
                  fontSize: 7,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

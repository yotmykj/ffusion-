/*
 * FFFusion
 * Copyright (C) 2021  Étienne Fesser
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

import 'dart:typed_data';
import 'dart:ui';

import 'package:flauncher/database.dart';
import 'package:flauncher/providers/apps_service.dart';
import 'package:flutter/foundation.dart' hide Category;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

const _activationKeys = [
  LogicalKeyboardKey.select,
  LogicalKeyboardKey.enter,
  LogicalKeyboardKey.gameButtonA
];

class FFFusionAppCard extends StatefulWidget {
  final App app;
  final Category category;
  final bool autofocus;

  const FFFusionAppCard({
    Key? key,
    required this.app,
    required this.category,
    this.autofocus = false,
  }) : super(key: key);

  @override
  _FFFusionAppCardState createState() => _FFFusionAppCardState();
}

class _FFFusionAppCardState extends State<FFFusionAppCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _elevationAnimation;
  bool _hasFocus = false;
  MemoryImage? _cachedIcon;
  MemoryImage? _cachedBanner;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 400),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );

    _elevationAnimation = Tween<double>(begin: 8, end: 24).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  ImageProvider _getCachedIcon(Uint8List bytes) {
    if (!listEquals(bytes, _cachedIcon?.bytes)) {
      _cachedIcon = MemoryImage(bytes);
    }
    return _cachedIcon!;
  }

  ImageProvider _getCachedBanner(Uint8List bytes) {
    if (!listEquals(bytes, _cachedBanner?.bytes)) {
      _cachedBanner = MemoryImage(bytes);
    }
    return _cachedBanner!;
  }

  @override
  Widget build(BuildContext context) => Focus(
        onFocusChange: (hasFocus) {
          setState(() => _hasFocus = hasFocus);
          if (hasFocus) {
            _animationController.forward();
          } else {
            _animationController.reverse();
          }
        },
        onKey: (node, event) => _handleKeyEvent(context, event),
        autofocus: widget.autofocus,
        child: AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) => Transform.scale(
            scale: _scaleAnimation.value,
            child: child,
          ),
          child: AnimatedBuilder(
            animation: _elevationAnimation,
            builder: (context, child) => Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Color(0xFF667EEA).withOpacity(
                        _hasFocus ? 0.6 : 0.3),
                    blurRadius: _elevationAnimation.value,
                    spreadRadius: 1,
                    offset: Offset(
                      0,
                      _hasFocus ? 8 : 4,
                    ),
                  ),
                  if (_hasFocus)
                    BoxShadow(
                      color: Color(0xFF764BA2).withOpacity(0.4),
                      blurRadius: 20,
                      spreadRadius: 0,
                      offset: Offset(0, 0),
                    )
                ],
              ),
              child: child,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: BackdropFilter(
                filter: ImageFilter.blur(
                  sigmaX: 10,
                  sigmaY: 10,
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => _launchApp(context),
                    focusColor: Colors.transparent,
                    highlightColor: Colors.white.withOpacity(0.1),
                    child: Stack(
                      children: [
                        // Background
                        _buildBackground(),
                        // Overlay gradient
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.transparent,
                                  Colors.black.withOpacity(0.4),
                                ],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                            ),
                          ),
                        ),
                        // Content
                        _buildContent(context),
                        // Focus border
                        if (_hasFocus)
                          Positioned.fill(
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color:
                                      Color(0xFF667EEA).withOpacity(0.8),
                                  width: 3,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

  Widget _buildBackground() {
    if (widget.app.banner != null) {
      return Positioned.fill(
        child: Image.memory(
          widget.app.banner!,
          fit: BoxFit.cover,
        ),
      );
    }
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF667EEA).withOpacity(0.5),
              Color(0xFF764BA2).withOpacity(0.5),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) => Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            if (widget.app.icon != null) ..._buildIconAndText(),
            if (widget.app.icon == null)
              Text(
                widget.app.name,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      shadows: [
                        Shadow(
                          color: Colors.black.withOpacity(0.5),
                          blurRadius: 4,
                          offset: Offset(2, 2),
                        )
                      ],
                    ),
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
          ],
        ),
      );

  List<Widget> _buildIconAndText() => [
        Padding(
          padding: EdgeInsets.only(bottom: 12),
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 8,
                  offset: Offset(2, 2),
                )
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.memory(
                widget.app.icon!,
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),
        Flexible(
          child: Text(
            widget.app.name,
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              shadows: [
                Shadow(
                  color: Colors.black.withOpacity(0.5),
                  blurRadius: 4,
                  offset: Offset(2, 2),
                )
              ],
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
          ),
        ),
      ];

  KeyEventResult _handleKeyEvent(
    BuildContext context,
    RawKeyEvent event,
  ) {
    if (event.isKeyPressed(LogicalKeyboardKey.select) ||
        event.isKeyPressed(LogicalKeyboardKey.enter) ||
        event.isKeyPressed(LogicalKeyboardKey.gameButtonA)) {
      _launchApp(context);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  void _launchApp(BuildContext context) {
    final appsService = context.read<AppsService>();
    appsService.launchApp(widget.app);
  }
}

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
import 'package:flauncher/providers/wallpaper_service.dart';
import 'package:flauncher/widgets/apps_grid.dart';
import 'package:flauncher/widgets/category_row.dart';
import 'package:flauncher/widgets/settings/settings_panel.dart';
import 'package:flauncher/widgets/time_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';

class FFFusion extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Stack(
        children: [
          Consumer<WallpaperService>(
            builder: (_, wallpaper, __) => _wallpaper(context, wallpaper.wallpaperBytes, wallpaper.gradient.gradient),
          ),
          Scaffold(
            backgroundColor: Colors.transparent,
            appBar: _buildModernAppBar(context),
            body: Consumer<AppsService>(
              builder: (context, appsService, _) => appsService.initialized
                  ? _buildModernHomeScreen(context, appsService.categoriesWithApps)
                  : _emptyState(context),
            ),
          ),
        ],
      );

  AppBar _buildModernAppBar(BuildContext context) => AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: Container(
          margin: EdgeInsets.all(8),
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
          child: Material(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => showDialog(context: context, builder: (_) => SettingsPanel()),
              child: Icon(Icons.settings_rounded, color: Colors.white),
            ),
          ),
        ),
        centerTitle: true,
        title: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 8,
              )
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: TimeWidget(),
              ),
            ),
          ),
        ),
      );

  Widget _buildModernHomeScreen(
      BuildContext context, List<CategoryWithApps> categoriesWithApps) =>
      CustomScrollView(
        physics: BouncingScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: EdgeInsets.fromLTRB(16, 24, 16, 16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final categoryWithApps = categoriesWithApps[index];
                  return _buildCategorySection(
                    context,
                    categoryWithApps.category,
                    categoryWithApps.applications,
                  );
                },
                childCount: categoriesWithApps.length,
              ),
            ),
          ),
        ],
      );

  Widget _buildCategorySection(
      BuildContext context, Category category, List<App> applications) {
    return Padding(
      padding: EdgeInsets.only(bottom: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Modern category header with accent line
          Padding(
            padding: EdgeInsets.only(left: 0, bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 4,
                      height: 28,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(2),
                        gradient: LinearGradient(
                          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                    SizedBox(width: 12),
                    Text(
                      category.name,
                      style: Theme.of(context).textTheme.headline5!.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            shadows: [
                              Shadow(
                                color: Colors.black.withOpacity(0.3),
                                offset: Offset(2, 2),
                                blurRadius: 8,
                              )
                            ],
                          ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Content based on category type
          switch (category.type) {
            CategoryType.row => _buildCategoryRow(context, category, applications),
            CategoryType.grid => _buildCategoryGrid(context, category, applications),
          },
        ],
      ),
    );
  }

  Widget _buildCategoryRow(
      BuildContext context, Category category, List<App> applications) {
    if (applications.isEmpty) {
      return _buildEmptyState(context);
    }

    return SizedBox(
      height: category.rowHeight.toDouble(),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: BouncingScrollPhysics(),
        padding: EdgeInsets.symmetric(horizontal: 0),
        itemCount: applications.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: EdgeInsets.only(right: 12),
            child: _buildModernAppCard(context, category, applications[index]),
          );
        },
      ),
    );
  }

  Widget _buildCategoryGrid(
      BuildContext context, Category category, List<App> applications) {
    if (applications.isEmpty) {
      return _buildEmptyState(context);
    }

    return GridView.builder(
      shrinkWrap: true,
      primary: false,
      physics: NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: category.columnsCount,
        childAspectRatio: 16 / 9,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
      ),
      itemCount: applications.length,
      itemBuilder: (context, index) {
        return _buildModernAppCard(context, category, applications[index]);
      },
    );
  }

  Widget _buildModernAppCard(
      BuildContext context, Category category, App application) {
    return Consumer<AppsService>(
      builder: (context, appsService, _) => _ModernAppCard(
        category: category,
        application: application,
        onTap: () => appsService.launchApp(application),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) => Container(
        height: 120,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [
              Colors.white.withOpacity(0.05),
              Colors.white.withOpacity(0.02),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(
            color: Colors.white.withOpacity(0.1),
            width: 1,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.folder_open_outlined,
                  color: Colors.white.withOpacity(0.5), size: 32),
              SizedBox(height: 8),
              Text(
                "Empty category",
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );

  Widget _wallpaper(BuildContext context, Uint8List? wallpaperImage,
          Gradient gradient) =>
      wallpaperImage != null
          ? Image.memory(
              wallpaperImage,
              key: Key("background"),
              fit: BoxFit.cover,
              height: window.physicalSize.height,
              width: window.physicalSize.width,
            )
          : Container(
              key: Key("background"),
              decoration: BoxDecoration(gradient: gradient),
            );

  Widget _emptyState(BuildContext context) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
            SizedBox(height: 16),
            Text(
              "Loading FFFusion...",
              style: Theme.of(context).textTheme.headline6,
            ),
          ],
        ),
      );
}

/// Modern app card with glassmorphism effect and full D-pad support
class _ModernAppCard extends StatefulWidget {
  final Category category;
  final App application;
  final VoidCallback onTap;

  const _ModernAppCard({
    Key? key,
    required this.category,
    required this.application,
    required this.onTap,
  }) : super(key: key);

  @override
  _ModernAppCardState createState() => _ModernAppCardState();
}

class _ModernAppCardState extends State<_ModernAppCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _hasFocus = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      onFocusChange: (hasFocus) {
        setState(() => _hasFocus = hasFocus);
        if (hasFocus) {
          _animationController.forward();
        } else {
          _animationController.reverse();
        }
      },
      onKey: (node, event) => _handleKeyEvent(context, event),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(_hasFocus ? 0.5 : 0.3),
                blurRadius: _hasFocus ? 16 : 8,
                offset: Offset(0, _hasFocus ? 4 : 2),
              ),
              if (_hasFocus)
                BoxShadow(
                  color: Color(0xFF6366F1).withOpacity(0.5),
                  blurRadius: 12,
                  offset: Offset(0, 0),
                )
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Material(
                color: Colors.white.withOpacity(_hasFocus ? 0.15 : 0.08),
                child: InkWell(
                  onTap: widget.onTap,
                  focusColor: Colors.transparent,
                  highlightColor: Colors.white.withOpacity(0.1),
                  child: Stack(
                    children: [
                      // Background image or icon + name
                      if (widget.application.banner != null)
                        Positioned.fill(
                          child: Image.memory(
                            widget.application.banner!,
                            fit: BoxFit.cover,
                          ),
                        )
                      else
                        Padding(
                          padding: EdgeInsets.all(12),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.3),
                                        blurRadius: 4,
                                      )
                                    ],
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.memory(
                                      widget.application.icon!,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(width: 12),
                              Flexible(
                                flex: 3,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      widget.application.name,
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        shadows: [
                                          Shadow(
                                            color:
                                                Colors.black.withOpacity(0.5),
                                            blurRadius: 4,
                                            offset: Offset(1, 1),
                                          )
                                        ],
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 2,
                                    ),
                                  ],
                                ),
                              )
                            ],
                          ),
                        ),
                      // Overlay gradient
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.transparent,
                                Colors.black.withOpacity(0.3),
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                        ),
                      ),
                      // Focus border
                      if (_hasFocus)
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Color(0xFF6366F1).withOpacity(0.8),
                                width: 2,
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
  }

  KeyEventResult _handleKeyEvent(BuildContext context, RawKeyEvent event) {
    // Handle D-pad navigation through standard keyboard events
    if (event.isKeyPressed(LogicalKeyboardKey.select) ||
        event.isKeyPressed(LogicalKeyboardKey.enter) ||
        event.isKeyPressed(LogicalKeyboardKey.gameButtonA)) {
      widget.onTap();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }
}

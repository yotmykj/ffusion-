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

import 'dart:ui';

import 'package:flauncher/database.dart';
import 'package:flauncher/providers/apps_service.dart';
import 'package:flauncher/widgets/fffusion_app_card.dart';
import 'package:flauncher/widgets/settings/settings_panel.dart';
import 'package:flauncher/widgets/time_widget.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class FFFusionHome extends StatefulWidget {
  final List<CategoryWithApps> categories;

  const FFFusionHome({
    Key? key,
    required this.categories,
  }) : super(key: key);

  @override
  _FFFusionHomeState createState() => _FFFusionHomeState();
}

class _FFFusionHomeState extends State<FFFusionHome> {
  late ScrollController _scrollController;
  late FocusNode _focusNode;
  int? _selectedCategoryIndex;
  int? _selectedAppIndex;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _focusNode = FocusNode();
    _selectedCategoryIndex = 0;
    _selectedAppIndex = 0;
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(
        children: [
          // Modern Header
          _buildHeader(context),
          // Content
          Expanded(
            child: widget.categories.isEmpty
                ? _buildEmptyState(context)
                : CustomScrollView(
                    controller: _scrollController,
                    physics: BouncingScrollPhysics(),
                    slivers: [
                      SliverPadding(
                        padding: EdgeInsets.fromLTRB(16, 8, 16, 32),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) => _buildCategorySection(
                              context,
                              widget.categories[index],
                              index,
                            ),
                            childCount: widget.categories.length,
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      );

  Widget _buildHeader(BuildContext context) => Container(
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: Colors.white.withOpacity(0.1),
              width: 1,
            ),
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(24),
            bottomRight: Radius.circular(24),
          ),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withOpacity(0.08),
                    Colors.white.withOpacity(0.04),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: Row(
                    children: [
                      // Settings Button
                      _buildHeaderIconButton(
                        context,
                        Icons.settings_rounded,
                        () => showDialog(
                          context: context,
                          builder: (_) => SettingsPanel(),
                        ),
                      ),
                      Spacer(),
                      // Time Display
                      Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          color: Colors.white.withOpacity(0.06),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.12),
                            width: 1,
                          ),
                        ),
                        child: TimeWidget(),
                      ),
                      Spacer(),
                      // Info Button
                      _buildHeaderIconButton(
                        context,
                        Icons.info_outlined,
                        () {},
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );

  Widget _buildHeaderIconButton(
    BuildContext context,
    IconData icon,
    VoidCallback onPressed,
  ) =>
      Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: EdgeInsets.all(8),
            child: Icon(
              icon,
              color: Colors.white,
              size: 24,
            ),
          ),
        ),
      );

  Widget _buildCategorySection(
    BuildContext context,
    CategoryWithApps categoryWithApps,
    int categoryIndex,
  ) =>
      Padding(
        padding: EdgeInsets.only(bottom: 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Category Header with accent
            Padding(
              padding: EdgeInsets.only(left: 8, bottom: 20),
              child: Row(
                children: [
                  Container(
                    width: 5,
                    height: 32,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(2.5),
                      gradient: LinearGradient(
                        colors: [
                          Color(0xFF667EEA),
                          Color(0xFF764BA2),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      categoryWithApps.category.name,
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                    ),
                  ),
                ],
              ),
            ),
            // Apps List/Grid
            _buildCategoryContent(
              context,
              categoryWithApps,
              categoryIndex,
            ),
          ],
        ),
      );

  Widget _buildCategoryContent(
    BuildContext context,
    CategoryWithApps categoryWithApps,
    int categoryIndex,
  ) {
    if (categoryWithApps.applications.isEmpty) {
      return _buildEmptyCategory(context);
    }

    switch (categoryWithApps.category.type) {
      case CategoryType.row:
        return _buildRowLayout(context, categoryWithApps, categoryIndex);
      case CategoryType.grid:
        return _buildGridLayout(context, categoryWithApps, categoryIndex);
    }
  }

  Widget _buildRowLayout(
    BuildContext context,
    CategoryWithApps categoryWithApps,
    int categoryIndex,
  ) =>
      SizedBox(
        height: categoryWithApps.category.rowHeight.toDouble() + 8,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          physics: BouncingScrollPhysics(),
          padding: EdgeInsets.symmetric(horizontal: 0),
          itemCount: categoryWithApps.applications.length,
          itemBuilder: (context, appIndex) => Padding(
            padding: EdgeInsets.only(right: 16),
            child: FFFusionAppCard(
              app: categoryWithApps.applications[appIndex],
              category: categoryWithApps.category,
              autofocus: categoryIndex == 0 && appIndex == 0,
            ),
          ),
        ),
      );

  Widget _buildGridLayout(
    BuildContext context,
    CategoryWithApps categoryWithApps,
    int categoryIndex,
  ) =>
      GridView.builder(
        shrinkWrap: true,
        primary: false,
        physics: NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: categoryWithApps.category.columnsCount,
          childAspectRatio: 16 / 9,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
        ),
        itemCount: categoryWithApps.applications.length,
        itemBuilder: (context, appIndex) => FFFusionAppCard(
          app: categoryWithApps.applications[appIndex],
          category: categoryWithApps.category,
          autofocus: categoryIndex == 0 && appIndex == 0,
        ),
      );

  Widget _buildEmptyCategory(BuildContext context) => Container(
        height: 120,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [
              Colors.white.withOpacity(0.06),
              Colors.white.withOpacity(0.02),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(
            color: Colors.white.withOpacity(0.12),
            width: 1,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.folder_open_outlined,
                color: Colors.white54,
                size: 40,
              ),
              SizedBox(height: 12),
              Text(
                "No apps in this category",
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white60,
                    ),
              ),
            ],
          ),
        ),
      );

  Widget _buildEmptyState(BuildContext context) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.apps_rounded,
              size: 80,
              color: Colors.white30,
            ),
            SizedBox(height: 24),
            Text(
              "No Categories",
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.white70,
                  ),
            ),
            SizedBox(height: 8),
            Text(
              "Tap the settings button to organize your apps",
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white54,
                  ),
            ),
          ],
        ),
      );
}

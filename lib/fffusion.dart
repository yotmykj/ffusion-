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
import 'package:flauncher/widgets/fffusion_home.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class FFFusion extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Stack(
        children: [
          // Wallpaper background
          Consumer<WallpaperService>(
            builder: (_, wallpaper, __) => _buildWallpaper(
              wallpaper.wallpaperBytes,
              wallpaper.gradient.gradient,
            ),
          ),
          // Content
          Scaffold(
            backgroundColor: Colors.transparent,
            body: Consumer<AppsService>(
              builder: (context, appsService, _) => appsService.initialized
                  ? FFFusionHome(
                      categories: appsService.categoriesWithApps,
                    )
                  : _buildLoadingState(context),
            ),
          ),
        ],
      );

  Widget _buildWallpaper(Uint8List? wallpaperImage, Gradient gradient) =>
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

  Widget _buildLoadingState(BuildContext context) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 64,
              height: 64,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox.expand(
                    child: CircularProgressIndicator(
                      strokeWidth: 4,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(Colors.white54),
                    ),
                  ),
                  Icon(
                    Icons.cloud_download_outlined,
                    color: Colors.white,
                    size: 32,
                  ),
                ],
              ),
            ),
            SizedBox(height: 24),
            Text(
              "Loading FFFusion",
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
            ),
            SizedBox(height: 8),
            Text(
              "Preparing your experience...",
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white60,
                  ),
            ),
          ],
        ),
      );
}

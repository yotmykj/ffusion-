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

import 'package:flauncher/database.dart';
import 'package:flauncher/flauncher_channel.dart';
import 'package:flutter/foundation.dart';

class AppsService extends ChangeNotifier {
  final FLauncherChannel _launcherChannel;
  final FLauncherDatabase _database;

  late List<CategoryWithApps> _categoriesWithApps = [];
  bool _initialized = false;

  AppsService(this._launcherChannel, this._database) {
    _init();
  }

  Future<void> _init() async {
    _categoriesWithApps = await _database.getAllCategoriesWithApps();
    _initialized = true;
    notifyListeners();
  }

  List<CategoryWithApps> get categoriesWithApps => _categoriesWithApps;

  bool get initialized => _initialized;

  Future<void> launchApp(App app) async {
    await _launcherChannel.launchApp(app.packageName);
  }

  void reorderApplication(Category category, int oldIndex, int newIndex) {
    final categoryIndex = _categoriesWithApps
        .indexWhere((c) => c.category.id == category.id);
    if (categoryIndex >= 0) {
      final apps = _categoriesWithApps[categoryIndex].applications;
      final app = apps.removeAt(oldIndex);
      apps.insert(newIndex, app);
      notifyListeners();
    }
  }

  Future<void> saveOrderInCategory(Category category) async {
    final categoryIndex = _categoriesWithApps
        .indexWhere((c) => c.category.id == category.id);
    if (categoryIndex >= 0) {
      final apps = _categoriesWithApps[categoryIndex].applications;
      await _database.updateAppsOrder(category, apps);
    }
  }
}

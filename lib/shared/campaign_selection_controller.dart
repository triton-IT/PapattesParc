import 'package:flutter/material.dart';

/// Retained for the app session, independently for every game.
class CampaignSelectionController extends ChangeNotifier {
  CampaignSelectionController(this.selectedIndex, this.unlockedLevel);
  static final Map<String, CampaignSelectionController> _sessions = {};
  static CampaignSelectionController forGame(String id, int unlocked) {
    final controller = _sessions.putIfAbsent(
      id,
      () => CampaignSelectionController(unlocked - 1, unlocked),
    );
    if (unlocked > controller.unlockedLevel) {
      controller.selectedIndex = unlocked - 1;
      controller.focusRequested = true;
    }
    controller.unlockedLevel = unlocked;
    return controller;
  }

  @visibleForTesting
  static void clearSessions() {
    for (final controller in _sessions.values) {
      controller.camera.dispose();
    }
    _sessions.clear();
  }

  final TransformationController camera = TransformationController();
  int selectedIndex;
  int unlockedLevel;
  Size? viewport;
  bool focusRequested = true;

  void select(int index) {
    selectedIndex = index;
    notifyListeners();
  }
}

import 'package:flutter/material.dart';

class GameConstants {
  // Lane positions (left, center, right)
  static const int leftLane = 0;
  static const int centerLane = 1;
  static const int rightLane = 2;

  // Game speed settings
  static const double initialSpeed = 8.0;
  static const double maxSpeed = 20.0;
  static const double speedIncrement = 0.5;
  static const int speedIncrementInterval = 1000; // points

  // Player settings
  static const double playerWidth = 60.0;
  static const double playerHeight = 100.0;
  static const double jumpHeight = 150.0;
  static const double jumpDuration = 0.5; // seconds
  static const double slideDuration = 0.6; // seconds
  static const double slideHeight = 40.0;

  // Lane change
  static const double laneChangeSpeed = 0.15; // seconds

  // Obstacle settings
  static const double obstacleWidth = 60.0;
  static const double obstacleHeight = 80.0;
  static const double minObstacleSpacing = 300.0;
  static const double maxObstacleSpacing = 600.0;

  // Coin settings
  static const double coinSize = 30.0;
  static const int coinValue = 10;

  // Road settings
  static const double roadSegmentLength = 400.0;
  static const int visibleSegments = 5;

  // Colors
  static const Color skyColorTop = Color(0xFF1a237e);
  static const Color skyColorBottom = Color(0xFF4fc3f7);
  static const Color roadColor = Color(0xFF424242);
  static const Color roadLineColor = Color(0xFFFFD54F);
  static const Color grassColor = Color(0xFF2E7D32);
  static const Color templeColor = Color(0xFF8D6E63);
  static const Color goldColor = Color(0xFFFFD700);
  static const Color playerColor = Color(0xFFE53935);

  // Responsive breakpoints
  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 900;
}

class ResponsiveUtils {
  static double getScreenWidth(BuildContext context) {
    return MediaQuery.of(context).size.width;
  }

  static double getScreenHeight(BuildContext context) {
    return MediaQuery.of(context).size.height;
  }

  static double getLaneWidth(BuildContext context) {
    final width = getScreenWidth(context);
    return width / 4; // 3 lanes + margins
  }

  static double getLanePosition(BuildContext context, int lane) {
    final screenWidth = getScreenWidth(context);
    final laneWidth = getLaneWidth(context);
    final centerX = screenWidth / 2;

    switch (lane) {
      case GameConstants.leftLane:
        return centerX - laneWidth;
      case GameConstants.centerLane:
        return centerX;
      case GameConstants.rightLane:
        return centerX + laneWidth;
      default:
        return centerX;
    }
  }

  static double getPlayerSize(BuildContext context) {
    final width = getScreenWidth(context);
    if (width < GameConstants.mobileBreakpoint) {
      return 50.0;
    } else if (width < GameConstants.tabletBreakpoint) {
      return 65.0;
    }
    return 80.0;
  }

  static double getObstacleSize(BuildContext context) {
    final width = getScreenWidth(context);
    if (width < GameConstants.mobileBreakpoint) {
      return 50.0;
    } else if (width < GameConstants.tabletBreakpoint) {
      return 65.0;
    }
    return 80.0;
  }

  static double getCoinSize(BuildContext context) {
    final width = getScreenWidth(context);
    if (width < GameConstants.mobileBreakpoint) {
      return 25.0;
    } else if (width < GameConstants.tabletBreakpoint) {
      return 30.0;
    }
    return 40.0;
  }
}

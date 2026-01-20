import 'dart:math';

enum PlayerState { running, jumping, sliding, dead }

enum ObstacleType {
  lowBarrier,    // Jump over
  highBarrier,   // Slide under
  fullBlock,     // Change lane
  templeRuin,    // Large obstacle
}

enum PowerUpType {
  magnet,        // Attracts coins
  multiplier,    // 2x score
  shield,        // One-time protection
  speedBoost,    // Temporary speed up
}

class Player {
  final int lane;
  final PlayerState state;
  final double verticalPosition; // 0 = ground, positive = up
  final bool hasShield;
  final int multiplier;

  const Player({
    this.lane = 1, // Start in center lane
    this.state = PlayerState.running,
    this.verticalPosition = 0,
    this.hasShield = false,
    this.multiplier = 1,
  });

  Player copyWith({
    int? lane,
    PlayerState? state,
    double? verticalPosition,
    bool? hasShield,
    int? multiplier,
  }) {
    return Player(
      lane: lane ?? this.lane,
      state: state ?? this.state,
      verticalPosition: verticalPosition ?? this.verticalPosition,
      hasShield: hasShield ?? this.hasShield,
      multiplier: multiplier ?? this.multiplier,
    );
  }

  bool get isGrounded => verticalPosition <= 0 && state != PlayerState.jumping;
  bool get isSliding => state == PlayerState.sliding;
  bool get isDead => state == PlayerState.dead;
}

class Obstacle {
  final String id;
  final int lane;
  final double zPosition; // Distance from player
  final ObstacleType type;
  final bool isActive;

  const Obstacle({
    required this.id,
    required this.lane,
    required this.zPosition,
    required this.type,
    this.isActive = true,
  });

  Obstacle copyWith({
    String? id,
    int? lane,
    double? zPosition,
    ObstacleType? type,
    bool? isActive,
  }) {
    return Obstacle(
      id: id ?? this.id,
      lane: lane ?? this.lane,
      zPosition: zPosition ?? this.zPosition,
      type: type ?? this.type,
      isActive: isActive ?? this.isActive,
    );
  }

  double get height {
    switch (type) {
      case ObstacleType.lowBarrier:
        return 40;
      case ObstacleType.highBarrier:
        return 100;
      case ObstacleType.fullBlock:
        return 80;
      case ObstacleType.templeRuin:
        return 120;
    }
  }

  bool get canJumpOver => type == ObstacleType.lowBarrier;
  bool get canSlideUnder => type == ObstacleType.highBarrier;
}

class Coin {
  final String id;
  final int lane;
  final double zPosition;
  final double verticalOffset; // For floating coins
  final bool isCollected;

  const Coin({
    required this.id,
    required this.lane,
    required this.zPosition,
    this.verticalOffset = 0,
    this.isCollected = false,
  });

  Coin copyWith({
    String? id,
    int? lane,
    double? zPosition,
    double? verticalOffset,
    bool? isCollected,
  }) {
    return Coin(
      id: id ?? this.id,
      lane: lane ?? this.lane,
      zPosition: zPosition ?? this.zPosition,
      verticalOffset: verticalOffset ?? this.verticalOffset,
      isCollected: isCollected ?? this.isCollected,
    );
  }
}

class PowerUp {
  final String id;
  final int lane;
  final double zPosition;
  final PowerUpType type;
  final bool isCollected;

  const PowerUp({
    required this.id,
    required this.lane,
    required this.zPosition,
    required this.type,
    this.isCollected = false,
  });

  PowerUp copyWith({
    String? id,
    int? lane,
    double? zPosition,
    PowerUpType? type,
    bool? isCollected,
  }) {
    return PowerUp(
      id: id ?? this.id,
      lane: lane ?? this.lane,
      zPosition: zPosition ?? this.zPosition,
      type: type ?? this.type,
      isCollected: isCollected ?? this.isCollected,
    );
  }
}

class GameState {
  final Player player;
  final List<Obstacle> obstacles;
  final List<Coin> coins;
  final List<PowerUp> powerUps;
  final int score;
  final int coinCount;
  final double distance;
  final double speed;
  final bool isPlaying;
  final bool isGameOver;
  final bool isPaused;
  final int highScore;
  final Random random;

  GameState({
    required this.player,
    required this.obstacles,
    required this.coins,
    required this.powerUps,
    required this.score,
    required this.coinCount,
    required this.distance,
    required this.speed,
    required this.isPlaying,
    required this.isGameOver,
    required this.isPaused,
    required this.highScore,
    Random? random,
  }) : random = random ?? Random();

  factory GameState.initial() {
    return GameState(
      player: const Player(),
      obstacles: const [],
      coins: const [],
      powerUps: const [],
      score: 0,
      coinCount: 0,
      distance: 0,
      speed: 8.0,
      isPlaying: false,
      isGameOver: false,
      isPaused: false,
      highScore: 0,
    );
  }

  GameState copyWith({
    Player? player,
    List<Obstacle>? obstacles,
    List<Coin>? coins,
    List<PowerUp>? powerUps,
    int? score,
    int? coinCount,
    double? distance,
    double? speed,
    bool? isPlaying,
    bool? isGameOver,
    bool? isPaused,
    int? highScore,
  }) {
    return GameState(
      player: player ?? this.player,
      obstacles: obstacles ?? this.obstacles,
      coins: coins ?? this.coins,
      powerUps: powerUps ?? this.powerUps,
      score: score ?? this.score,
      coinCount: coinCount ?? this.coinCount,
      distance: distance ?? this.distance,
      speed: speed ?? this.speed,
      isPlaying: isPlaying ?? this.isPlaying,
      isGameOver: isGameOver ?? this.isGameOver,
      isPaused: isPaused ?? this.isPaused,
      highScore: highScore ?? this.highScore,
      random: random,
    );
  }
}

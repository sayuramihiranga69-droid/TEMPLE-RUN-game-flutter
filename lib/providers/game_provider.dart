import 'dart:async';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/game_models.dart';
import '../utils/game_constants.dart';

final gameProvider = StateNotifierProvider<GameNotifier, GameState>((ref) {
  return GameNotifier();
});

class GameNotifier extends StateNotifier<GameState> {
  GameNotifier() : super(GameState.initial());

  Timer? _gameTimer;
  Timer? _jumpTimer;
  Timer? _slideTimer;
  Timer? _laneChangeTimer;
  int _obstacleIdCounter = 0;
  int _coinIdCounter = 0;

  void startGame() {
    state = GameState.initial().copyWith(
      isPlaying: true,
      isGameOver: false,
      highScore: state.highScore,
    );

    _generateInitialWorld();
    _startGameLoop();
  }

  void _generateInitialWorld() {
    final obstacles = <Obstacle>[];
    final coins = <Coin>[];

    // Generate initial obstacles
    double currentZ = 500;
    for (int i = 0; i < 5; i++) {
      final obstacle = _generateObstacle(currentZ);
      obstacles.add(obstacle);
      currentZ += GameConstants.minObstacleSpacing +
          state.random.nextDouble() *
              (GameConstants.maxObstacleSpacing - GameConstants.minObstacleSpacing);
    }

    // Generate initial coins
    currentZ = 200;
    for (int i = 0; i < 20; i++) {
      final coin = _generateCoin(currentZ);
      coins.add(coin);
      currentZ += 80 + state.random.nextDouble() * 100;
    }

    state = state.copyWith(obstacles: obstacles, coins: coins);
  }

  Obstacle _generateObstacle(double zPosition) {
    final lane = state.random.nextInt(3);
    final types = ObstacleType.values;
    final type = types[state.random.nextInt(types.length)];

    return Obstacle(
      id: 'obstacle_${_obstacleIdCounter++}',
      lane: lane,
      zPosition: zPosition,
      type: type,
    );
  }

  Coin _generateCoin(double zPosition) {
    final lane = state.random.nextInt(3);
    final verticalOffset = state.random.nextBool() ? 0.0 : 50.0;

    return Coin(
      id: 'coin_${_coinIdCounter++}',
      lane: lane,
      zPosition: zPosition,
      verticalOffset: verticalOffset,
    );
  }

  void _startGameLoop() {
    _gameTimer?.cancel();
    _gameTimer = Timer.periodic(const Duration(milliseconds: 16), (_) {
      if (!state.isPlaying || state.isPaused || state.isGameOver) return;
      _update();
    });
  }

  void _update() {
    final dt = 0.016; // 60 FPS
    final moveAmount = state.speed * dt * 60;

    // Update distance and score
    final newDistance = state.distance + moveAmount;
    final newScore = state.score + (moveAmount * state.player.multiplier).toInt();

    // Increase speed over time
    double newSpeed = state.speed;
    if (newScore > 0 && newScore % GameConstants.speedIncrementInterval < 10) {
      newSpeed = min(state.speed + GameConstants.speedIncrement * dt,
          GameConstants.maxSpeed);
    }

    // Update obstacles
    final updatedObstacles = state.obstacles.map((obstacle) {
      return obstacle.copyWith(zPosition: obstacle.zPosition - moveAmount);
    }).where((obstacle) => obstacle.zPosition > -100).toList();

    // Generate new obstacles if needed
    if (updatedObstacles.isEmpty ||
        updatedObstacles.last.zPosition < 800) {
      final lastZ = updatedObstacles.isEmpty
          ? 1000.0
          : updatedObstacles.last.zPosition;
      updatedObstacles.add(_generateObstacle(
          lastZ + GameConstants.minObstacleSpacing +
              state.random.nextDouble() *
                  (GameConstants.maxObstacleSpacing - GameConstants.minObstacleSpacing)));
    }

    // Update coins
    var updatedCoins = state.coins.map((coin) {
      return coin.copyWith(zPosition: coin.zPosition - moveAmount);
    }).where((coin) => coin.zPosition > -50 && !coin.isCollected).toList();

    // Generate new coins
    if (updatedCoins.isEmpty || updatedCoins.last.zPosition < 600) {
      final lastZ = updatedCoins.isEmpty ? 800.0 : updatedCoins.last.zPosition;
      for (int i = 0; i < 3; i++) {
        updatedCoins.add(_generateCoin(lastZ + 100 + i * 80));
      }
    }

    // Update player vertical position during jump
    Player updatedPlayer = state.player;
    if (state.player.state == PlayerState.jumping) {
      // Jump handled by timer, just keep state
    }

    // Check collisions
    final collisionResult = _checkCollisions(updatedObstacles, updatedCoins);

    if (collisionResult.hitObstacle && !state.player.hasShield) {
      _gameOver();
      return;
    }

    // Collect coins
    int coinsCollected = 0;
    if (collisionResult.collectedCoinIds.isNotEmpty) {
      coinsCollected = collisionResult.collectedCoinIds.length;
      updatedCoins = updatedCoins.map((coin) {
        if (collisionResult.collectedCoinIds.contains(coin.id)) {
          return coin.copyWith(isCollected: true);
        }
        return coin;
      }).where((coin) => !coin.isCollected).toList();
    }

    state = state.copyWith(
      distance: newDistance,
      score: newScore + (coinsCollected * GameConstants.coinValue * state.player.multiplier),
      coinCount: state.coinCount + coinsCollected,
      speed: newSpeed,
      obstacles: updatedObstacles,
      coins: updatedCoins,
      player: updatedPlayer,
    );
  }

  CollisionResult _checkCollisions(List<Obstacle> obstacles, List<Coin> coins) {
    final hitCoinIds = <String>[];
    bool hitObstacle = false;

    // Check obstacle collisions
    for (final obstacle in obstacles) {
      if (obstacle.zPosition > -30 && obstacle.zPosition < 60) {
        if (obstacle.lane == state.player.lane) {
          // Check if player can avoid
          if (obstacle.canJumpOver && state.player.state == PlayerState.jumping) {
            continue; // Jumped over
          }
          if (obstacle.canSlideUnder && state.player.state == PlayerState.sliding) {
            continue; // Slid under
          }
          hitObstacle = true;
          break;
        }
      }
    }

    // Check coin collisions
    for (final coin in coins) {
      if (coin.zPosition > -20 && coin.zPosition < 40) {
        if (coin.lane == state.player.lane && !coin.isCollected) {
          // Check vertical position for floating coins
          if (coin.verticalOffset > 0) {
            if (state.player.state == PlayerState.jumping ||
                state.player.verticalPosition > 30) {
              hitCoinIds.add(coin.id);
            }
          } else {
            if (state.player.state != PlayerState.jumping ||
                state.player.verticalPosition < 30) {
              hitCoinIds.add(coin.id);
            }
          }
        }
      }
    }

    return CollisionResult(
      hitObstacle: hitObstacle,
      collectedCoinIds: hitCoinIds,
    );
  }

  void moveLeft() {
    if (!state.isPlaying || state.isGameOver || state.isPaused) return;
    if (state.player.lane > 0) {
      _animateLaneChange(state.player.lane - 1);
    }
  }

  void moveRight() {
    if (!state.isPlaying || state.isGameOver || state.isPaused) return;
    if (state.player.lane < 2) {
      _animateLaneChange(state.player.lane + 1);
    }
  }

  void _animateLaneChange(int targetLane) {
    _laneChangeTimer?.cancel();
    state = state.copyWith(
      player: state.player.copyWith(lane: targetLane),
    );
  }

  void jump() {
    if (!state.isPlaying || state.isGameOver || state.isPaused) return;
    if (!state.player.isGrounded) return;

    state = state.copyWith(
      player: state.player.copyWith(
        state: PlayerState.jumping,
        verticalPosition: GameConstants.jumpHeight,
      ),
    );

    _jumpTimer?.cancel();
    _jumpTimer = Timer(
      Duration(milliseconds: (GameConstants.jumpDuration * 1000).toInt()),
      () {
        if (state.player.state == PlayerState.jumping) {
          state = state.copyWith(
            player: state.player.copyWith(
              state: PlayerState.running,
              verticalPosition: 0,
            ),
          );
        }
      },
    );
  }

  void slide() {
    if (!state.isPlaying || state.isGameOver || state.isPaused) return;
    if (state.player.state == PlayerState.jumping) return;

    state = state.copyWith(
      player: state.player.copyWith(
        state: PlayerState.sliding,
      ),
    );

    _slideTimer?.cancel();
    _slideTimer = Timer(
      Duration(milliseconds: (GameConstants.slideDuration * 1000).toInt()),
      () {
        if (state.player.state == PlayerState.sliding) {
          state = state.copyWith(
            player: state.player.copyWith(
              state: PlayerState.running,
            ),
          );
        }
      },
    );
  }

  void _gameOver() {
    _gameTimer?.cancel();
    _jumpTimer?.cancel();
    _slideTimer?.cancel();
    _laneChangeTimer?.cancel();

    final newHighScore = max(state.score, state.highScore);

    state = state.copyWith(
      isPlaying: false,
      isGameOver: true,
      highScore: newHighScore,
      player: state.player.copyWith(state: PlayerState.dead),
    );
  }

  void pauseGame() {
    state = state.copyWith(isPaused: true);
  }

  void resumeGame() {
    state = state.copyWith(isPaused: false);
  }

  void restartGame() {
    startGame();
  }

  @override
  void dispose() {
    _gameTimer?.cancel();
    _jumpTimer?.cancel();
    _slideTimer?.cancel();
    _laneChangeTimer?.cancel();
    super.dispose();
  }
}

class CollisionResult {
  final bool hitObstacle;
  final List<String> collectedCoinIds;

  CollisionResult({
    required this.hitObstacle,
    required this.collectedCoinIds,
  });
}

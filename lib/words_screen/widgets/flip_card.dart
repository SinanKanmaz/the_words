import 'dart:math';
import 'package:flutter/material.dart';

import 'dart:async';

enum FlipDirection {
  vertical,
  horizantal,
}

enum CardSide {
  front,
  back,
}

enum Fill { none, fillFront, fillBack }

class AnimationCard extends StatelessWidget {
  const AnimationCard({Key? key, this.child, this.animation, this.direction})
      : super(key: key);

  final Widget? child;
  final Animation<double>? animation;
  final FlipDirection? direction;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation!,
      builder: (BuildContext context, Widget? child) {
        var transform = Matrix4.identity();
        transform.setEntry(3, 2, 0.001);
        if (direction == FlipDirection.vertical) {
          transform.rotateX(animation!.value);
        } else {
          transform.rotateY(animation!.value);
        }
        return Transform(
          transform: transform,
          alignment: Alignment.center,
          child: child,
        );
      },
      child: child,
    );
  }
}

typedef void BoolCallback(bool isFront);

class FlipCard extends StatefulWidget {
  final Widget front;
  final Widget back;

  /// The amount of milliseconds a turn animation will take.
  final int speed;
  final FlipDirection direction;
  final VoidCallback? onFlip;
  final BoolCallback? onFlipDone;
  final FlipCardController? controller;
  final Fill fill;
  final CardSide side;

  /// If the value is set, the flip effect will work automatically after the specified duration.
  final Duration? autoFlipDuration;

  /// When enabled, the card will flip automatically when touched. This behavior
  /// can be disabled if this is not desired. To manually flip a card from your
  /// code, you could do this:
  ///```dart
  /// GlobalKey<FlipCardState> cardKey = GlobalKey<FlipCardState>();
  ///
  /// @override
  /// Widget build(BuildContext context) {
  ///   return FlipCard(
  ///     key: cardKey,
  ///     flipOnTouch: false,
  ///     front: Container(
  ///       child: RaisedButton(
  ///         onPressed: () => cardKey.currentState.toggleCard(),
  ///         child: Text('Toggle'),
  ///       ),
  ///     ),
  ///     back: Container(
  ///       child: Text('Back'),
  ///     ),
  ///   );
  /// }
  ///```
  final bool flipOnTouch;

  final Alignment alignment;

  const FlipCard({
    Key? key,
    required this.front,
    required this.back,
    this.speed = 500,
    this.onFlip,
    this.onFlipDone,
    this.direction = FlipDirection.horizantal,
    this.controller,
    this.flipOnTouch = true,
    this.alignment = Alignment.center,
    this.fill = Fill.none,
    this.side = CardSide.front,
    this.autoFlipDuration,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return FlipCardState(side == CardSide.front);
  }
}

class FlipCardState extends State<FlipCard>
    with SingleTickerProviderStateMixin {
  AnimationController? controller;
  Animation<double>? _frontRotation;
  Animation<double>? _backRotation;

  bool isFront;

  FlipCardState(this.isFront);

  @override
  void initState() {
    super.initState();
    controller = AnimationController(
      value: isFront ? 0.0 : 1.0,
      duration: Duration(milliseconds: widget.speed),
      vsync: this,
    );
    _frontRotation = TweenSequence(
      [
        TweenSequenceItem<double>(
          tween: Tween(begin: 0.0, end: pi / 2)
              .chain(CurveTween(curve: Curves.easeIn)),
          weight: 50.0,
        ),
        TweenSequenceItem<double>(
          tween: ConstantTween<double>(pi / 2),
          weight: 50.0,
        ),
      ],
    ).animate(controller!);
    _backRotation = TweenSequence(
      [
        TweenSequenceItem<double>(
          tween: ConstantTween<double>(pi / 2),
          weight: 50.0,
        ),
        TweenSequenceItem<double>(
          tween: Tween(begin: -pi / 2, end: 0.0)
              .chain(CurveTween(curve: Curves.easeOut)),
          weight: 50.0,
        ),
      ],
    ).animate(controller!);

    widget.controller?.state = this;

    if (widget.autoFlipDuration != null) {
      Future.delayed(widget.autoFlipDuration!, toggleCard);
    }
  }

  @override
  void didUpdateWidget(FlipCard oldWidget) {
    widget.controller?.state ??= this;
  }

  /// Flip the card
  /// If awaited, returns after animation completes.
  Future<void> toggleCard() async {
    widget.onFlip?.call();

    final isFrontBefore = isFront;
    controller!.duration = Duration(milliseconds: widget.speed);

    final animation = isFront ? controller!.forward() : controller!.reverse();
    animation.whenComplete(() {
      if (widget.onFlipDone != null) widget.onFlipDone!(isFront);
      if (!mounted) return;
      setState(() => isFront = !isFrontBefore);
    });
  }

  /// Flip the card without playing an animation.
  /// This cancels any ongoing animation.
  void toggleCardWithoutAnimation() {
    controller!.stop();

    widget.onFlip?.call();

    if (widget.onFlipDone != null) widget.onFlipDone!(isFront);

    setState(() {
      isFront = !isFront;
      controller!.value = isFront ? 0.0 : 1.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final frontPositioning = widget.fill == Fill.fillFront ? _fill : _noop;
    final backPositioning = widget.fill == Fill.fillBack ? _fill : _noop;

    final child = Stack(
      alignment: widget.alignment,
      fit: StackFit.passthrough,
      children: <Widget>[
        frontPositioning(_buildContent(front: true)),
        backPositioning(_buildContent(front: false)),
      ],
    );

    /// if we need to flip the card on taps, wrap the content
    if (widget.flipOnTouch) {
      return GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: toggleCard,
        child: child,
      );
    }
    return child;
  }

  Widget _buildContent({required bool front}) {
    /// pointer events that would reach the backside of the card should be
    /// ignored
    return IgnorePointer(
      /// absorb the front card when the background is active (!isFront),
      /// absorb the background when the front is active
      ignoring: front ? !isFront : isFront,
      child: AnimationCard(
        animation: front ? _frontRotation : _backRotation,
        child: front ? widget.front : widget.back,
        direction: widget.direction,
      ),
    );
  }

  @override
  void dispose() {
    controller!.dispose();
    super.dispose();
  }
}

Widget _fill(Widget child) => Positioned.fill(child: child);
Widget _noop(Widget child) => child;

class FlipCardController {
  /// The internal widget state.
  /// Use only if you know what you're doing!
  FlipCardState? state;

  /// The underlying AnimationController.
  /// Use only if you know what you're doing!
  AnimationController? get controller {
    assert(state != null,
        'Controller not attached to any FlipCard. Did you forget to pass the controller to the FlipCard?');
    return state!.controller;
  }

  /// Flip the card
  /// If awaited, returns after animation completes.
  Future<void> toggleCard() async => await state?.toggleCard();

  /// Flip the card without playing an animation.
  /// This cancels any ongoing animation.
  void toggleCardWithoutAnimation() => state?.toggleCardWithoutAnimation();

  /// Skew by amount percentage (0 - 1.0)
  /// This can be used with a MouseReagion to indicate that the card can
  /// be flipped. skew(0) to go back to original.
  /// If awaited, returns after animation completes.
  Future<void> skew(double amount, {Duration? duration, Curve? curve}) async {
    assert(0 <= amount && amount <= 1);

    final target = state!.isFront ? amount : 1 - amount;
    await controller
        ?.animateTo(target, duration: duration, curve: curve ?? Curves.linear)
        .asStream()
        .first;
  }

  /// Triggers a flip animation that reverses after the duration
  /// and will run for `total`
  /// If awaited, returns after animation completes.
  Future<void> hint({Duration? duration, Duration? total}) async {
    assert(controller is AnimationController);
    if (!(controller is AnimationController)) return;

    if (controller!.isAnimating || controller!.value != 0) return;

    final durationTotal = total ?? controller!.duration;

    final completer = Completer();

    Duration? original = controller!.duration;
    controller!.duration = durationTotal;
    controller!.forward();

    final durationFlipBack = duration ?? const Duration(milliseconds: 150);

    Timer(durationFlipBack, () {
      controller!.reverse().whenComplete(() {
        completer.complete();
      });
      controller!.duration = original;
    });

    await completer.future;
  }
}

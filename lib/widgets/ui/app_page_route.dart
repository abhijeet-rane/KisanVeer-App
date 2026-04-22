import 'package:flutter/material.dart';
import 'package:kisan_veer/constants/app_motion.dart';

/// Catalogue of page-transition variants this app ships with.
///
/// Use the semantics, not the visual. Pick the one that matches what
/// the user is doing in narrative terms — "moving forward", "opening
/// a modal", "swapping between peers" — and the visual follows.
enum AppPageTransition {
  /// **Shared axis (horizontal)** — use when the user is moving
  /// *forward* in a stack (list → detail, detail → sub-detail).
  /// Outgoing slides left + fades out, incoming slides in from right
  /// + fades in. This is the default for `push`.
  sharedAxisX,

  /// **Shared axis (vertical)** — use for settings / preferences
  /// drill-downs where the new screen feels like it belongs "inside"
  /// the previous one rather than "next to" it.
  sharedAxisY,

  /// **Fade through** — use when navigating between peer destinations
  /// that are conceptually siblings (switching a tab, swapping a
  /// filter view). No motion direction implied.
  fadeThrough,

  /// **Fade + scale** — use for modal-ish surfaces that "pop" into
  /// existence (dialogs that take over the screen, full-screen
  /// previews, search results pages).
  fadeScale,

  /// Instant transition with no animation — prefer only for restore /
  /// cold-start flows where animating would feel weird.
  none,
}

/// A theme-aware page route that picks a polished transition based on
/// its [transition] parameter.
///
/// Designed to replace scattered `MaterialPageRoute` / `PageRouteBuilder`
/// call sites and keep every push in the app visually consistent.
///
/// ```dart
/// Navigator.of(context).push(
///   AppPageRoute(
///     builder: (_) => const OrderDetailsScreen(...),
///     transition: AppPageTransition.sharedAxisX,
///   ),
/// );
/// ```
///
/// For the common case, [AppPageRoute.of] is a shorter helper:
///
/// ```dart
/// Navigator.of(context).push(AppPageRoute.of(const OrderDetailsScreen(...)));
/// ```
class AppPageRoute<T> extends PageRouteBuilder<T> {
  AppPageRoute({
    required WidgetBuilder builder,
    this.transition = AppPageTransition.sharedAxisX,
    this.duration = AppMotion.base,
    this.reverseDuration = AppMotion.fast,
    bool opaque = true,
    Color? barrierColor,
    bool barrierDismissible = false,
    bool fullscreenDialog = false,
    super.settings,
  }) : super(
         pageBuilder: (context, animation, secondaryAnimation) =>
             builder(context),
         transitionDuration: duration,
         reverseTransitionDuration: reverseDuration,
         opaque: opaque,
         barrierColor: barrierColor,
         barrierDismissible: barrierDismissible,
         fullscreenDialog: fullscreenDialog,
         transitionsBuilder: (context, animation, secondaryAnimation, child) {
           return _buildTransition(
             transition,
             animation,
             secondaryAnimation,
             child,
           );
         },
       );

  /// Shorthand for the typical "push a child screen" case. Uses
  /// [AppPageTransition.sharedAxisX].
  static AppPageRoute<T> of<T>(
    Widget page, {
    AppPageTransition transition = AppPageTransition.sharedAxisX,
    bool fullscreenDialog = false,
    RouteSettings? settings,
  }) {
    return AppPageRoute<T>(
      builder: (_) => page,
      transition: transition,
      fullscreenDialog: fullscreenDialog,
      settings: settings,
    );
  }

  final AppPageTransition transition;
  final Duration duration;
  final Duration reverseDuration;
}

Widget _buildTransition(
  AppPageTransition type,
  Animation<double> incoming,
  Animation<double> outgoing,
  Widget child,
) {
  switch (type) {
    case AppPageTransition.none:
      return child;

    case AppPageTransition.sharedAxisX:
      final inSlide = Tween<Offset>(
        begin: const Offset(0.12, 0),
        end: Offset.zero,
      ).chain(CurveTween(curve: AppMotion.emphasized)).animate(incoming);
      final inFade = CurvedAnimation(
        parent: incoming,
        curve: const Interval(0.2, 1.0, curve: AppMotion.standard),
      );
      final outSlide = Tween<Offset>(
        begin: Offset.zero,
        end: const Offset(-0.08, 0),
      ).chain(CurveTween(curve: AppMotion.emphasized)).animate(outgoing);
      final outFade = Tween<double>(
        begin: 1,
        end: 0,
      ).chain(CurveTween(curve: const Interval(0, 0.5))).animate(outgoing);

      return SlideTransition(
        position: outSlide,
        child: FadeTransition(
          opacity: outFade,
          child: SlideTransition(
            position: inSlide,
            child: FadeTransition(opacity: inFade, child: child),
          ),
        ),
      );

    case AppPageTransition.sharedAxisY:
      final inSlide = Tween<Offset>(
        begin: const Offset(0, 0.08),
        end: Offset.zero,
      ).chain(CurveTween(curve: AppMotion.emphasized)).animate(incoming);
      final inFade = CurvedAnimation(
        parent: incoming,
        curve: const Interval(0.2, 1.0, curve: AppMotion.standard),
      );
      final outSlide = Tween<Offset>(
        begin: Offset.zero,
        end: const Offset(0, -0.04),
      ).chain(CurveTween(curve: AppMotion.emphasized)).animate(outgoing);
      final outFade = Tween<double>(
        begin: 1,
        end: 0,
      ).chain(CurveTween(curve: const Interval(0, 0.5))).animate(outgoing);

      return SlideTransition(
        position: outSlide,
        child: FadeTransition(
          opacity: outFade,
          child: SlideTransition(
            position: inSlide,
            child: FadeTransition(opacity: inFade, child: child),
          ),
        ),
      );

    case AppPageTransition.fadeThrough:
      final inFade = CurvedAnimation(
        parent: incoming,
        curve: const Interval(0.3, 1.0, curve: AppMotion.standard),
      );
      final inScale = Tween<double>(
        begin: 0.96,
        end: 1.0,
      ).chain(CurveTween(curve: AppMotion.decelerate)).animate(incoming);
      final outFade = Tween<double>(
        begin: 1,
        end: 0,
      ).chain(CurveTween(curve: const Interval(0.0, 0.35))).animate(outgoing);

      return FadeTransition(
        opacity: outFade,
        child: FadeTransition(
          opacity: inFade,
          child: ScaleTransition(scale: inScale, child: child),
        ),
      );

    case AppPageTransition.fadeScale:
      final inFade = CurvedAnimation(parent: incoming, curve: Curves.easeOut);
      final inScale = Tween<double>(begin: 0.92, end: 1.0)
          .chain(CurveTween(curve: AppMotion.emphasizedDecelerate))
          .animate(incoming);

      return FadeTransition(
        opacity: inFade,
        child: ScaleTransition(scale: inScale, child: child),
      );
  }
}

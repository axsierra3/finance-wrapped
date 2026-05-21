import 'package:flutter/material.dart';
import 'dart:math' as math;

//APP THEME CLASS: 
//shared colors and styling accross the app for consistent look and feel
class AppTheme {
  // main mint - brighter background color option
  static const Color mint = Color(0xFFB85F5D8);

  // softer mint - home page background (less saturated)
  static const Color softMint = Color(0xFFF0FDF7);

  // dark forest green - mostly for text
  static const Color darkGreen = Color(0xFF0D3D27);

  // medium forest green - buttons, accents
  static const Color forestGreen = Color(0xFF1A6B52);

  // muted green — subtitles, labels
  static const Color mutedGreen = Color(0xFF2D7A56);

  // lighter mint border for cards
  static const Color mintBorder = Color(0xFFB5F5D8);
}


// LOGO PAINTER CLASS EXTENDING CUSTOM PAINTER
// $ logo with spiral slowly wrapping around it
// CustomPainter is FLutter's way of drawing custom shapes
// you override paint(0) and it gives you a canvas to draw on and define how to draw the shape

class LogoPainter extends CustomPainter {
  // Animation progress goes from 0.0 to 1.0
  // 0.0 = nothing drawn, 1.0 = fully drawn
  // when progress = 1.0 its identical to the static logo used later
  final double progress;

  LogoPainter({this.progress = 1.0}); // by default the logo is fully drawn, but we can change it to 0 to animate it
   
  @override 
  void paint(Canvas canvas, Size size) {
    // center of canvas
    final cx = size.width / 2; // center x coordinate
    final cy = size.height / 2; // center y coordinate

  //scale factor - lets us reuse same code for big and small logos by scaling the coordinates and sizes based on canvas size
    final s = size.width / 180; //180 is the original width of logo design

    //DOLLAR SIGN
    // fades in during first 22% of animation
    final dollarFade = (progress / 0.22).clamp(0.0, 1.0); //fade go from 0 to 1 in .22 of the time progress takes

  //defines paintbrush (color, fade, roundness)
    final dollarPaint = Paint()
      ..color = AppTheme.forestGreen.withValues(alpha: dollarFade) //apply fade tp color
      ..strokeWidth = 3.5 * s 
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
  

  // the S curve of the dollar sign
  // Path + cubicTo is how you draw complex curves in Flutter
  // each cubicTo for path object takes 2 control pts and an end pt
  final sCurve = Path();
  sCurve.moveTo(cx + 14 * s, cy - 18 * s);  // START here — top right of the S, not default (top left)
  sCurve.cubicTo(
      cx + 10 * s, cy - 26 * s,   // control 1
      cx - 14 * s, cy - 26 * s,   // control 2
      cx - 14 * s, cy - 12 * s,   // end
    );
    sCurve.cubicTo(
      cx - 14 * s, cy - 2 * s,
      cx + 14 * s, cy - 2 * s,
      cx + 14 * s, cy + 8 * s,
    );
    sCurve.cubicTo(
      cx + 14 * s, cy + 22 * s,
      cx - 10 * s, cy + 22 * s,
      cx - 14 * s, cy + 14 * s,
    );
    canvas.drawPath(sCurve, dollarPaint); //draw s curve on canvas w/ dollar paintbrush we defined

    // the vertical line through the S
    final verticalLine = Path();
    verticalLine.moveTo(cx, cy - 30 * s);
    verticalLine.lineTo(cx, cy + 30 * s);
    canvas.drawPath(verticalLine, dollarPaint);

    //SPIRAL:
    // starts from top of dollar vertical line annd spirals around clockwise
    // only starts drawing after 18% progress
    // gives the $ sign time to appear first
    if (progress > 0.18) {
      final spiralProgress = ((progress - 0.18) / 0.82).clamp(0.0, 1.0);

      final spiralPaint = Paint()
        ..color = AppTheme.forestGreen
        ..strokeWidth = 3.5 * s
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;

      final spiral = Path();
      const steps = 200;
      final numPoints = (spiralProgress * steps).floor();

      // spiral math — for each point, calculate angle and radius
      // radius grows from minR to maxR as we go around
      // making it expand outward instead of staying a circle
      const totalAngle = 3.2 * 3.14159; // ~3.2 rotations
      const startAngle = -1.5708; // -pi/2 = starts at top

      for (int i = 0; i <= numPoints; i++) {
        final t = i / steps;
        final angle = startAngle + t * totalAngle;
        final r = (30 + (78 - 18) * t) * s; // radius grows 30-78 before expanding out
        final x = cx + r * math.cos(angle);
        final y = cy + r * math.sin(angle);
        if (i == 0) {
          spiral.moveTo(x, y);
        } else {
          spiral.lineTo(x, y);
        }
      }

      canvas.drawPath(spiral, spiralPaint);
    }
  }

  @override
  bool shouldRepaint(LogoPainter oldDelegate) {
    // only redraw when progress changes 
    return oldDelegate.progress != progress;
  }
}     
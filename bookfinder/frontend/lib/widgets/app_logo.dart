import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class AppLogo extends StatelessWidget {
  final double size;
  final bool showText;

  const AppLogo({super.key, this.size = 40, this.showText = false});

  @override
  Widget build(BuildContext context) {
    if (!showText) {
      return SizedBox(
        width: size,
        height: size,
        child: SvgPicture.asset(
          'assets/images/logo.svg',
          fit: BoxFit.contain,
        ),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: size,
          height: size,
          child: SvgPicture.asset(
            'assets/images/logo.svg',
            fit: BoxFit.contain,
          ),
        ),
        const SizedBox(width: 10),
        Text(
          'BookFinder',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
        ),
      ],
    );
  }
}

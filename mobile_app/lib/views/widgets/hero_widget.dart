import 'package:flutter/material.dart';

class HeroWidget extends StatelessWidget {
  const HeroWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: "login_hero",
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20.0),
        child: Image.asset("assets/images/ink_splash.jpg"),
      ),
    );
  }
}

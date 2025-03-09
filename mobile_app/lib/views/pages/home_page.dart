import 'package:flutter/material.dart';
import 'package:mobile_app/views/widgets/hero_widget.dart';
import 'package:mobile_app/data/constants.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            HeroWidget(),
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: 20.0),
              child: Card(
                child: Padding(
                  padding: EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Card Title", style: CustomTextStyles.cardTitle),
                      Text(
                        "This is a card",
                        style: CustomTextStyles.cardDescription,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

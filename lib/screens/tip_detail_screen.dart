import 'package:flutter/material.dart';
import '../models/tip_model.dart';

class TipDetailScreen extends StatelessWidget {
  final TipModel tip;
  const TipDetailScreen({required this.tip});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(tip.title)),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(tip.image, height: 190, fit: BoxFit.cover),
              ),
            ),
            SizedBox(height: 18),
            Text(
              tip.category,
              style: TextStyle(
                color: Colors.brown[600],
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
            SizedBox(height: 12),
            Text(tip.content, style: TextStyle(fontSize: 17)),
          ],
        ),
      ),
    );
  }
}

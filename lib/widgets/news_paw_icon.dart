import 'package:flutter/material.dart';

class NewsPawIcon extends StatelessWidget {
  final double size;
  const NewsPawIcon({this.size = 28});
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size, height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Quadrado do jornal
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: Colors.transparent,
              border: Border.all(color: Colors.grey, width: 2),
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          // Texto "news"
          Positioned(
            top: size * 0.09,
            left: size * 0.13,
            child: Text(
              'news',
              style: TextStyle(
                fontSize: size * 0.32,
                color: Colors.grey[700],
                fontWeight: FontWeight.w600,
                letterSpacing: -0.5,
              ),
            ),
          ),
          // Linha inferior
          Positioned(
            bottom: size * 0.14,
            left: size * 0.13,
            right: size * 0.13,
            child: Container(
              height: size * 0.08,
              color: Colors.grey[400],
            ),
          ),
          // Quadradinho (simula imagem)
          Positioned(
            left: size * 0.13,
            bottom: size * 0.34,
            child: Container(
              width: size * 0.24,
              height: size * 0.24,
              color: Colors.grey[400],
            ),
          ),
          // Patinha
          Positioned(
            right: size * 0.13,
            bottom: size * 0.28,
            child: SizedBox(
              width: size * 0.28,
              height: size * 0.22,
              child: Stack(
                children: [
                  // Almofada
                  Positioned(
                    left: size * 0.11,
                    top: size * 0.10,
                    child: Container(
                      width: size * 0.12,
                      height: size * 0.10,
                      decoration: BoxDecoration(
                        color: Colors.grey[700],
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  // Dedo 1
                  Positioned(
                    left: size * 0.0,
                    top: size * 0.0,
                    child: Container(
                      width: size * 0.06,
                      height: size * 0.08,
                      decoration: BoxDecoration(
                        color: Colors.grey[700],
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  // Dedo 2
                  Positioned(
                    left: size * 0.13,
                    top: size * -0.01,
                    child: Container(
                      width: size * 0.06,
                      height: size * 0.08,
                      decoration: BoxDecoration(
                        color: Colors.grey[700],
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  // Dedo 3
                  Positioned(
                    left: size * 0.21,
                    top: size * 0.03,
                    child: Container(
                      width: size * 0.06,
                      height: size * 0.08,
                      decoration: BoxDecoration(
                        color: Colors.grey[700],
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';

class ProductCard extends StatelessWidget {
  final String imagePath;
  final String title;
  final String price;

  const ProductCard({
    super.key,
    required this.imagePath,
    required this.title,
    required this.price,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () {
        // Handle tap event (e.g., navigate to product details page)
      },
      child: SizedBox(
        width: 160,
        child: Stack(
          children: [
            // Card content
            Card(
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              shadowColor: Colors.black.withOpacity(0.2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image container
                  ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                    child: Image.asset(
                      imagePath,
                      width: double.infinity,
                      height: 150,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Title
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final textStyle = const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        );

                        final textPainter = TextPainter(
                          text: TextSpan(text: title, style: textStyle.copyWith(fontSize: 16)),
                          maxLines: 1,
                          textDirection: TextDirection.ltr,
                        );

                        textPainter.layout(maxWidth: constraints.maxWidth);

                        final isOverflowing = textPainter.didExceedMaxLines;

                        return Text(
                          title,
                          style: textStyle.copyWith(fontSize: isOverflowing ? 12 : 16),
                          maxLines: isOverflowing ? 2 : 1,
                          overflow: TextOverflow.ellipsis,
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Price
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Text(
                      price,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.green,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
            // Heart icon in the bottom right corner
            // Positioned(
            //   bottom: 8,
            //   right: 8,
            //   child: IconButton(
            //     icon: const Icon(Icons.favorite_border, color: Colors.red),
            //     onPressed: () {
            //       // Handle heart icon press
            //     },
            //   ),
            // ),
          ],
        ),
      ),
    );
  }
}

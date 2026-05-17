import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../explore/data/models/customer_experience_model.dart';

class FavoriteExperienceCard extends StatelessWidget {
  final CustomerExperienceModel experience;
  final VoidCallback onTap;
  final VoidCallback onFavoriteTap;

  const FavoriteExperienceCard({
    super.key,
    required this.experience,
    required this.onTap,
    required this.onFavoriteTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasImage = experience.coverPhotoUrl != null &&
        experience.coverPhotoUrl!.trim().isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.07),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 185,
            child: Stack(
              children: [
                Positioned.fill(
                  child: hasImage
                      ? Image.network(
                          experience.coverPhotoUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) {
                            return const _ImagePlaceholder();
                          },
                        )
                      : const _ImagePlaceholder(),
                ),

                Positioned(
                  top: 14,
                  right: 14,
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      onFavoriteTap();
                    },
                    child: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.95),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.10),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.favorite_rounded,
                        color: Color(0xFFE11D48),
                        size: 23,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  experience.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF111827),
                    height: 1.2,
                  ),
                ),

                const SizedBox(height: 10),

                Row(
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      size: 18,
                      color: Color(0xFF6B7280),
                    ),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        experience.displayLocation,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                Row(
                  children: [
                    const Icon(
                      Icons.star_rounded,
                      size: 19,
                      color: Color(0xFFF59E0B),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      experience.rating.toStringAsFixed(1),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF111827),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'Desde ${experience.formattedPrice}',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF111827),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                GestureDetector(
                  onTap: onTap,
                  child: const Text(
                    'Ver detalles',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF2563EB),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ImagePlaceholder extends StatelessWidget {
  const _ImagePlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFE5E7EB),
      child: const Center(
        child: Icon(
          Icons.image_outlined,
          size: 46,
          color: Color(0xFF9CA3AF),
        ),
      ),
    );
  }
}
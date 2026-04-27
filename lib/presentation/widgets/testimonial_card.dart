import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class TestimonialCard extends StatelessWidget {
  final String name;
  final String city;
  final String quote;
  final int rating;
  final String? avatarInitials;

  const TestimonialCard({
    super.key,
    required this.name,
    required this.city,
    required this.quote,
    this.rating = 5,
    this.avatarInitials,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 240,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Stars
          Row(
            children: List.generate(
              5,
              (i) => Icon(
                i < rating ? Icons.star_rounded : Icons.star_border_rounded,
                color: AppColors.gold,
                size: 16,
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Quote
          Text(
            '"$quote"',
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.darkText,
              height: 1.5,
              fontStyle: FontStyle.italic,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 10),
          const Divider(height: 1, color: AppColors.lightGray),
          const SizedBox(height: 10),
          // Author
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.deepBlue,
                child: Text(
                  avatarInitials ??
                      name.substring(0, name.length >= 2 ? 2 : 1).toUpperCase(),
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.darkText,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      city,
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.darkGray,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Static testimonial data
class TestimonialData {
  static const List<Map<String, dynamic>> testimonials = [
    {
      'name': 'María García',
      'city': 'Bogotá, Colombia',
      'quote':
          'El viaje a San Andrés fue absolutamente increíble. Todo organizado a la perfección, desde el hotel hasta los traslados.',
      'rating': 5,
    },
    {
      'name': 'Carlos Rodríguez',
      'city': 'Medellín, Colombia',
      'quote':
          'Viajé a Cancún con mi familia y fue la mejor decisión. Precio justo y servicio impecable. ¡Volveremos!',
      'rating': 5,
    },
    {
      'name': 'Ana Martínez',
      'city': 'Cali, Colombia',
      'quote':
          'Europa Clásica fue un sueño hecho realidad. La organización fue perfecta y los guías muy amables.',
      'rating': 5,
    },
    {
      'name': 'Luis Pérez',
      'city': 'Barranquilla, Colombia',
      'quote':
          'Reservé a través de la app y fue muy fácil. Me contactaron rápido y aclararon todas mis dudas.',
      'rating': 4,
    },
    {
      'name': 'Sofía Torres',
      'city': 'Cartagena, Colombia',
      'quote':
          'Mi viaje de luna de miel fue perfecto gracias a Ruta Épica. Altamente recomendada.',
      'rating': 5,
    },
  ];
}

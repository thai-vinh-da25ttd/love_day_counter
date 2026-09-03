import 'package:flutter/material.dart';

import '../../../models/couple_model.dart';

class CoupleProfile extends StatelessWidget {
  final CoupleMember? me;
  final CoupleMember? partner;
  final VoidCallback onEditMeAvatar;
  final VoidCallback onEditMeNickname;

  const CoupleProfile({
    super.key,
    required this.me,
    required this.partner,
    required this.onEditMeAvatar,
    required this.onEditMeNickname,
  });

  Widget _avatar({
    required CoupleMember? member,
    required VoidCallback? onTap,
  }) {
    final child = member?.avatarUrl.isNotEmpty == true
        ? Image.network(
            member!.avatarUrl,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => const Icon(
              Icons.person,
              size: 48,
              color: Colors.white70,
            ),
          )
        : const Icon(
            Icons.person,
            size: 48,
            color: Colors.white70,
          );

    return GestureDetector(
      onTap: onTap,
      child: CircleAvatar(
        radius: 52,
        backgroundColor: Colors.white.withOpacity(0.18),
        child: ClipOval(
          child: SizedBox(
            width: 104,
            height: 104,
            child: child,
          ),
        ),
      ),
    );
  }

  Widget _name(
    CoupleMember? member, {
    required VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Text(
        member?.nickname.isNotEmpty == true
            ? member!.nickname
            : 'Đang chờ...',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Column(
          children: [
            _avatar(
              member: me,
              onTap: onEditMeAvatar,
            ),
            const SizedBox(height: 10),
            _name(
              me,
              onTap: onEditMeNickname,
            ),
          ],
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 18),
          child: Text(
            '❤️',
            style: TextStyle(fontSize: 28),
          ),
        ),
        Column(
          children: [
            _avatar(
              member: partner,
              onTap: null,
            ),
            const SizedBox(height: 10),
            _name(partner, onTap: null),
          ],
        ),
      ],
    );
  }
}

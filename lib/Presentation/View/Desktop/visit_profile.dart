// lib/presentation/pages/profile_page_desktop.dart
import 'package:dating_app/Data/Models/userinformation_model.dart';
import 'package:dating_app/Core/Theme/colors.dart';
import 'package:flutter/material.dart';

class ProfilePageVisitDesktop extends StatelessWidget {
  final UserinformationModel? user;
  final VoidCallback? onNavigateToMatches;

  const ProfilePageVisitDesktop({
    super.key,
    this.user,
    this.onNavigateToMatches,
  });

  @override
  Widget build(BuildContext context) {
    
    // If no user passed, show placeholder UI
    if (user == null) {
      return Scaffold(
        backgroundColor: kBackgroundColor,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.person_outline_rounded,
                  size: 96,
                  color: charcoal.withOpacity(0.6),
                ),
                const SizedBox(height: 16),
                Text(
                  'Not yet visited any profile',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: charcoal,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'Tap a user\'s profile from the list to view their details here.',
                  style: TextStyle(
                    fontSize: 15,
                    color: kBodyTextColor,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    // optional: trigger a callback if parent provided one
                    onNavigateToMatches?.call();
                    // otherwise simply pop back
                    if (onNavigateToMatches == null) {
                      Navigator.of(context).maybePop();
                    }
                  },
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                    child: Text('Browse Profiles'),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Non-null user => show full profile view
    final u = user!;

    return Scaffold(
      backgroundColor: kBackgroundColor,
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            // Header Section with Profile Image
            _buildProfileHeader(u),

            const SizedBox(height: 32),

            // Personal Details Section
            _buildPersonalDetails(u),

            const SizedBox(height: 32),

            // Bio Section
            _buildBioSection(u),

            const SizedBox(height: 32),

            // Tags/Interests Section
            _buildTagsSection(u),

            const SizedBox(height: 32),

            // Personality & Motivation Section
            _buildPersonalitySection(u),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(UserinformationModel u) {
    return Container(
      height: 320,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            headingViolet.withOpacity(0.85),
            kSecondaryColor.withOpacity(0.4),
          ],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Stack(
        children: [
          // Background decorative elements
          Positioned(
            top: 50,
            right: 30,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: kAccentColor.withOpacity(0.3),
              ),
            ),
          ),
          Positioned(
            bottom: 60,
            left: 20,
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: kPrimaryColor.withOpacity(0.2),
              ),
            ),
          ),

          // Profile content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Profile Avatar with elegant shadow
                Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 4),
                    boxShadow: [
                      BoxShadow(
                        color: charcoal.withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child:
                        u.profilePicture != null && u.profilePicture!.isNotEmpty
                        ? Image.network(
                            u.profilePicture!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _buildDefaultAvatar(),
                          )
                        : _buildDefaultAvatar(),
                  ),
                ),
                const SizedBox(height: 24),

                // Name and Age (safe formatting)
                Text(
                  '${u.name ?? 'No name'}${u.age != null ? ', ${u.age}' : ''}',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 8),

                // Gender
                if (u.gender != null && u.gender!.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withOpacity(0.3)),
                    ),
                    child: Text(
                      u.gender!,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
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

  Widget _buildDefaultAvatar() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            kSecondaryColor.withOpacity(0.8),
            kPrimaryColor.withOpacity(0.6),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Center(
        child: Icon(Icons.person, size: 60, color: Colors.white),
      ),
    );
  }

  Widget _buildPersonalDetails(UserinformationModel user) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          // Section Title
          _buildSectionTitle('Personal Details', kPrimaryColor),
          const SizedBox(height: 24),

          // Details Cards in a responsive grid
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              if (user.age != null)
                _buildDetailCard(
                  icon: Icons.cake_rounded,
                  title: 'Age',
                  value: '${user.age} years',
                  iconColor: kPrimaryColor,
                ),

              if (user.gender != null && user.gender!.isNotEmpty)
                _buildDetailCard(
                  icon: Icons.person_outline_rounded,
                  title: 'Gender',
                  value: user.gender!,
                  iconColor: subtextViolet,
                ),

              _buildDetailCard(
                icon: Icons.psychology_rounded,
                title: 'Personality',
                value: user.personality ?? 'Not specified',
                iconColor: kSecondaryColor,
              ),

              _buildDetailCard(
                icon: Icons.emoji_objects_rounded,
                title: 'Looking For',
                value: user.motivation ?? 'Meaningful connections',
                iconColor: kAccentColor,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBioSection(UserinformationModel user) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('About Me', headingViolet),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: charcoal.withOpacity(0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              children: [
                Icon(
                  Icons.format_quote_rounded,
                  size: 32,
                  color: kPrimaryColor.withOpacity(0.5),
                ),
                const SizedBox(height: 12),
                Text(
                  user.bio?.isNotEmpty == true
                      ? user.bio!
                      : 'No bio available yet. This person prefers to let their personality shine through conversations.',
                  style: TextStyle(
                    fontSize: 16,
                    height: 1.6,
                    color: kBodyTextColor,
                    fontWeight: FontWeight.w400,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTagsSection(UserinformationModel user) {
    final tags = user.tags ?? [];

    if (tags.isEmpty) return const SizedBox();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Interests & Passions', kSecondaryColor),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: charcoal.withOpacity(0.08),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              children: tags.map((tag) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        kPrimaryColor.withOpacity(0.1),
                        kSecondaryColor.withOpacity(0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(
                      color: kPrimaryColor.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    tag,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: kPrimaryColor,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalitySection(UserinformationModel user) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          // Personality Traits
          if (user.personality != null && user.personality!.isNotEmpty)
            Column(
              children: [
                _buildTraitCard(
                  icon: Icons.psychology_rounded,
                  title: 'Personality',
                  description: user.personality!,
                  color: kPrimaryColor,
                ),
                const SizedBox(height: 16),
              ],
            ),

          // Motivation
          if (user.motivation != null && user.motivation!.isNotEmpty)
            Column(
              children: [
                _buildTraitCard(
                  icon: Icons.emoji_objects_rounded,
                  title: 'Motivation',
                  description: user.motivation!,
                  color: kSecondaryColor,
                ),
                const SizedBox(height: 16),
              ],
            ),

          // Frustrations
          if (user.frustration != null && user.frustration!.isNotEmpty)
            _buildTraitCard(
              icon: Icons.mood_rounded,
              title: 'Deal Breakers',
              description: user.frustration!,
              color: kAccentColor,
            ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, Color color) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 24,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: charcoal,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailCard({
    required IconData icon,
    required String title,
    required String value,
    required Color iconColor,
  }) {
    return Container(
      width: 180,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: charcoal.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 28),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: kBodyTextColor,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: charcoal,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTraitCard({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: charcoal.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: charcoal,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    color: kBodyTextColor,
                    height: 1.4,
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

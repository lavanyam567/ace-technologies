import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  static const _services = [
    'Server, laptop installation and troubleshooting',
    'Wi-Fi and WiMAX device handling',
    'Networking solutions with star topology',
    'Router and switch installation, configuration, and troubleshooting',
    'Network designing and structured cabling',
    'Windows Server 2003/2008, Linux, Novell NetWare solutions',
    'Firewall and security solutions',
    'Machine assembling',
    'CCTV configuring and installation',
    'Fire alarm panel routing and configuration',
    'Door access configuration and installation',
  ];

  static const _authorizedBrands = [
    'HP Compaq',
    'Samsung',
    'Acer',
    'Wipro',
    'APC',
    'Canon',
    'Accuvision',
    'Dahua',
    'Hikvision',
    'ESSL',
  ];

  static const _clients = [
    'Arena Multimedia',
    'Avishkar Techno Solutions',
    'AVC Engineering College',
    'AVC College',
    'AVC Polytechnic',
    'Alpha Works Consultancy',
    'Choksi Imaging Limited',
    'Candid Technologies',
    'Clarion',
    'Galaxy Automation Solution',
    'Kalakshetra Foundations',
    'Lalaji Memorial Omega International School',
    'Mazenet Technologies',
    'Micromatic Machine Tools',
    'Mentor Infocomm',
    'Neo Alliance Healthcare',
    'Sify Technologies',
    'Simhass Group Of Companies',
    'Studio Creia',
    'Sun Direct',
    'True Value Homes',
    'Triburg',
    'Twice Digital',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text(
          'About Us',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        children: [
          _buildHero(),
          const SizedBox(height: 18),
          _buildSummaryCards(context),
          const SizedBox(height: 18),
          _SectionCard(
            title: 'Our Objective',
            icon: Icons.flag_outlined,
            child: const Text(
              'Ace Technologies provides one-stop solutions for computer security, infrastructure, and IT requirements. We continuously keep ourselves updated with the latest developments in the information technology market so customers receive modern and reliable solutions.',
              style: _bodyStyle,
            ),
          ),
          const SizedBox(height: 14),
          _SectionCard(
            title: 'Our Philosophy',
            icon: Icons.handshake_outlined,
            child: const Text(
              'Our corporate philosophy is total customer satisfaction. We work in partnership with customers through quality products, dependable services, reliable delivery, quick response, and competitive pricing.',
              style: _bodyStyle,
            ),
          ),
          const SizedBox(height: 14),
          _SectionCard(
            title: 'Capabilities',
            icon: Icons.engineering_outlined,
            child: const Text(
              'We have wide experience in storage, routers, security devices, Wi-Fi, WiMAX, peripherals, desktops, laptops, structured cabling, optical fiber, copper cabling, wireless infrastructure, active networking components, Windows Server infrastructure, ADS, DNS, DHCP, and TELNET server maintenance.',
              style: _bodyStyle,
            ),
          ),
          const SizedBox(height: 14),
          _SectionCard(
            title: 'Services',
            icon: Icons.build_circle_outlined,
            child: _BulletList(items: _services),
          ),
          const SizedBox(height: 14),
          _SectionCard(
            title: 'Authorized For',
            icon: Icons.verified_outlined,
            child: _WrapChips(items: _authorizedBrands),
          ),
          const SizedBox(height: 14),
          _SectionCard(
            title: 'Our Resources',
            icon: Icons.groups_outlined,
            child: const Text(
              'Qualified service engineers with graduate and post-graduate qualifications, trained with strong technical backgrounds and more than 10 years of field experience.',
              style: _bodyStyle,
            ),
          ),
          const SizedBox(height: 14),
          _SectionCard(
            title: 'Clients',
            icon: Icons.business_center_outlined,
            child: _WrapChips(items: _clients),
          ),
          const SizedBox(height: 14),
          _ContactCard(),
        ],
      ),
    );
  }

  Widget _buildHero() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primaryColor, AppTheme.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withValues(alpha: 0.24),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ace Technologies',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'One-stop IT, computer security, networking, structured cabling, CCTV, fire alarm, and access control solutions.',
            style: TextStyle(color: Colors.white, fontSize: 16, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards(BuildContext context) {
    final isWide = MediaQuery.sizeOf(context).width >= 760;
    final cards = [
      _MiniInfoCard(
        icon: Icons.security_outlined,
        title: 'IT & Security',
        subtitle: 'Complete infrastructure solutions',
      ),
      _MiniInfoCard(
        icon: Icons.router_outlined,
        title: 'Networking',
        subtitle: 'Routers, switches, servers, cabling',
      ),
      _MiniInfoCard(
        icon: Icons.support_agent_outlined,
        title: 'Service Team',
        subtitle: 'Qualified technical engineers',
      ),
    ];

    if (isWide) {
      return Row(
        children: cards
            .map(
              (card) => Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: card,
                ),
              ),
            )
            .toList(),
      );
    }

    return Column(
      children: cards
          .map(
            (card) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: card,
            ),
          )
          .toList(),
    );
  }
}

const _bodyStyle = TextStyle(
  color: AppTheme.textSecondary,
  fontSize: 15,
  height: 1.55,
);

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppTheme.primaryColor),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _MiniInfoCard extends StatelessWidget {
  const _MiniInfoCard({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$title. $subtitle',
      container: true,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppTheme.primaryColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BulletList extends StatelessWidget {
  const _BulletList({required this.items});

  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: items
          .map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.check_circle,
                    color: AppTheme.primaryColor,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: Text(item, style: _bodyStyle)),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}

class _WrapChips extends StatelessWidget {
  const _WrapChips({required this.items});

  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: items
          .map(
            (item) => Chip(
              label: Text(item),
              backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.08),
              labelStyle: const TextStyle(color: AppTheme.primaryColor),
              side: BorderSide.none,
            ),
          )
          .toList(),
    );
  }
}

class _ContactCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Contact Us',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 14),
          _ContactRow(icon: Icons.person_outline, text: 'Muralidharan P'),
          _ContactRow(icon: Icons.phone_outlined, text: '9444048910'),
          _ContactRow(
            icon: Icons.location_on_outlined,
            text: 'No 14, RC Church Road, C. Pallavaram, Chennai - 600043',
          ),
        ],
      ),
    );
  }
}

class _ContactRow extends StatelessWidget {
  const _ContactRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: text,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: SelectableText(
                text,
                style: const TextStyle(color: Colors.white, fontSize: 15),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

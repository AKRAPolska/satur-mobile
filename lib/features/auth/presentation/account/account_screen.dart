import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:satur_app/core/theme/satur_colors.dart';
import 'package:satur_app/features/auth/domain/auth_session.dart';
import 'package:satur_app/features/auth/presentation/session_cubit.dart';
import 'package:satur_app/features/catalog/presentation/shared/catalog_bottom_nav.dart';
import 'package:satur_app/features/catalog/presentation/shared/catalog_nav.dart';

class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  Future<void> _logout(BuildContext context) async {
    await context.read<SessionCubit>().clear();
    if (context.mounted) context.go('/welcome');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SaturColors.surface,
      body: BlocBuilder<SessionCubit, AuthSession?>(
        builder: (context, session) {
          return Column(
            children: [
              Expanded(
                child: CustomScrollView(
                  slivers: [
                    const SliverAppBar(
                      pinned: true,
                      backgroundColor: Colors.white,
                      title: Text(
                        'Moje konto',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: SaturColors.onSurface,
                        ),
                      ),
                      centerTitle: true,
                      automaticallyImplyLeading: false,
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate([
                          if (session != null) ...[
                            Text(
                              session.email,
                              style: const TextStyle(
                                fontSize: 14,
                                color: SaturColors.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],
                          _MenuCard(
                            children: [
                              _MenuRow(
                                icon: Icons.home,
                                label: 'Moje konto',
                                active: true,
                                onTap: () {},
                              ),
                              _MenuRow(
                                icon: Icons.person_outline,
                                label: 'Twój profil',
                                onTap: () {},
                              ),
                              _MenuRow(
                                icon: Icons.lock_outline,
                                label: 'Zmień hasło',
                                onTap: () {},
                              ),
                              _MenuRow(
                                icon: Icons.menu_book_outlined,
                                label: 'Książka adresowa',
                                onTap: () {},
                              ),
                              _MenuRow(
                                icon: Icons.local_mall_outlined,
                                label: 'Historia zamówień',
                                onTap: () {},
                              ),
                              _MenuRow(
                                icon: Icons.favorite_border,
                                label: 'Ulubione',
                                onTap: () {},
                              ),
                              _MenuRow(
                                icon: Icons.payments_outlined,
                                label: 'Moje zwroty i reklamacje',
                                onTap: () {},
                                showDivider: false,
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Material(
                            color: SaturColors.error.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(24),
                            child: InkWell(
                              onTap: () => _logout(context),
                              borderRadius: BorderRadius.circular(24),
                              child: const Padding(
                                padding: EdgeInsets.symmetric(vertical: 14),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.logout,
                                      size: 20,
                                      color: SaturColors.error,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      'Wyloguj się',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                        color: SaturColors.error,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          const _VersionFooter(),
                        ]),
                      ),
                    ),
                  ],
                ),
              ),
              CatalogBottomNav(
                active: CatalogTab.konto,
                onTap: (tab) => handleCatalogTabNavigation(context, tab),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _MenuCard extends StatelessWidget {
  const _MenuCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: SaturColors.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(24),
      clipBehavior: Clip.antiAlias,
      child: Column(children: children),
    );
  }
}

class _MenuRow extends StatelessWidget {
  const _MenuRow({
    required this.icon,
    required this.label,
    required this.onTap,
    this.active = false,
    this.showDivider = true,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool active;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          child: Container(
            color: active ? SaturColors.surfaceContainerLow : null,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                if (active)
                  Container(
                    width: 4,
                    height: 24,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: const BoxDecoration(
                      color: SaturColors.primaryContainer,
                      borderRadius: BorderRadius.horizontal(
                        right: Radius.circular(2),
                      ),
                    ),
                  )
                else
                  const SizedBox(width: 12),
                Icon(
                  icon,
                  size: 22,
                  color: active
                      ? SaturColors.primary
                      : SaturColors.onSurfaceVariant,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: active ? 18 : 16,
                      fontWeight: active ? FontWeight.w700 : FontWeight.w400,
                      color:
                          active ? SaturColors.primary : SaturColors.onSurface,
                    ),
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  size: 20,
                  color: active ? SaturColors.primary : SaturColors.outline,
                ),
              ],
            ),
          ),
        ),
        if (showDivider)
          const Divider(height: 1, color: SaturColors.surfaceVariant),
      ],
    );
  }
}

class _VersionFooter extends StatelessWidget {
  const _VersionFooter();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        Text(
          'Satur',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: SaturColors.outline,
          ),
        ),
        SizedBox(height: 4),
        Text(
          'Satur Retail Sp. z o.o. Wszelkie prawa zastrzeżone',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            color: SaturColors.outlineVariant,
          ),
        ),
      ],
    );
  }
}

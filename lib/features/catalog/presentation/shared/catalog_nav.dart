import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:satur_app/features/auth/presentation/session_cubit.dart';
import 'package:satur_app/features/catalog/presentation/shared/catalog_bottom_nav.dart';

void handleCatalogTabNavigation(BuildContext context, CatalogTab tab) {
  switch (tab) {
    case CatalogTab.start:
      break; // hidden in nav for now
    case CatalogTab.oferta:
      context.go('/products');
    case CatalogTab.konto:
      final loggedIn = context.read<SessionCubit>().isAuthenticated;
      context.go(loggedIn ? '/account' : '/login');
    case CatalogTab.ulubione:
    case CatalogTab.koszyk:
      break;
  }
}

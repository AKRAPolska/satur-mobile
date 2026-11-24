import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:satur_app/features/auth/domain/auth_session.dart';
import 'package:satur_app/features/auth/presentation/session_cubit.dart';
import 'package:satur_app/features/cart/presentation/cart_cubit.dart';

/// Resets the cart (drops token + state) when the user logs out (session -> null).
/// Cold-start hydrate (null -> session) and login do nothing.
class CartSessionListener extends StatelessWidget {
  const CartSessionListener({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return BlocListener<SessionCubit, AuthSession?>(
      listenWhen: (previous, current) => previous != null && current == null,
      listener: (context, _) => context.read<CartCubit>().reset(),
      child: child,
    );
  }
}

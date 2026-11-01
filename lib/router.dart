import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tagihan_air/ui/screens/bill_form_screen.dart';
import 'package:tagihan_air/ui/screens/bill_list_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const BillListScreen(),
        routes: [
          GoRoute(
            path: 'bills/new',
            builder: (context, state) => const BillFormScreen(),
          ),
        ],
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});

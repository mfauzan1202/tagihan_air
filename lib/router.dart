import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tagihan_air/ui/screens/bill_detail_screen.dart';
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
          GoRoute(
            path: 'bills/:id',
            redirect: (context, state) => _billId(state) == null ? '/' : null,
            builder: (context, state) =>
                BillDetailScreen(billId: _billId(state)!),
            routes: [
              GoRoute(
                path: 'edit',
                builder: (context, state) =>
                    EditBillScreen(billId: _billId(state)!),
              ),
            ],
          ),
        ],
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});

int? _billId(GoRouterState state) =>
    int.tryParse(state.pathParameters['id'] ?? '');

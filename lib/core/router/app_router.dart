import 'package:go_router/go_router.dart';
import '../../features/home/home_page.dart';
import '../../features/auth/login_page.dart';
import '../../features/auth/signup_page.dart';
import '../../features/dashboard/dashboard_page.dart';
import '../../features/onboarding/hybrid_onboarding_page.dart';
import '../../features/transactions/transactions_page.dart';
import '../../features/transactions/transaction_detail_page.dart';
import '../../features/receipts/upload_receipt_page.dart';
import '../../core/services/supabase_service.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  redirect: (context, state) {
    final isAuthenticated = SupabaseService.isAuthenticated;
    final location = state.matchedLocation;
    final isLoggingIn = location == '/login' || location == '/signup';
    final isHome = location == '/';

    // Hvis ikke innlogget og prøver å gå til noe annet enn login/signup
    if (!isAuthenticated && !isLoggingIn) {
      return '/login';
    }

    // Hvis innlogget og prøver å gå til login/signup, send til dashboard
    if (isAuthenticated && isLoggingIn) {
      return '/dashboard';
    }

    // Hvis innlogget og går til home, send til dashboard
    if (isAuthenticated && isHome) {
      return '/dashboard';
    }

    return null;
  },
  routes: [
    GoRoute(
      path: '/',
      name: 'home',
      builder: (context, state) => const HomePage(),
    ),
    GoRoute(
      path: '/dashboard',
      name: 'dashboard',
      builder: (context, state) => const DashboardPage(),
    ),
    GoRoute(
      path: '/login',
      name: 'login',
      builder: (context, state) => const LoginPage(),
    ),
    GoRoute(
      path: '/signup',
      name: 'signup',
      builder: (context, state) => const SignupPage(),
    ),
    GoRoute(
      path: '/onboarding',
      name: 'onboarding',
      builder: (context, state) => const HybridOnboardingPage(),
    ),
    GoRoute(
      path: '/transactions',
      name: 'transactions',
      builder: (context, state) => const TransactionsPage(),
    ),
    GoRoute(
      path: '/transaction/:id',
      name: 'transaction-detail',
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        return TransactionDetailPage(transactionId: id);
      },
    ),
    GoRoute(
      path: '/upload-receipt',
      name: 'upload-receipt',
      builder: (context, state) => const UploadReceiptPage(),
    ),
  ],
);


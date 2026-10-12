import 'package:go_router/go_router.dart';
import '../../presentation/splash_screen.dart';
import '../../presentation/main_screen.dart';
import '../../presentation/merchant/merchant_main_screen.dart';
import '../../presentation/auth/landing_screen.dart';
import '../../presentation/auth/role_selection_screen.dart';
import '../../presentation/auth/customer_signup_screen.dart';
import '../../presentation/auth/merchant_signup_screen.dart';
import '../../presentation/auth/login_screen.dart';
import '../../presentation/auth/admin_login_screen.dart';
import '../../presentation/categories/category_details_screen.dart';
import '../../presentation/categories/product_merchants_screen.dart';
import '../../presentation/admin/admin_main_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/landing',
      builder: (context, state) => const LandingScreen(),
    ),
    GoRoute(
      path: '/role-selection',
      builder: (context, state) => const RoleSelectionScreen(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/customer-signup',
      builder: (context, state) => const CustomerSignupScreen(),
    ),
    GoRoute(
      path: '/merchant-signup',
      builder: (context, state) => const MerchantSignupScreen(),
    ),
    GoRoute(
      path: '/main',
      builder: (context, state) => const MainScreen(),
    ),
    GoRoute(
      path: '/merchant-main',
      builder: (context, state) => const MerchantMainScreen(),
    ),
    GoRoute(
      path: '/admin-login',
      builder: (context, state) => const AdminLoginScreen(),
    ),
    GoRoute(
      path: '/admin-main',
      builder: (context, state) => const AdminMainScreen(),
    ),
    GoRoute(
      path: '/category/:id',
      builder: (context, state) {
        final categoryId = state.pathParameters['id']!;
        final categoryName = state.extra as String? ?? 'Category';
        return CategoryDetailsScreen(
          categoryId: categoryId,
          categoryName: categoryName,
        );
      },
    ),
    GoRoute(
      path: '/product/:id',
      builder: (context, state) {
        final variantId = state.pathParameters['id']!;
        final productData = state.extra;
        return ProductMerchantsScreen(
          variantId: variantId,
          productData: productData,
        );
      },
    ),
  ],
);

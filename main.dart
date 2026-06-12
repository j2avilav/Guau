import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const GuauGOApp());
}

/* MAIN 1 */

class GuauGOApp extends StatelessWidget {
  const GuauGOApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GuauGO',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF3EDF8),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF7B2CBF),
          primary: const Color(0xFF7B2CBF),
          secondary: const Color(0xFFFF9F1C),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          surfaceTintColor: Colors.transparent,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFE0D7EF)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFE0D7EF)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFF7B2CBF), width: 1.6),
          ),
        ),
      ),
      home: const SplashPage(),
    );
  }
}

/* 2 COLORES */

class AppColors {
  static const purple = Color(0xFF7B2CBF);
  static const purpleDark = Color(0xFF6A1FB1);
  static const purpleSoft = Color(0xFFEDE7F6);
  static const orange = Color(0xFFFF9F1C);
  static const orangeSoft = Color(0xFFFFF1DD);
  static const dark = Color(0xFF333333);
  static const border = Color(0xFFE0D7EF);
  static const bg = Color(0xFFF3EDF8);
}

/* 3 SPLASH PAGE */

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  double _logoOpacity = 0;
  double _logoScale = 0.86;
  bool _showPaw = false;

  @override
  void initState() {
    super.initState();

    Future.delayed(const Duration(milliseconds: 200), () {
      if (!mounted) return;
      setState(() {
        _logoOpacity = 1;
        _logoScale = 1;
      });
    });

    Future.delayed(const Duration(milliseconds: 1800), () {
      if (!mounted) return;
      setState(() {
        _logoOpacity = 0;
        _logoScale = 1.08;
        _showPaw = true;
      });
    });

    Future.delayed(const Duration(milliseconds: 2800), () {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const RootDecisionPage()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.purple,
      body: Stack(
        children: [
          const PawPatternBackground(),
          Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                AnimatedOpacity(
                  opacity: _logoOpacity,
                  duration: const Duration(milliseconds: 700),
                  curve: Curves.easeInOut,
                  child: AnimatedScale(
                    scale: _logoScale,
                    duration: const Duration(milliseconds: 900),
                    curve: Curves.easeOutBack,
                    child: Image.asset(
                      'assets/images/logo_guaugo.png',
                      width: 240,
                      errorBuilder: (context, error, stackTrace) {
                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.pets, size: 90, color: Colors.white),
                            SizedBox(height: 14),
                            Text(
                              'GuauGO',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 34,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
                AnimatedOpacity(
                  opacity: _showPaw ? 1 : 0,
                  duration: const Duration(milliseconds: 600),
                  child: AnimatedScale(
                    scale: _showPaw ? 1 : 0.5,
                    duration: const Duration(milliseconds: 600),
                    curve: Curves.easeOutBack,
                    child: const Icon(
                      Icons.pets,
                      size: 82,
                      color: Colors.white,
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
}

/* rood decision */

class RootDecisionPage extends StatelessWidget {
  const RootDecisionPage({super.key});

  Future<Widget> _resolveHome(User? user) async {
    if (user == null) {
      return const MainNavigationPage();
    }

    final groomerDoc = await FirebaseFirestore.instance
        .collection('banadores')
        .doc(user.uid)
        .get();

    if (groomerDoc.exists) {
      final data = groomerDoc.data()!;
      final estado = data['estado'] ?? 'pendiente_revision';

      if (estado == 'pendiente_revision') {
        return const PendingReviewPage();
      }

      if (estado == 'aprobado') {
        return const MainNavigationPage();
      }

      if (estado == 'rechazado') {
        return const RejectedApplicationPage();
      }
    }

    return const MainNavigationPage();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return FutureBuilder<Widget>(
          future: _resolveHome(authSnapshot.data),
          builder: (context, futureSnapshot) {
            if (futureSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            return futureSnapshot.data ?? const MainNavigationPage();
          },
        );
      },
    );
  }
}

/* pendiente revision*/

class PendingReviewPage extends StatelessWidget {
  const PendingReviewPage({super.key});

  Future<void> _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    if (!context.mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const MainNavigationPage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: _simpleAppBar('Solicitud en revisión'),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 82,
                  height: 82,
                  decoration: BoxDecoration(
                    color: AppColors.purpleSoft,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.hourglass_top_rounded,
                    color: AppColors.purple,
                    size: 44,
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Tu solicitud está en revisión',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: AppColors.dark,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Recibimos tu registro como bañador. Ahora validaremos tus datos y documentos antes de activar tu perfil en GuauGO.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.black54,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 18),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F4FB),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Estado actual',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: AppColors.dark,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        '• Solicitud recibida\n• Validación de datos pendiente\n• Revisión de documentos pendiente',
                        style: TextStyle(
                          color: Colors.black87,
                          height: 1.45,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _logout(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.purple,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'Cerrar sesión',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


/* rechazado */


class RejectedApplicationPage extends StatelessWidget {
  const RejectedApplicationPage({super.key});

  Future<void> _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    if (!context.mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const MainNavigationPage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: _simpleAppBar('Solicitud observada'),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 82,
                  height: 82,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFFF1DD),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.report_gmailerrorred_rounded,
                    color: AppColors.orange,
                    size: 44,
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Tu solicitud necesita revisión',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: AppColors.dark,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Encontramos observaciones en tus datos o documentos. Más adelante podemos agregar un detalle exacto de la observación.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.black54,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _logout(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.orange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'Cerrar sesión',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class PawPatternBackground extends StatelessWidget {
  const PawPatternBackground({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Colors.white.withValues(alpha: 0.08);

    return Stack(
      children: [
        Positioned(
          top: 60,
          left: 24,
          child: Icon(Icons.pets, color: c, size: 26),
        ),
        Positioned(
          top: 90,
          right: 34,
          child: Icon(Icons.pets, color: c, size: 22),
        ),
        Positioned(
          top: 160,
          left: 90,
          child: Icon(Icons.favorite_border, color: c, size: 18),
        ),
        Positioned(
          top: 240,
          right: 72,
          child: Icon(Icons.pets, color: c, size: 28),
        ),
        Positioned(
          top: 330,
          left: 45,
          child: Icon(Icons.pets, color: c, size: 22),
        ),
        Positioned(
          top: 430,
          right: 50,
          child: Icon(Icons.favorite_border, color: c, size: 18),
        ),
        Positioned(
          bottom: 220,
          left: 95,
          child: Icon(Icons.pets, color: c, size: 24),
        ),
        Positioned(
          bottom: 150,
          right: 42,
          child: Icon(Icons.pets, color: c, size: 30),
        ),
        Positioned(
          bottom: 80,
          left: 38,
          child: Icon(Icons.favorite_border, color: c, size: 18),
        ),
      ],
    );
  }
}

/* 4 NAVEGACIÓN PRINCIPAL */

class MainNavigationPage extends StatefulWidget {
  const MainNavigationPage({super.key});

  @override
  State<MainNavigationPage> createState() => _MainNavigationPageState();
}

class _MainNavigationPageState extends State<MainNavigationPage> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      const HomePage(),
      const OrdersPage(),
      const FavoritesPage(),
      const AccountPage(),
    ];

    return Scaffold(
      body: pages[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        backgroundColor: Colors.white,
        indicatorColor: AppColors.purpleSoft,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Inicio',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: 'Pedidos',
          ),
          NavigationDestination(
            icon: Icon(Icons.favorite_border),
            selectedIcon: Icon(Icons.favorite),
            label: 'Favoritos',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Cuenta',
          ),
        ],
      ),
    );
  }
}

/* 5 PÁGINA DE INICIO */

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  void _goToStoresAndServices(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const StoresAndServicesPage()),
    );
  }

  void _goToRegisterType(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const RegisterTypePage()),
    );
  }

  void _goToBath(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const BathBookingPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: RichText(
          text: const TextSpan(
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
            children: [
              TextSpan(
                text: 'Guau',
                style: TextStyle(color: AppColors.purpleDark),
              ),
              TextSpan(
                text: 'GO',
                style: TextStyle(color: AppColors.orange),
              ),
            ],
          ),
        ),
        leading: IconButton(
          onPressed: () {},
          icon: const Icon(Icons.menu, color: AppColors.dark),
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.notifications_none, color: AppColors.dark),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '¿Qué necesitas hoy?',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.dark,
                ),
              ),
              const SizedBox(height: 14),
              ServiceCard(
                color: AppColors.purple,
                title: 'Baño a domicilio',
                subtitle: 'Agendamos y vamos a tu hogar',
                icon: Icons.pets,
                onTap: () => _goToBath(context),
              ),
              const SizedBox(height: 12),
              ServiceCard(
                color: AppColors.orange,
                title: 'Tiendas y servicios',
                subtitle: 'Encuentra tiendas cerca de ti',
                icon: Icons.storefront_outlined,
                onTap: () => _goToStoresAndServices(context),
              ),
              const SizedBox(height: 12),
              ServiceCard(
                color: const Color(0xFFD8C9F1),
                title: 'Mis pedidos',
                subtitle: 'Revisa el estado de tus solicitudes',
                icon: Icons.assignment_outlined,
                titleColor: AppColors.dark,
                subtitleColor: AppColors.dark,
                onTap: () {},
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                        color: AppColors.purpleSoft,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: const Icon(
                        Icons.person_add_alt_1,
                        color: AppColors.purple,
                        size: 30,
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '¿Aún no tienes cuenta?',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: AppColors.dark,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Regístrate para agendar servicios y guardar tus pedidos.',
                            style: TextStyle(
                              fontSize: 13.5,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () => _goToRegisterType(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.purple,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text('Entrar'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Destacados',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.dark,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: MiniFeatureCard(
                      icon: Icons.shield_outlined,
                      title: 'Cuidado\nseguro',
                      color: AppColors.purpleSoft,
                      iconColor: AppColors.purple,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: MiniFeatureCard(
                      icon: Icons.schedule,
                      title: 'Agenda\nfácil',
                      color: AppColors.orangeSoft,
                      iconColor: AppColors.orange,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: MiniFeatureCard(
                      icon: Icons.favorite_outline,
                      title: 'Tus\nfavoritos',
                      color: Colors.white,
                      iconColor: AppColors.dark,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/* 8 WIDGETS REUTILIZABLES */

class ServiceCard extends StatelessWidget {
  final Color color;
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;
  final Color titleColor;
  final Color subtitleColor;

  const ServiceCard({
    super.key,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
    this.titleColor = Colors.white,
    this.subtitleColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 62,
                height: 62,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(icon, color: Colors.white, size: 32),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: titleColor,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: subtitleColor.withValues(alpha: 0.95),
                        fontSize: 13,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.arrow_forward_ios,
                color: titleColor == AppColors.dark
                    ? AppColors.dark
                    : Colors.white,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MiniFeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final Color iconColor;

  const MiniFeatureCard({
    super.key,
    required this.icon,
    required this.title,
    required this.color,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 116,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 28),
          const Spacer(),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: AppColors.dark,
            ),
          ),
        ],
      ),
    );
  }
}

/* 6 PEDIDOS */

class OrdersPage extends StatelessWidget {
  const OrdersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _simpleAppBar('Mis pedidos'),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          InfoTile(
            icon: Icons.schedule_outlined,
            title: 'No tienes pedidos activos',
            subtitle: 'Cuando agendes un servicio aparecerá aquí.',
          ),
          SizedBox(height: 12),
          InfoTile(
            icon: Icons.history,
            title: 'Historial',
            subtitle: 'Aquí verás tus pedidos anteriores y su estado.',
          ),
        ],
      ),
    );
  }
}

class FavoritesPage extends StatelessWidget {
  const FavoritesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _simpleAppBar('Favoritos'),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          InfoTile(
            icon: Icons.favorite_border,
            title: 'Aún no tienes favoritos',
            subtitle: 'Guarda tus servicios o tiendas preferidas.',
          ),
        ],
      ),
    );
  }
}

class AccountPage extends StatelessWidget {
  const AccountPage({super.key});

  void _goToRegisterType(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const RegisterTypePage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _simpleAppBar('Cuenta'),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: AppColors.purpleSoft,
                    child: const Icon(
                      Icons.person,
                      color: AppColors.purple,
                      size: 34,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Bienvenido a GuauGO',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppColors.dark,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Ingresa o regístrate para gestionar tus servicios.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.black54),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => _goToRegisterType(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.purple,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        'Registrarme',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
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

/* 7 REGISTRO TIPO */

class RegisterTypePage extends StatelessWidget {
  const RegisterTypePage({super.key});

  void _goToForm(BuildContext context, String userType) {
    if (userType == 'Cliente') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => RegistrationPage(userType: userType)),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const BusinessRoleSelectionPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _simpleAppBar('Registro'),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            children: [
              const SizedBox(height: 8),
              const Text(
                '¿Cómo quieres registrarte?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: AppColors.dark,
                ),
              ),
              const SizedBox(height: 22),
              _registerOptionCard(
                context: context,
                color: AppColors.purple,
                icon: Icons.person,
                title: 'Soy Cliente',
                subtitle: 'Quiero agendar servicios o comprar productos',
                onTap: () => _goToForm(context, 'Cliente'),
              ),
              const SizedBox(height: 16),
              _registerOptionCard(
                context: context,
                color: AppColors.orange,
                icon: Icons.storefront,
                title: 'Soy Bañador / Tienda',
                subtitle: 'Ofrezco servicios y productos',
                onTap: () => _goToForm(context, 'Bañador / Tienda'),
              ),
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    '¿Ya tengo cuenta? ',
                    style: TextStyle(color: Colors.black54),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Text(
                      'Iniciar sesión',
                      style: TextStyle(
                        color: AppColors.purple,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  Widget _registerOptionCard({
    required BuildContext context,
    required Color color,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                width: 62,
                height: 62,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: Colors.white, size: 30),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                color: Colors.white,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/* 7.0 REGISTRO TIPO NEGOCIO */

class BusinessRoleSelectionPage extends StatelessWidget {
  const BusinessRoleSelectionPage({super.key});

  void _goToGroomer(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const GroomerRegistrationPage()),
    );
  }

  void _goToStore(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const StoreRegistrationPage()),
    );
  }

  Widget _optionCard({
    required Color color,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                width: 62,
                height: 62,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: Colors.white, size: 30),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                color: Colors.white,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _simpleAppBar('Tipo de negocio'),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            children: [
              const SizedBox(height: 8),
              const Text(
                '¿Qué quieres registrar?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: AppColors.dark,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Selecciona si ofrecerás servicios como bañador o si registrarás una tienda.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13.5, color: Colors.black54),
              ),
              const SizedBox(height: 24),
              _optionCard(
                color: AppColors.purple,
                icon: Icons.pets,
                title: 'Soy Bañador',
                subtitle:
                    'Ofrezco baño, corte y servicios a domicilio o por agenda',
                onTap: () => _goToGroomer(context),
              ),
              const SizedBox(height: 16),
              _optionCard(
                color: AppColors.orange,
                icon: Icons.storefront_outlined,
                title: 'Soy Tienda',
                subtitle:
                    'Tengo un local o negocio físico con productos o servicios',
                onTap: () => _goToStore(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/* 7.0.1 REGISTRO BAÑADOR */

class GroomerRegistrationPage extends StatefulWidget {
  const GroomerRegistrationPage({super.key});

  @override
  State<GroomerRegistrationPage> createState() =>
      _GroomerRegistrationPageState();
}

class _GroomerRegistrationPageState extends State<GroomerRegistrationPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _fullNameCtrl = TextEditingController();
  final TextEditingController _phoneCtrl = TextEditingController();
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _passwordCtrl = TextEditingController();
  final TextEditingController _confirmPasswordCtrl = TextEditingController();
  final TextEditingController _communeCtrl = TextEditingController();
  final TextEditingController _coverageCtrl = TextEditingController();
  final TextEditingController _instagramCtrl = TextEditingController();
  final TextEditingController _whatsappCtrl = TextEditingController();
  final TextEditingController _descriptionCtrl = TextEditingController();

  String openTime = '09:00';
  String closeTime = '20:00';

  bool worksAtHome = true;
  bool hasOwnTransport = false;
  bool showInMap = false;

  final List<String> availableTimes = const [
    '08:00',
    '09:00',
    '10:00',
    '11:00',
    '12:00',
    '13:00',
    '14:00',
    '15:00',
    '16:00',
    '17:00',
    '18:00',
    '19:00',
    '20:00',
    '21:00',
  ];

  final Map<String, bool> services = {
    'Baño': true,
    'Corte': false,
    'Deslanado': false,
    'Corte de uñas': false,
    'Limpieza de oídos': false,
    'Perfume': false,
    'Cepillado': false,
  };

  @override
  void dispose() {
    _fullNameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    _communeCtrl.dispose();
    _coverageCtrl.dispose();
    _instagramCtrl.dispose();
    _whatsappCtrl.dispose();
    _descriptionCtrl.dispose();
    super.dispose();
  }

  List<String> get selectedServices {
    return services.entries
        .where((entry) => entry.value)
        .map((entry) => entry.key)
        .toList();
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: AppColors.dark,
          ),
        ),
      ),
    );
  }

  Widget _buildServiceChip(String label) {
    final isSelected = services[label] ?? false;

    return FilterChip(
      selected: isSelected,
      label: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : AppColors.dark,
          fontWeight: FontWeight.w700,
        ),
      ),
      onSelected: (value) {
        setState(() {
          services[label] = value;
        });
      },
      selectedColor: AppColors.purple,
      backgroundColor: Colors.white,
      side: BorderSide(
        color: isSelected ? AppColors.purple : AppColors.border,
      ),
      checkmarkColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (selectedServices.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.redAccent,
          content: Text(
            'Selecciona al menos un servicio 🐾',
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
      return;
    }

    if (_passwordCtrl.text.trim() != _confirmPasswordCtrl.text.trim()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.redAccent,
          content: Text(
            'Las contraseñas no coinciden',
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
      return;
    }

    try {
      final credential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text.trim(),
      );

      final user = credential.user;
      if (user == null) {
        throw Exception('No se pudo crear el usuario en Firebase Auth');
      }

      await FirebaseFirestore.instance.collection('banadores').doc(user.uid).set({
        'uid': user.uid,
        'rol': 'banador',
        'nombreCompleto': _fullNameCtrl.text.trim(),
        'telefono': _phoneCtrl.text.trim(),
        'correo': _emailCtrl.text.trim(),
        'comuna': _communeCtrl.text.trim(),
        'zonaCobertura': _coverageCtrl.text.trim(),
        'servicios': selectedServices,
        'horarioDesde': openTime,
        'horarioHasta': closeTime,
        'trabajaDomicilio': worksAtHome,
        'tieneTransporte': hasOwnTransport,
        'mostrarEnMapa': false,
        'instagram': _instagramCtrl.text.trim(),
        'whatsapp': _whatsappCtrl.text.trim(),
        'descripcion': _descriptionCtrl.text.trim(),

        // ESTADOS IMPORTANTES
        'estado': 'pendiente_revision',
        'documentosEstado': 'pendiente',
        'perfilActivo': false,
        'visibleEnMapa': false,

        'fechaRegistro': DateTime.now(),
      });

      // OPCIONAL: si luego instalas la extensión Trigger Email de Firebase,
      // este bloque te deja listo el correo automático de bienvenida.
      /*
      await FirebaseFirestore.instance.collection('mail').add({
        'to': _emailCtrl.text.trim(),
        'message': {
          'subject': 'Bienvenido a GuauGO 🐾',
          'html': '''
            <h2>Hola ${_fullNameCtrl.text.trim()}</h2>
            <p>Recibimos tu registro como bañador en GuauGO.</p>
            <p>Tu cuenta quedó en estado <b>pendiente de revisión</b>.</p>
            <p>Estaremos validando tus datos y documentos antes de activar tu perfil.</p>
            <p>Gracias por postular 💜</p>
          ''',
        },
      });
      */

      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const PendingReviewPage()),
        (route) => false,
      );
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'Ocurrió un error al crear la cuenta';

      if (e.code == 'email-already-in-use') {
        errorMessage = 'Ese correo ya está registrado';
      } else if (e.code == 'weak-password') {
        errorMessage = 'La contraseña es muy débil';
      } else if (e.code == 'invalid-email') {
        errorMessage = 'El correo no es válido';
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.redAccent,
          content: Text(
            errorMessage,
            style: const TextStyle(color: Colors.white),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.redAccent,
          content: Text(
            'Error al guardar: $e',
            style: const TextStyle(color: Colors.white),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _simpleAppBar('Registro de bañador 🐶'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: const Color(0xFFF8F4FB),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppColors.border),
          ),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const Text(
                  'Registro para bañadores',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppColors.dark,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Crea tu cuenta y postula tus servicios en GuauGO',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.black54,
                    fontSize: 13.5,
                  ),
                ),
                const SizedBox(height: 24),

                _buildSectionTitle('Datos personales'),

                TextFormField(
                  controller: _fullNameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Nombre completo',
                    hintText: 'Ej. Juan Pérez',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Ingresa tu nombre';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                TextFormField(
                  controller: _phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Teléfono',
                    hintText: 'Ej. +56 9 1234 5678',
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Ingresa un teléfono';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                TextFormField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Correo electrónico',
                    hintText: 'Ej. banador@email.com',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Ingresa un correo';
                    }
                    if (!value.contains('@')) {
                      return 'Ingresa un correo válido';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                TextFormField(
                  controller: _passwordCtrl,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Contraseña',
                    hintText: 'Mínimo 6 caracteres',
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Ingresa una contraseña';
                    }
                    if (value.trim().length < 6) {
                      return 'La contraseña debe tener al menos 6 caracteres';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                TextFormField(
                  controller: _confirmPasswordCtrl,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Confirmar contraseña',
                    hintText: 'Repite tu contraseña',
                    prefixIcon: Icon(Icons.lock_reset_outlined),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Confirma tu contraseña';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 24),

                _buildSectionTitle('Cobertura'),

                TextFormField(
                  controller: _communeCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Comuna base',
                    hintText: 'Ej. Macul',
                    prefixIcon: Icon(Icons.map_outlined),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Ingresa tu comuna';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                TextFormField(
                  controller: _coverageCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Zona de cobertura',
                    hintText: 'Ej. Macul, Ñuñoa, La Florida',
                    prefixIcon: Icon(Icons.location_on_outlined),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Ingresa tu zona de cobertura';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 24),

                _buildSectionTitle('Servicios ofrecidos'),

                Align(
                  alignment: Alignment.centerLeft,
                  child: Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: services.keys.map(_buildServiceChip).toList(),
                  ),
                ),

                const SizedBox(height: 24),

                _buildSectionTitle('Horario disponible'),

                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: openTime,
                        decoration: const InputDecoration(
                          labelText: 'Desde',
                          prefixIcon: Icon(Icons.schedule),
                        ),
                        items: availableTimes
                            .map(
                              (time) =>
                                  DropdownMenuItem(value: time, child: Text(time)),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              openTime = value;
                            });
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: closeTime,
                        decoration: const InputDecoration(
                          labelText: 'Hasta',
                          prefixIcon: Icon(Icons.lock_clock),
                        ),
                        items: availableTimes
                            .map(
                              (time) =>
                                  DropdownMenuItem(value: time, child: Text(time)),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              closeTime = value;
                            });
                          }
                        },
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                _buildSectionTitle('Contacto y redes'),

                TextFormField(
                  controller: _instagramCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Instagram',
                    hintText: 'Ej. @banador.pet',
                    prefixIcon: Icon(Icons.camera_alt_outlined),
                  ),
                ),
                const SizedBox(height: 14),

                TextFormField(
                  controller: _whatsappCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'WhatsApp',
                    hintText: 'Ej. +56 9 1234 5678',
                    prefixIcon: Icon(Icons.chat_outlined),
                  ),
                ),
                const SizedBox(height: 14),

                TextFormField(
                  controller: _descriptionCtrl,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Descripción',
                    hintText:
                        'Cuéntanos brevemente sobre tu experiencia, estilo de trabajo o especialidad.',
                    alignLabelWithHint: true,
                    prefixIcon: Icon(Icons.description_outlined),
                  ),
                ),

                const SizedBox(height: 24),

                _buildSectionTitle('Configuración'),

                SwitchListTile(
                  value: worksAtHome,
                  activeThumbColor: AppColors.purple,
                  contentPadding: EdgeInsets.zero,
                  title: const Text(
                    'Trabajo a domicilio',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: const Text(
                    'Indica si ofreces servicio móvil en la dirección del cliente.',
                  ),
                  onChanged: (value) {
                    setState(() {
                      worksAtHome = value;
                    });
                  },
                ),

                SwitchListTile(
                  value: hasOwnTransport,
                  activeThumbColor: AppColors.purple,
                  contentPadding: EdgeInsets.zero,
                  title: const Text(
                    'Tengo transporte propio',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: const Text(
                    'Esto ayuda a mostrar disponibilidad de movilidad.',
                  ),
                  onChanged: (value) {
                    setState(() {
                      hasOwnTransport = value;
                    });
                  },
                ),

                SwitchListTile(
                  value: showInMap,
                  activeThumbColor: AppColors.purple,
                  contentPadding: EdgeInsets.zero,
                  title: const Text(
                    'Quiero aparecer en el mapa cuando me aprueben',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: const Text(
                    'La visibilidad real quedará sujeta a aprobación.',
                  ),
                  onChanged: (value) {
                    setState(() {
                      showInMap = value;
                    });
                  },
                ),

                const SizedBox(height: 24),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Resumen rápido',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: AppColors.dark,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Servicios: ${selectedServices.isEmpty ? 'Ninguno' : selectedServices.join(', ')}',
                        style: const TextStyle(color: Colors.black87),
                      ),
                      Text(
                        'Horario: $openTime a $closeTime',
                        style: const TextStyle(color: Colors.black87),
                      ),
                      Text(
                        'A domicilio: ${worksAtHome ? 'Sí' : 'No'}',
                        style: const TextStyle(color: Colors.black87),
                      ),
                      const Text(
                        'Estado inicial: pendiente de revisión',
                        style: TextStyle(color: Colors.black87),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 26),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.purple,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 17),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'Crear cuenta y enviar solicitud',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

  final _formKey = GlobalKey<FormState>();

  final TextEditingController _fullNameCtrl = TextEditingController();
  final TextEditingController _phoneCtrl = TextEditingController();
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _communeCtrl = TextEditingController();
  final TextEditingController _coverageCtrl = TextEditingController();
  final TextEditingController _instagramCtrl = TextEditingController();
  final TextEditingController _whatsappCtrl = TextEditingController();
  final TextEditingController _descriptionCtrl = TextEditingController();

  String openTime = '09:00';
  String closeTime = '20:00';

  bool worksAtHome = true;
  bool hasOwnTransport = false;
  bool showInMap = true;

  final List<String> availableTimes = const [
    '08:00',
    '09:00',
    '10:00',
    '11:00',
    '12:00',
    '13:00',
    '14:00',
    '15:00',
    '16:00',
    '17:00',
    '18:00',
    '19:00',
    '20:00',
    '21:00',
  ];

  final Map<String, bool> services = {
    'Baño': true,
    'Corte': false,
    'Deslanado': false,
    'Corte de uñas': false,
    'Limpieza de oídos': false,
    'Perfume': false,
    'Cepillado': false,
  };

  @override
  void dispose() {
    _fullNameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _communeCtrl.dispose();
    _coverageCtrl.dispose();
    _instagramCtrl.dispose();
    _whatsappCtrl.dispose();
    _descriptionCtrl.dispose();
    super.dispose();
  }

  List<String> get selectedServices {
    return services.entries
        .where((entry) => entry.value)
        .map((entry) => entry.key)
        .toList();
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (selectedServices.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.redAccent,
          content: Text(
            'Selecciona al menos un servicio 🐾',
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
      return;
    }

    try {
      await FirebaseFirestore.instance.collection('banadores').add({
        'nombreCompleto': _fullNameCtrl.text,
        'telefono': _phoneCtrl.text,
        'correo': _emailCtrl.text,
        'comuna': _communeCtrl.text,
        'zonaCobertura': _coverageCtrl.text,
        'servicios': selectedServices,
        'horarioDesde': openTime,
        'horarioHasta': closeTime,
        'trabajaDomicilio': worksAtHome,
        'tieneTransporte': hasOwnTransport,
        'mostrarEnMapa': showInMap,
        'instagram': _instagramCtrl.text,
        'whatsapp': _whatsappCtrl.text,
        'descripcion': _descriptionCtrl.text,
        'estado': 'pendiente',
        'fechaRegistro': DateTime.now(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.green,
          content: Text('Solicitud enviada ✅'),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(backgroundColor: Colors.red, content: Text('Error: $e')),
      );
    }
  }

  Widget _buildServiceChip(String label) {
    final isSelected = services[label] ?? false;

    return FilterChip(
      selected: isSelected,
      label: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : AppColors.dark,
          fontWeight: FontWeight.w700,
        ),
      ),
      onSelected: (value) {
        setState(() {
          services[label] = value;
        });
      },
      selectedColor: AppColors.purple,
      backgroundColor: Colors.white,
      side: BorderSide(color: isSelected ? AppColors.purple : AppColors.border),
      checkmarkColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: AppColors.dark,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _simpleAppBar('Registro de bañador 🐶'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: const Color(0xFFF8F4FB),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppColors.border),
          ),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const Text(
                  'Registro para bañadores',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppColors.dark,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Completa la información para postular tus servicios en GuauGO',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.black54, fontSize: 13.5),
                ),
                const SizedBox(height: 24),

                _buildSectionTitle('Datos personales'),

                TextFormField(
                  controller: _fullNameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Nombre completo',
                    hintText: 'Ej. Juan Pérez',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Ingresa tu nombre';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                TextFormField(
                  controller: _phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Teléfono',
                    hintText: 'Ej. +56 9 1234 5678',
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Ingresa un teléfono';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                TextFormField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Correo electrónico',
                    hintText: 'Ej. banador@email.com',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Ingresa un correo';
                    }
                    if (!value.contains('@')) {
                      return 'Ingresa un correo válido';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 24),

                _buildSectionTitle('Cobertura'),

                TextFormField(
                  controller: _communeCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Comuna base',
                    hintText: 'Ej. Macul',
                    prefixIcon: Icon(Icons.map_outlined),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Ingresa tu comuna';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                TextFormField(
                  controller: _coverageCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Zona de cobertura',
                    hintText: 'Ej. Macul, Ñuñoa, La Florida',
                    prefixIcon: Icon(Icons.location_on_outlined),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Ingresa tu zona de cobertura';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 24),

                _buildSectionTitle('Servicios ofrecidos'),

                Align(
                  alignment: Alignment.centerLeft,
                  child: Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: services.keys.map(_buildServiceChip).toList(),
                  ),
                ),

                const SizedBox(height: 24),

                _buildSectionTitle('Horario disponible'),

                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: openTime,
                        decoration: const InputDecoration(
                          labelText: 'Desde',
                          prefixIcon: Icon(Icons.schedule),
                        ),
                        items: availableTimes
                            .map(
                              (time) => DropdownMenuItem(
                                value: time,
                                child: Text(time),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              openTime = value;
                            });
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: closeTime,
                        decoration: const InputDecoration(
                          labelText: 'Hasta',
                          prefixIcon: Icon(Icons.lock_clock),
                        ),
                        items: availableTimes
                            .map(
                              (time) => DropdownMenuItem(
                                value: time,
                                child: Text(time),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              closeTime = value;
                            });
                          }
                        },
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                _buildSectionTitle('Contacto y redes'),

                TextFormField(
                  controller: _instagramCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Instagram',
                    hintText: 'Ej. @banador.pet',
                    prefixIcon: Icon(Icons.camera_alt_outlined),
                  ),
                ),
                const SizedBox(height: 14),

                TextFormField(
                  controller: _whatsappCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'WhatsApp',
                    hintText: 'Ej. +56 9 1234 5678',
                    prefixIcon: Icon(Icons.chat_outlined),
                  ),
                ),
                const SizedBox(height: 14),

                TextFormField(
                  controller: _descriptionCtrl,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Descripción',
                    hintText:
                        'Cuéntanos brevemente sobre tu experiencia, estilo de trabajo o especialidad.',
                    alignLabelWithHint: true,
                    prefixIcon: Icon(Icons.description_outlined),
                  ),
                ),

                const SizedBox(height: 24),

                _buildSectionTitle('Configuración'),

                SwitchListTile(
                  value: worksAtHome,
                  activeThumbColor: AppColors.purple,
                  contentPadding: EdgeInsets.zero,
                  title: const Text(
                    'Trabajo a domicilio',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: const Text(
                    'Indica si ofreces servicio móvil en la dirección del cliente.',
                  ),
                  onChanged: (value) {
                    setState(() {
                      worksAtHome = value;
                    });
                  },
                ),

                SwitchListTile(
                  value: hasOwnTransport,
                  activeThumbColor: AppColors.purple,
                  contentPadding: EdgeInsets.zero,
                  title: const Text(
                    'Tengo transporte propio',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: const Text(
                    'Esto ayuda a mostrar disponibilidad de movilidad.',
                  ),
                  onChanged: (value) {
                    setState(() {
                      hasOwnTransport = value;
                    });
                  },
                ),

                SwitchListTile(
                  value: showInMap,
                  activeThumbColor: AppColors.purple,
                  contentPadding: EdgeInsets.zero,
                  title: const Text(
                    'Mostrar en el mapa',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: const Text(
                    'Si está activo, podrás aparecer como punto/servicio dentro del mapa.',
                  ),
                  onChanged: (value) {
                    setState(() {
                      showInMap = value;
                    });
                  },
                ),

                const SizedBox(height: 24),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Resumen rápido',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: AppColors.dark,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Servicios: ${selectedServices.isEmpty ? 'Ninguno' : selectedServices.join(', ')}',
                        style: const TextStyle(color: Colors.black87),
                      ),
                      Text(
                        'Horario: $openTime a $closeTime',
                        style: const TextStyle(color: Colors.black87),
                      ),
                      Text(
                        'A domicilio: ${worksAtHome ? 'Sí' : 'No'}',
                        style: const TextStyle(color: Colors.black87),
                      ),
                      Text(
                        'Mapa: ${showInMap ? 'Visible' : 'Oculto'}',
                        style: const TextStyle(color: Colors.black87),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 26),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.purple,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 17),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'Enviar solicitud',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/* 7.1 REGISTRO CLIENTE */

class RegistrationPage extends StatefulWidget {
  final String userType;

  const RegistrationPage({super.key, required this.userType});

  @override
  State<RegistrationPage> createState() => _RegistrationPageState();
}

class _RegistrationPageState extends State<RegistrationPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _phoneCtrl = TextEditingController();

  late String selectedUserType;

  @override
  void initState() {
    super.initState();
    selectedUserType = widget.userType;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.purple,
          content: Text(
            'Registro enviado como $selectedUserType ✅',
            style: const TextStyle(color: Colors.white),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _simpleAppBar('Registro'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const Text(
                'Registro',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  color: AppColors.dark,
                ),
              ),
              const SizedBox(height: 22),
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Nombre completo',
                  hintText: 'Ej. Juan Pérez',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Ingresa tu nombre';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  hintText: 'Ej. juan@email.com',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Ingresa tu email';
                  }
                  if (!value.contains('@')) {
                    return 'Ingresa un email válido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Teléfono',
                  hintText: 'Ej. +569 1234 5678',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Ingresa tu teléfono';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                initialValue: selectedUserType,
                decoration: const InputDecoration(labelText: 'Tipo de usuario'),
                items: const [
                  DropdownMenuItem(value: 'Cliente', child: Text('Cliente')),
                  DropdownMenuItem(
                    value: 'Bañador / Tienda',
                    child: Text('Bañador / Tienda'),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      selectedUserType = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.purple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 17),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'Registrarse',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Al registrarte aceptas nuestros',
                style: TextStyle(color: Colors.black54),
              ),
              const SizedBox(height: 4),
              const Text(
                'Términos y Condiciones',
                style: TextStyle(
                  color: AppColors.purple,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/* INICIO DE AGENDAMIENTO DE BAÑO */

class BathBookingPage extends StatefulWidget {
  const BathBookingPage({super.key});

  @override
  State<BathBookingPage> createState() => _BathBookingPageState();
}

class _BathBookingPageState extends State<BathBookingPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _addressCtrl = TextEditingController();

  String petType = 'Perro';
  String petSize = 'Mediano';
  String serviceType = 'Baño';

  DateTime? selectedDate;
  String? selectedTime;

  final List<String> timeSlots = const [
    '09:00',
    '11:00',
    '13:00',
    '15:00',
    '17:00',
    '19:00',
  ];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? today,
      firstDate: today,
      lastDate: DateTime(now.year + 1),
      helpText: 'Selecciona una fecha',
      cancelText: 'Cancelar',
      confirmText: 'Elegir',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.purple,
              onPrimary: Colors.white,
              onSurface: AppColors.dark,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Selecciona una fecha';

    const weekdays = [
      'Lunes',
      'Martes',
      'Miércoles',
      'Jueves',
      'Viernes',
      'Sábado',
      'Domingo',
    ];

    const months = [
      'enero',
      'febrero',
      'marzo',
      'abril',
      'mayo',
      'junio',
      'julio',
      'agosto',
      'septiembre',
      'octubre',
      'noviembre',
      'diciembre',
    ];

    final weekday = weekdays[date.weekday - 1];
    final month = months[date.month - 1];

    return '$weekday ${date.day} de $month de ${date.year}';
  }

  String _resumeDateTime() {
    if (selectedDate == null || selectedTime == null) return '';
    return '${_formatDate(selectedDate)} • $selectedTime';
  }

  void _sendRequest() {
    if (!_formKey.currentState!.validate()) return;

    if (selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.redAccent,
          content: Text(
            'Debes seleccionar una fecha 📅',
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
      return;
    }

    if (selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.redAccent,
          content: Text(
            'Debes seleccionar un horario ⏰',
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.purple,
        content: Text(
          'Solicitud enviada ✅\n${_resumeDateTime()}',
          style: const TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildTimeChip(String time) {
    final isSelected = selectedTime == time;

    return ChoiceChip(
      label: Text(
        time,
        style: TextStyle(
          color: isSelected ? Colors.white : AppColors.dark,
          fontWeight: FontWeight.w700,
        ),
      ),
      selected: isSelected,
      onSelected: (_) {
        setState(() {
          selectedTime = time;
        });
      },
      selectedColor: AppColors.purple,
      backgroundColor: Colors.white,
      side: BorderSide(color: isSelected ? AppColors.purple : AppColors.border),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      showCheckmark: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _simpleAppBar('Agendar baño 🐶'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: const Color(0xFFF8F4FB),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppColors.border),
          ),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const Text(
                  'Formulario de agendamiento',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.dark,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Disponible de lunes a domingo, cada 2 horas',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.black54, fontSize: 13.5),
                ),
                const SizedBox(height: 22),

                TextFormField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Nombre',
                    hintText: 'Ej. Juan Pérez',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Ingresa un nombre';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                TextFormField(
                  controller: _addressCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Dirección',
                    hintText: 'Ej. Av. Macul 3927',
                    prefixIcon: Icon(Icons.location_on_outlined),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Ingresa una dirección';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                DropdownButtonFormField<String>(
                  initialValue: petType,
                  decoration: const InputDecoration(
                    labelText: 'Tipo de mascota',
                    prefixIcon: Icon(Icons.pets),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'Perro', child: Text('Perro')),
                    DropdownMenuItem(value: 'Gato', child: Text('Gato')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => petType = value);
                    }
                  },
                ),
                const SizedBox(height: 14),

                DropdownButtonFormField<String>(
                  initialValue: petSize,
                  decoration: const InputDecoration(
                    labelText: 'Tamaño',
                    prefixIcon: Icon(Icons.straighten),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'Pequeño', child: Text('Pequeño')),
                    DropdownMenuItem(value: 'Mediano', child: Text('Mediano')),
                    DropdownMenuItem(value: 'Grande', child: Text('Grande')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => petSize = value);
                    }
                  },
                ),
                const SizedBox(height: 14),

                DropdownButtonFormField<String>(
                  initialValue: serviceType,
                  decoration: const InputDecoration(
                    labelText: 'Servicio',
                    prefixIcon: Icon(Icons.content_cut),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'Baño', child: Text('Baño')),
                    DropdownMenuItem(value: 'Corte', child: Text('Corte')),
                    DropdownMenuItem(
                      value: 'Baño + Corte',
                      child: Text('Baño + Corte'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => serviceType = value);
                    }
                  },
                ),
                const SizedBox(height: 18),

                Align(
                  alignment: Alignment.centerLeft,
                  child: const Text(
                    'Fecha',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppColors.dark,
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                InkWell(
                  onTap: _pickDate,
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 18,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.calendar_month_outlined,
                          color: AppColors.purple,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _formatDate(selectedDate),
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: selectedDate == null
                                  ? Colors.black45
                                  : AppColors.dark,
                            ),
                          ),
                        ),
                        const Icon(Icons.expand_more, color: Colors.black45),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 18),

                Align(
                  alignment: Alignment.centerLeft,
                  child: const Text(
                    'Horarios disponibles',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppColors.dark,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Lunes a domingo • bloques cada 2 horas',
                    style: TextStyle(color: Colors.black54, fontSize: 13),
                  ),
                ),
                const SizedBox(height: 12),

                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: timeSlots.map(_buildTimeChip).toList(),
                ),

                const SizedBox(height: 20),

                if (selectedDate != null || selectedTime != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.event_available,
                          color: AppColors.purple,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            selectedDate != null && selectedTime != null
                                ? _resumeDateTime()
                                : 'Completa fecha y horario',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: AppColors.dark,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _sendRequest,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.purple,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'Enviar solicitud',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/* TIENDAS Y SERVICIOS */

class StoresAndServicesPage extends StatelessWidget {
  const StoresAndServicesPage({super.key});

  void _goToRegisterType(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const RegisterTypePage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _simpleAppBar('Tiendas y servicios 🗺️'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tiendas y servicios',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: AppColors.dark,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Explora negocios, servicios y futuras funciones dentro de GuauGO.',
              style: TextStyle(fontSize: 13.5, color: Colors.black54),
            ),
            const SizedBox(height: 18),

            Container(
              width: double.infinity,
              height: 220,
              decoration: BoxDecoration(
                color: const Color(0xFFEDE7F6),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.border),
              ),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: Container(color: const Color(0xFFEDE7F6)),
                    ),
                  ),
                  const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.map_outlined,
                          size: 54,
                          color: AppColors.purple,
                        ),
                        SizedBox(height: 10),
                        Text(
                          'Mapa en desarrollo',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppColors.dark,
                          ),
                        ),
                        SizedBox(height: 6),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 24),
                          child: Text(
                            'Aquí se mostrarán las tiendas registradas con ubicación.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.black54,
                              fontSize: 13.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 22),

            const Text(
              'Servicios disponibles',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.dark,
              ),
            ),
            const SizedBox(height: 12),

            const InfoTile(
              icon: Icons.storefront_outlined,
              title: 'Tiendas cercanas',
              subtitle: 'Pronto podrás ver negocios pet cerca de tu ubicación.',
            ),
            const SizedBox(height: 12),

            const InfoTile(
              icon: Icons.content_cut,
              title: 'Peluquería y baño',
              subtitle: 'Encuentra servicios especializados para tu mascota.',
            ),
            const SizedBox(height: 12),

            const InfoTile(
              icon: Icons.local_hospital_outlined,
              title: 'Veterinaria',
              subtitle:
                  'Consulta opciones de atención y servicios veterinarios.',
            ),

            const SizedBox(height: 22),

            const Text(
              'Próximamente',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.dark,
              ),
            ),
            const SizedBox(height: 12),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      color: AppColors.orangeSoft,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Icon(
                      Icons.construction_outlined,
                      color: AppColors.orange,
                      size: 30,
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Nuevo servicio en construcción 🚧',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppColors.dark,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Muy pronto agregaremos nuevas funciones para ampliar GuauGO.',
                          style: TextStyle(
                            fontSize: 13.5,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _goToRegisterType(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.purple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                icon: const Icon(Icons.store_mall_directory_outlined),
                label: const Text(
                  'Registrar mi negocio',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/* REGISTRO DE BAÑADORES / TIENDAS */

class StoreRegistrationPage extends StatefulWidget {
  const StoreRegistrationPage({super.key});

  @override
  State<StoreRegistrationPage> createState() => _StoreRegistrationPageState();
}

class _StoreRegistrationPageState extends State<StoreRegistrationPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _storeNameCtrl = TextEditingController();
  final TextEditingController _ownerNameCtrl = TextEditingController();
  final TextEditingController _phoneCtrl = TextEditingController();
  final TextEditingController _emailCtrl = TextEditingController();

  final TextEditingController _addressCtrl = TextEditingController();
  final TextEditingController _districtCtrl = TextEditingController();
  final TextEditingController _regionCtrl = TextEditingController();
  final TextEditingController _referenceCtrl = TextEditingController();

  final TextEditingController _instagramCtrl = TextEditingController();
  final TextEditingController _whatsappCtrl = TextEditingController();
  final TextEditingController _descriptionCtrl = TextEditingController();

  String businessType = 'Tienda de mascotas';
  String openTime = '09:00';
  String closeTime = '20:00';

  bool isActive = true;
  bool showInMap = true;

  final List<String> businessTypes = const [
    'Tienda de mascotas',
    'Peluquería canina',
    'Veterinaria',
    'Pet shop',
    'Otro',
  ];

  final List<String> availableTimes = const [
    '08:00',
    '09:00',
    '10:00',
    '11:00',
    '12:00',
    '13:00',
    '14:00',
    '15:00',
    '16:00',
    '17:00',
    '18:00',
    '19:00',
    '20:00',
    '21:00',
  ];

  final Map<String, bool> services = {
    'Baño': true,
    'Corte': false,
    'Accesorios': false,
    'Alimento': false,
    'Consulta': false,
    'Paseo': false,
    'Guardería': false,
  };

  @override
  void dispose() {
    _storeNameCtrl.dispose();
    _ownerNameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _addressCtrl.dispose();
    _districtCtrl.dispose();
    _regionCtrl.dispose();
    _referenceCtrl.dispose();
    _instagramCtrl.dispose();
    _whatsappCtrl.dispose();
    _descriptionCtrl.dispose();
    super.dispose();
  }

  List<String> get selectedServices {
    return services.entries
        .where((entry) => entry.value)
        .map((entry) => entry.key)
        .toList();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    if (selectedServices.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.redAccent,
          content: Text(
            'Selecciona al menos un servicio 🐾',
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
      return;
    }

    final summary =
        '''
Negocio: ${_storeNameCtrl.text}
Responsable: ${_ownerNameCtrl.text}
Tipo: $businessType
Servicios: ${selectedServices.join(', ')}
Dirección: ${_addressCtrl.text}
Comuna: ${_districtCtrl.text}
Horario: $openTime - $closeTime
Visible en mapa: ${showInMap ? 'Sí' : 'No'}
''';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.purple,
        content: Text(
          'Solicitud enviada con éxito ✅\n$summary',
          style: const TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: AppColors.dark,
          ),
        ),
      ),
    );
  }

  Widget _buildServiceChip(String label) {
    final isSelected = services[label] ?? false;

    return FilterChip(
      selected: isSelected,
      label: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : AppColors.dark,
          fontWeight: FontWeight.w700,
        ),
      ),
      onSelected: (value) {
        setState(() {
          services[label] = value;
        });
      },
      selectedColor: AppColors.purple,
      backgroundColor: Colors.white,
      side: BorderSide(color: isSelected ? AppColors.purple : AppColors.border),
      checkmarkColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _simpleAppBar('Registro de tiendas 🏪'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: const Color(0xFFF8F4FB),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppColors.border),
          ),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const Text(
                  'Registro para bañadores o tiendas',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppColors.dark,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Completa la información para postular tu tienda en GuauGO',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.black54, fontSize: 13.5),
                ),
                const SizedBox(height: 24),

                _buildSectionTitle('Datos del negocio'),

                TextFormField(
                  controller: _storeNameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Nombre de la tienda',
                    hintText: 'Ej. Peluditos Spa',
                    prefixIcon: Icon(Icons.storefront_outlined),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Ingresa el nombre de la tienda';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                TextFormField(
                  controller: _ownerNameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Responsable',
                    hintText: 'Ej. Juan Pérez',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Ingresa el nombre del responsable';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                TextFormField(
                  controller: _phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Teléfono',
                    hintText: 'Ej. +56 9 1234 5678',
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Ingresa un teléfono';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                TextFormField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Correo electrónico',
                    hintText: 'Ej. tienda@email.com',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Ingresa un correo';
                    }
                    if (!value.contains('@')) {
                      return 'Ingresa un correo válido';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                DropdownButtonFormField<String>(
                  initialValue: businessType,
                  decoration: const InputDecoration(
                    labelText: 'Tipo de negocio',
                    prefixIcon: Icon(Icons.category_outlined),
                  ),
                  items: businessTypes
                      .map(
                        (type) =>
                            DropdownMenuItem(value: type, child: Text(type)),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        businessType = value;
                      });
                    }
                  },
                ),

                const SizedBox(height: 24),

                _buildSectionTitle('Ubicación'),

                TextFormField(
                  controller: _addressCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Dirección',
                    hintText: 'Ej. Av. Macul 3927',
                    prefixIcon: Icon(Icons.location_on_outlined),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Ingresa una dirección';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                TextFormField(
                  controller: _districtCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Comuna',
                    hintText: 'Ej. Macul',
                    prefixIcon: Icon(Icons.map_outlined),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Ingresa la comuna';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                TextFormField(
                  controller: _regionCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Región',
                    hintText: 'Ej. Metropolitana',
                    prefixIcon: Icon(Icons.public_outlined),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Ingresa la región';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                TextFormField(
                  controller: _referenceCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Referencia',
                    hintText: 'Ej. Frente al metro / local esquina',
                    prefixIcon: Icon(Icons.place_outlined),
                  ),
                ),

                const SizedBox(height: 24),

                _buildSectionTitle('Servicios ofrecidos'),

                Align(
                  alignment: Alignment.centerLeft,
                  child: Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: services.keys.map(_buildServiceChip).toList(),
                  ),
                ),

                const SizedBox(height: 24),

                _buildSectionTitle('Horario de atención'),

                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: openTime,
                        decoration: const InputDecoration(
                          labelText: 'Apertura',
                          prefixIcon: Icon(Icons.schedule),
                        ),
                        items: availableTimes
                            .map(
                              (time) => DropdownMenuItem(
                                value: time,
                                child: Text(time),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              openTime = value;
                            });
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: closeTime,
                        decoration: const InputDecoration(
                          labelText: 'Cierre',
                          prefixIcon: Icon(Icons.lock_clock),
                        ),
                        items: availableTimes
                            .map(
                              (time) => DropdownMenuItem(
                                value: time,
                                child: Text(time),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              closeTime = value;
                            });
                          }
                        },
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Por ahora este horario aplicará de lunes a domingo.',
                    style: TextStyle(color: Colors.black54, fontSize: 13),
                  ),
                ),

                const SizedBox(height: 24),

                _buildSectionTitle('Contacto y redes'),

                TextFormField(
                  controller: _instagramCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Instagram',
                    hintText: 'Ej. @guaugo.cl',
                    prefixIcon: Icon(Icons.camera_alt_outlined),
                  ),
                ),
                const SizedBox(height: 14),

                TextFormField(
                  controller: _whatsappCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'WhatsApp',
                    hintText: 'Ej. +56 9 1234 5678',
                    prefixIcon: Icon(Icons.chat_outlined),
                  ),
                ),
                const SizedBox(height: 14),

                TextFormField(
                  controller: _descriptionCtrl,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Descripción',
                    hintText:
                        'Cuéntanos brevemente sobre la tienda, servicios, estilo o especialidad.',
                    alignLabelWithHint: true,
                    prefixIcon: Icon(Icons.description_outlined),
                  ),
                ),

                const SizedBox(height: 24),

                _buildSectionTitle('Configuración'),

                SwitchListTile(
                  value: isActive,
                  activeThumbColor: AppColors.purple,
                  contentPadding: EdgeInsets.zero,
                  title: const Text(
                    'Negocio activo',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: const Text(
                    'Indica si el negocio está habilitado en la plataforma.',
                  ),
                  onChanged: (value) {
                    setState(() {
                      isActive = value;
                    });
                  },
                ),

                SwitchListTile(
                  value: showInMap,
                  activeThumbColor: AppColors.purple,
                  contentPadding: EdgeInsets.zero,
                  title: const Text(
                    'Mostrar en el mapa',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: const Text(
                    'Si está activo, este negocio podrá aparecer como punto en el mapa.',
                  ),
                  onChanged: (value) {
                    setState(() {
                      showInMap = value;
                    });
                  },
                ),

                const SizedBox(height: 24),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Resumen rápido',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: AppColors.dark,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tipo: $businessType',
                        style: const TextStyle(color: Colors.black87),
                      ),
                      Text(
                        'Servicios: ${selectedServices.isEmpty ? 'Ninguno' : selectedServices.join(', ')}',
                        style: const TextStyle(color: Colors.black87),
                      ),
                      Text(
                        'Horario: $openTime a $closeTime',
                        style: const TextStyle(color: Colors.black87),
                      ),
                      Text(
                        'Mapa: ${showInMap ? 'Visible' : 'Oculto'}',
                        style: const TextStyle(color: Colors.black87),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 26),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.purple,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 17),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'Enviar solicitud',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/* INFO TILE */

class InfoTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const InfoTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: AppColors.purpleSoft,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: AppColors.purple),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.dark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Colors.black54,
                    fontSize: 13.5,
                    height: 1.3,
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

/* APP BAR SIMPLE */

PreferredSizeWidget _simpleAppBar(String title) {
  return AppBar(
    backgroundColor: Colors.white,
    surfaceTintColor: Colors.transparent,
    elevation: 0,
    centerTitle: true,
    title: Text(
      title,
      style: const TextStyle(
        color: AppColors.dark,
        fontWeight: FontWeight.w800,
      ),
    ),
  );
}

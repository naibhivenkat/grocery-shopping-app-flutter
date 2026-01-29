import 'package:flutter/material.dart';
import '../api/service_api.dart';
import '../utils/provider_theme.dart';
import '../utils/ui_helpers.dart';
import '../utils/validators.dart';
import 'forgot_password_screen.dart';
import 'provider_home_dashboard.dart';
import 'service_register_screen.dart';

class ServiceLoginScreen extends StatefulWidget {
  const ServiceLoginScreen({super.key});

  @override
  State<ServiceLoginScreen> createState() => _ServiceLoginScreenState();
}

class _ServiceLoginScreenState extends State<ServiceLoginScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _pass = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _email.dispose();
    _pass.dispose();
    super.dispose();
  }

  Future<void> _doLogin() async {
    if (!_form.currentState!.validate()) return;

    setState(() => _loading = true);
    try {
      final res = await ServiceApi.login(
        email: _email.text.trim(),
        password: _pass.text.trim(),
      );

      final user = res["user"];
      if (user == null) throw Exception("Login failed. User missing.");

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (routeCtx) => ProviderHomeDashboard(
            providerId: user["uid"],
            providerName: user["name"] ?? "Provider",
            role: user["role"] ?? "provider",
            serviceCategoryId: user["service_category_id"] ?? "",
          ),
        ),
      );
    } catch (e) {
      UIHelpers.showSnack(
        context,
        e.toString().replaceFirst("Exception: ", ""),
        error: true,
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ProviderTheme.themeData(),
      child: Scaffold(
        body: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                ProviderTheme.primary.withOpacity(0.10),
                Colors.white,
                Colors.white,
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(18),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // ✅ ICON + TITLE
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [
                              Colors.deepPurple.withOpacity(0.9),
                              Colors.blue.withOpacity(0.9),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.12),
                              blurRadius: 16,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.design_services_rounded,
                          color: Colors.white,
                          size: 34,
                        ),
                      ),

                      const SizedBox(height: 14),

                      const Text(
                        "Service Login",
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: ProviderTheme.text,
                        ),
                      ),

                      const SizedBox(height: 6),

                      Text(
                        "Login as Provider or Requester",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.black.withOpacity(0.55),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),

                      const SizedBox(height: 18),

                      // ✅ LOGIN CARD CENTER
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Form(
                            key: _form,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Email Address",
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: Colors.black.withOpacity(0.75),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: _email,
                                  keyboardType: TextInputType.emailAddress,
                                  decoration: const InputDecoration(
                                    hintText: "example@gmail.com",
                                    prefixIcon: Icon(Icons.email_outlined),
                                  ),
                                  validator: Validators.email,
                                ),

                                const SizedBox(height: 14),

                                Text(
                                  "Password",
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: Colors.black.withOpacity(0.75),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: _pass,
                                  obscureText: true,
                                  decoration: const InputDecoration(
                                    hintText: "Enter password",
                                    prefixIcon: Icon(Icons.lock_outline_rounded),
                                  ),
                                  validator: Validators.password,
                                ),

                                const SizedBox(height: 16),

                                SizedBox(
                                  width: double.infinity,
                                  height: 50,
                                  child: ElevatedButton(
                                    onPressed: _loading ? null : _doLogin,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: ProviderTheme.primary,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                    ),
                                    child: _loading
                                        ? const SizedBox(
                                            height: 20,
                                            width: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white,
                                            ),
                                          )
                                        : const Text(
                                            "Login",
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w800,
                                              color: Colors.white,
                                            ),
                                          ),
                                  ),
                                ),

                                const SizedBox(height: 12),

                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    TextButton(
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (ctx) => const ServiceRegisterScreen(),
                                          ),
                                        );
                                      },
                                      child: const Text(
                                        "New? Register",
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          color: Colors.deepPurple,
                                        ),
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (ctx) => const ForgotPasswordScreen(),
                                          ),
                                        );
                                      },
                                      child: const Text(
                                        "Forgot Password?",
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          color: Colors.blue,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

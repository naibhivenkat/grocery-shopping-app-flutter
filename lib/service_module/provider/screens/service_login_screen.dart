import 'package:flutter/material.dart';
import '../../../services/notification_service.dart';
import '../api/service_api.dart';
import '../utils/provider_theme.dart';
import '../utils/ui_helpers.dart';
import '../utils/validators.dart';
import 'forgot_password_screen.dart';
import 'provider_home_dashboard.dart';
import 'service_register_screen.dart';
import 'package:grocery_app_new_flutter/services/session_manager.dart';



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
  bool _showPassword = false;

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
    if (user == null) {
      throw Exception("Login failed");
    }

    //////////////////////////////////////////////////////////////
    /// ✅ SAVE LOGIN SESSION
    //////////////////////////////////////////////////////////////
    await SessionManager.saveLogin(
      user["name"] ?? "",
      "provider",
    );

    await SessionManager.setServiceUserId(user["uid"]);

    //////////////////////////////////////////////////////////////
    /// ✅ VERY IMPORTANT — SAVE FULL PROFILE
    //////////////////////////////////////////////////////////////
    await SessionManager.saveUserProfileFull(
      fullName: user["name"] ?? "",
      email: user["email"] ?? "",
      phone: user["mobile"] ?? "",
      address: user["address"] ?? "",
      location: user["location"] ?? "",
      photoUrl: "", // if you don't use URL
      photoBase64: user["photo_base64"] ?? "",
    );

    //////////////////////////////////////////////////////////////
    /// 🔔 REGISTER FCM TOKEN AFTER LOGIN
    //////////////////////////////////////////////////////////////
    await NotificationService.checkAndUploadToken();

    if (!mounted) return;

    final List services =
        (user["service_category_ids"] is List)
            ? user["service_category_ids"]
            : [];

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => ProviderHomeDashboard(
          providerId: user["uid"],
          providerName: user["name"] ?? "Service User",
          role: "service_provider",
          serviceCategoryId:
              services.isNotEmpty ? services.first : "",
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
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(18),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // 🔥 ICON
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            Colors.deepPurple.withOpacity(0.9),
                            Colors.blue.withOpacity(0.9),
                          ],
                        ),
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
                      ),
                    ),

                    const SizedBox(height: 6),

                    const Text(
                      "Login to continue",
                      style: TextStyle(color: Colors.black54),
                    ),

                    const SizedBox(height: 20),

                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Form(
                          key: _form,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Email",
                                style: TextStyle(fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _email,
                                keyboardType: TextInputType.emailAddress,
                                decoration: const InputDecoration(
                                  prefixIcon: Icon(Icons.email_outlined),
                                  hintText: "example@gmail.com",
                                ),
                                validator: Validators.email,
                              ),

                              const SizedBox(height: 14),

                              const Text(
                                "Password",
                                style: TextStyle(fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _pass,
                                obscureText: !_showPassword,
                                decoration: InputDecoration(
                                  prefixIcon: const Icon(Icons.lock_outline),
                                  hintText: "Enter password",
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _showPassword
                                          ? Icons.visibility_off
                                          : Icons.visibility,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _showPassword = !_showPassword;
                                      });
                                    },
                                  ),
                                ),
                                validator: Validators.password,
                              ),

                              const SizedBox(height: 20),

                              SizedBox(
                                width: double.infinity,
                                height: 50,
                                child: ElevatedButton(
                                  onPressed: _loading ? null : _doLogin,
                                  child: _loading
                                      ? const CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        )
                                      : const Text(
                                          "Login",
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                ),
                              ),

                              const SizedBox(height: 12),

                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  TextButton(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              const ServiceRegisterScreen(),
                                        ),
                                      );
                                    },
                                    child: const Text("New? Register"),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              const ForgotPasswordScreen(),
                                        ),
                                      );
                                    },
                                    child: const Text("Forgot Password?"),
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
    );
  }
}

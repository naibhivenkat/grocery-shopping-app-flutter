import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../api/service_api.dart';
import '../utils/provider_theme.dart';
import '../utils/service_catalog.dart';
import '../utils/ui_helpers.dart';
import '../utils/validators.dart';

class ServiceRegisterScreen extends StatefulWidget {
  const ServiceRegisterScreen({super.key});

  @override
  State<ServiceRegisterScreen> createState() => _ServiceRegisterScreenState();
}

class _ServiceRegisterScreenState extends State<ServiceRegisterScreen> {
  final _form = GlobalKey<FormState>();

  final _name = TextEditingController();
  final _mobile = TextEditingController();
  final _email = TextEditingController();
  final _location = TextEditingController();

  // optional bank
  final _bankName = TextEditingController();
  final _bankAcc = TextEditingController();
  final _ifsc = TextEditingController();
  final _upi = TextEditingController();

  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();

  // ✅ Multi-select services (optional)
  final Set<String> _selectedServiceIds = {};
  final _serviceSearch = TextEditingController();

  // ✅ Optional schedule (not required)
  final Set<String> _workingDays = {};
  TimeOfDay _from = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _to = const TimeOfDay(hour: 18, minute: 0);
  int _slotSize = 30;

  // ✅ Optional photo
  Uint8List? _photoBytes;

  // ✅ OTP
  bool _otpSent = false;
  bool _otpVerified = false;
  final _otpCtrl = TextEditingController();

  // ✅ OTP resend timer + progress
  int _resendSec = 0; // counts down from 30
  static const int _cooldownTotal = 30;

  bool get _canResend => _resendSec == 0;
  double get _cooldownProgress {
    if (_resendSec <= 0) return 1.0;
    return (_cooldownTotal - _resendSec) / _cooldownTotal;
  }

  // ✅ Terms
  bool _acceptTerms = false;

  // ✅ password eye icons
  bool _showPass = false;
  bool _showConfirm = false;

  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _password.addListener(() => setState(() {}));
    _confirmPassword.addListener(() => setState(() {}));
    _serviceSearch.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _name.dispose();
    _mobile.dispose();
    _email.dispose();
    _location.dispose();
    _bankName.dispose();
    _bankAcc.dispose();
    _ifsc.dispose();
    _upi.dispose();
    _password.dispose();
    _confirmPassword.dispose();
    _otpCtrl.dispose();
    _serviceSearch.dispose();
    super.dispose();
  }

  String _fmt(TimeOfDay t) =>
      "${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}";

  // ✅ Password rules
  bool get _hasMinLen => _password.text.trim().length >= 8;
  bool get _hasUpper => RegExp(r'[A-Z]').hasMatch(_password.text);
  bool get _hasLower => RegExp(r'[a-z]').hasMatch(_password.text);
  bool get _hasNumber => RegExp(r'\d').hasMatch(_password.text);
  bool get _hasSpecial =>
      RegExp(r'[!@#\$%\^&\*\(\)_\+\-=\[\]{};:"\\|,.<>\/?]')
          .hasMatch(_password.text);

  bool get _passwordOk =>
      _hasMinLen && _hasUpper && _hasLower && _hasNumber && _hasSpecial;

  bool get _passwordsMatch => _password.text == _confirmPassword.text;

  Future<void> _pickTime(bool from) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: from ? _from : _to,
    );
    if (picked != null) {
      setState(() {
        if (from) {
          _from = picked;
        } else {
          _to = picked;
        }
      });
    }
  }

  Future<void> _pickPhoto() async {
    try {
      final picker = ImagePicker();
      final xFile = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 50,
        maxWidth: 600,
        maxHeight: 600,
      );
      if (xFile == null) return;

      final bytes = await xFile.readAsBytes();
      setState(() => _photoBytes = bytes);
    } catch (e) {
      UIHelpers.showSnack(context, "Photo pick failed: $e", error: true);
    }
  }

  void _startResendTimer() async {
    setState(() => _resendSec = _cooldownTotal);
    while (_resendSec > 0 && mounted) {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return;
      setState(() => _resendSec = _resendSec - 1);
    }
  }

  Future<void> _sendOtp() async {
    if (Validators.email(_email.text) != null) {
      UIHelpers.showSnack(context, "Enter valid email first", error: true);
      return;
    }
    if (!_canResend) return;

    setState(() => _loading = true);

    try {
      await ServiceApi.sendOtp(email: _email.text.trim());
      setState(() {
        _otpSent = true;
        _otpVerified = false;
      });

      _startResendTimer();
      UIHelpers.showSnack(context, "OTP sent to email ✅");
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

  Future<void> _verifyOtp() async {
    if (_otpCtrl.text.trim().length != 6) return;

    setState(() => _loading = true);
    try {
      await ServiceApi.verifyOtp(
        email: _email.text.trim(),
        otp: _otpCtrl.text.trim(),
      );
      setState(() => _otpVerified = true);
      UIHelpers.showSnack(context, "OTP verified ✅");
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

  Future<void> _register() async {
    if (!_form.currentState!.validate()) return;

    if (!_passwordOk) {
      UIHelpers.showSnack(
        context,
        "Password does not meet requirements",
        error: true,
      );
      return;
    }

    if (!_passwordsMatch) {
      UIHelpers.showSnack(context, "Passwords do not match", error: true);
      return;
    }

    if (!_acceptTerms) {
      UIHelpers.showSnack(
        context,
        "Please accept Terms & Conditions",
        error: true,
      );
      return;
    }

    if (!_otpVerified) {
      UIHelpers.showSnack(
        context,
        "Verify OTP before registration",
        error: true,
      );
      return;
    }

    setState(() => _loading = true);

    try {
      final bankFilled = _bankName.text.trim().isNotEmpty ||
          _bankAcc.text.trim().isNotEmpty ||
          _ifsc.text.trim().isNotEmpty ||
          _upi.text.trim().isNotEmpty;

      final scheduleFilled = _workingDays.isNotEmpty;

      final payload = {
        "name": _name.text.trim(),
        "mobile": _mobile.text.trim(),
        "email": _email.text.trim(),
        "password": _password.text,

        "location": _location.text.trim().isEmpty ? null : _location.text.trim(),

        // ✅ Multi services optional
        "service_category_ids": _selectedServiceIds.toList(),

        // ✅ Optional photo base64
        "photo_base64": _photoBytes == null ? null : base64Encode(_photoBytes!),

        // ✅ Optional bank
        "bank": bankFilled
            ? {
                "bank_name": _bankName.text.trim(),
                "account_no": _bankAcc.text.trim(),
                "ifsc": _ifsc.text.trim(),
                "upi": _upi.text.trim().isEmpty ? null : _upi.text.trim(),
              }
            : null,

        // ✅ Optional schedule
        "working_schedule": scheduleFilled
            ? {
                "working_days": _workingDays.toList(),
                "working_hours": {"from": _fmt(_from), "to": _fmt(_to)},
                "slot_size": _slotSize,
              }
            : null,
      };

      await ServiceApi.register(payload);

      if (!mounted) return;
      UIHelpers.showSnack(context, "Registration successful ✅ Please login");
      Navigator.pop(context);
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

  // ✅ Clear all selected services
  void _clearAllServices() {
    setState(() => _selectedServiceIds.clear());
  }

  Widget _sectionTitle(String title, {String? sub}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
        if (sub != null) ...[
          const SizedBox(height: 4),
          Text(sub, style: const TextStyle(color: ProviderTheme.subText)),
        ],
        const SizedBox(height: 10),
      ],
    );
  }

  Widget _rule(String text, bool ok) {
    return Row(
      children: [
        Icon(ok ? Icons.check_circle : Icons.circle_outlined,
            size: 16, color: ok ? Colors.green : Colors.grey),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: ok ? Colors.green.shade800 : Colors.black54,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _serviceChip(ServiceCatalogItem item) {
    final selected = _selectedServiceIds.contains(item.id);

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () {
        setState(() {
          if (selected) {
            _selectedServiceIds.remove(item.id);
          } else {
            _selectedServiceIds.add(item.id);
          }
        });
      },
      child: Container(
        margin: const EdgeInsets.only(right: 10, bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? item.color.withOpacity(0.18) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? item.color.withOpacity(0.65) : ProviderTheme.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(item.icon, color: item.color, size: 18),
            const SizedBox(width: 8),
            Text(
              item.name,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: selected ? ProviderTheme.text : Colors.black87,
              ),
            ),
            if (selected) ...[
              const SizedBox(width: 6),
              Icon(Icons.check_circle, size: 16, color: item.color),
            ]
          ],
        ),
      ),
    );
  }

  Widget _dayChip(String d) {
    final on = _workingDays.contains(d);
    return FilterChip(
      selected: on,
      label: Text(d),
      onSelected: (v) => setState(() {
        if (v) {
          _workingDays.add(d);
        } else {
          _workingDays.remove(d);
        }
      }),
    );
  }

  String _selectedServicesText() {
    if (_selectedServiceIds.isEmpty) return "Selected: None (optional)";

    final names = _selectedServiceIds
        .map((id) => ServiceCatalog.byId(id)?.name ?? id)
        .toList();

    return "Selected: ${names.join(", ")}";
  }

  // ✅ Filter + Selected first sorting ✅
  List<ServiceCatalogItem> _filteredServices() {
  final q = _serviceSearch.text.trim().toLowerCase();

  // ✅ make a mutable copy (IMPORTANT)
  List<ServiceCatalogItem> list =
      List<ServiceCatalogItem>.from(ServiceCatalog.items);

  if (q.isNotEmpty) {
    list = list.where((e) => e.name.toLowerCase().contains(q)).toList();
  }

  // ✅ Selected first sorting
  list.sort((a, b) {
    final aSel = _selectedServiceIds.contains(a.id);
    final bSel = _selectedServiceIds.contains(b.id);
    if (aSel == bSel) return a.name.compareTo(b.name);
    return aSel ? -1 : 1;
  });

  return list;
}

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredServices();

    return Theme(
      data: ProviderTheme.themeData(),
      child: Scaffold(
        body: Container(
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
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Column(
                  children: [
                    // ✅ header
                    Row(
                      children: [
                        InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: () => Navigator.pop(context),
                          child: const Padding(
                            padding: EdgeInsets.all(10),
                            child: Icon(Icons.arrow_back),
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text(
                            "Service Registration",
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // ✅ Photo upload
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Container(
                              height: 58,
                              width: 58,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: ProviderTheme.primary.withOpacity(0.12),
                                border: Border.all(color: ProviderTheme.border),
                              ),
                              child: ClipOval(
                                child: _photoBytes == null
                                    ? const Icon(Icons.person, size: 30, color: ProviderTheme.primary)
                                    : Image.memory(_photoBytes!, fit: BoxFit.cover),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    "Profile Photo (Optional)",
                                    style: TextStyle(fontWeight: FontWeight.w900),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "You can add photo now or later in profile.",
                                    style: TextStyle(
                                      color: Colors.black.withOpacity(0.55),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            OutlinedButton(
                              onPressed: _loading ? null : _pickPhoto,
                              child: const Text("Upload"),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Form(
                          key: _form,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _sectionTitle(
                                "Basic Details",
                                sub: "Only Name, Mobile, Email are required.",
                              ),

                              TextFormField(
                                controller: _name,
                                decoration: const InputDecoration(labelText: "Full Name"),
                                validator: (v) => Validators.requiredField(v, label: "Name"),
                              ),
                              const SizedBox(height: 12),

                              TextFormField(
                                controller: _mobile,
                                keyboardType: TextInputType.phone,
                                decoration: const InputDecoration(labelText: "Mobile Number"),
                                validator: Validators.mobile,
                              ),
                              const SizedBox(height: 12),

                              TextFormField(
                                controller: _email,
                                keyboardType: TextInputType.emailAddress,
                                decoration: const InputDecoration(labelText: "Email Address"),
                                validator: Validators.email,
                              ),
                              const SizedBox(height: 12),

                              TextFormField(
                                controller: _location,
                                decoration: const InputDecoration(
                                  labelText: "Area / Location (Optional)",
                                ),
                              ),

                              const SizedBox(height: 20),

                              _sectionTitle(
                                "Services (Optional)",
                                sub: "Select one or more services you can offer / request.",
                              ),

                              // ✅ Search box
                              TextFormField(
                                controller: _serviceSearch,
                                decoration: const InputDecoration(
                                  labelText: "Search services",
                                  prefixIcon: Icon(Icons.search),
                                ),
                              ),
                              const SizedBox(height: 10),

                              // ✅ Selected services line + Clear All
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: ProviderTheme.bg,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: ProviderTheme.border),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        _selectedServicesText(),
                                        style: const TextStyle(fontWeight: FontWeight.w800),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    if (_selectedServiceIds.isNotEmpty)
                                      InkWell(
                                        onTap: _clearAllServices,
                                        borderRadius: BorderRadius.circular(10),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                          decoration: BoxDecoration(
                                            color: Colors.red.withOpacity(0.08),
                                            borderRadius: BorderRadius.circular(10),
                                            border: Border.all(color: Colors.red.withOpacity(0.25)),
                                          ),
                                          child: const Text(
                                            "Clear",
                                            style: TextStyle(
                                              fontWeight: FontWeight.w900,
                                              color: Colors.red,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 10),

                              Wrap(
                                children: filtered.map<Widget>((e) => _serviceChip(e)).toList(),
                              ),

                              const SizedBox(height: 18),

                              _sectionTitle(
                                "Create Password",
                                sub: "Use a strong password for your account.",
                              ),

                              TextFormField(
                                controller: _password,
                                obscureText: !_showPass,
                                decoration: InputDecoration(
                                  labelText: "Password",
                                  suffixIcon: IconButton(
                                    onPressed: () => setState(() => _showPass = !_showPass),
                                    icon: Icon(_showPass ? Icons.visibility_off : Icons.visibility),
                                  ),
                                ),
                                validator: Validators.password,
                              ),
                              const SizedBox(height: 12),

                              TextFormField(
                                controller: _confirmPassword,
                                obscureText: !_showConfirm,
                                decoration: InputDecoration(
                                  labelText: "Confirm Password",
                                  suffixIcon: IconButton(
                                    onPressed: () => setState(() => _showConfirm = !_showConfirm),
                                    icon: Icon(_showConfirm ? Icons.visibility_off : Icons.visibility),
                                  ),
                                ),
                                validator: (v) => Validators.requiredField(v, label: "Confirm password"),
                              ),

                              const SizedBox(height: 12),

                              // ✅ Password rules
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: ProviderTheme.bg,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: ProviderTheme.border),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      "Password must contain:",
                                      style: TextStyle(fontWeight: FontWeight.w900),
                                    ),
                                    const SizedBox(height: 10),
                                    _rule("At least 8 characters", _hasMinLen),
                                    _rule("1 uppercase letter (A-Z)", _hasUpper),
                                    _rule("1 lowercase letter (a-z)", _hasLower),
                                    _rule("1 number (0-9)", _hasNumber),
                                    _rule("1 special character (!@#...)", _hasSpecial),
                                    const SizedBox(height: 10),
                                    _rule("Password and confirm password match", _passwordsMatch),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 18),

                              // ✅ Terms checkbox
                              Row(
                                children: [
                                  Checkbox(
                                    value: _acceptTerms,
                                    onChanged: (v) => setState(() => _acceptTerms = v ?? false),
                                  ),
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () => setState(() => _acceptTerms = !_acceptTerms),
                                      child: const Text(
                                        "I agree to Terms & Conditions",
                                        style: TextStyle(fontWeight: FontWeight.w700),
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 18),

                              _sectionTitle(
                                "Email OTP Verification",
                                sub: "OTP required to verify email before registration.",
                              ),

                              // ✅ Send / Resend button + progress bar
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(
                                    width: double.infinity,
                                    height: 48,
                                    child: ElevatedButton(
                                      onPressed: (_loading || !_canResend) ? null : _sendOtp,
                                      child: Text(
                                        _canResend ? "Send OTP" : "Resend in $_resendSec sec",
                                      ),
                                    ),
                                  ),

                                  const SizedBox(height: 10),

                                  // ✅ Smooth cooldown progress bar
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: LinearProgressIndicator(
                                      value: _cooldownProgress,
                                      minHeight: 8,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    _canResend
                                        ? "You can resend OTP now ✅"
                                        : "Please wait before resending OTP...",
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.black.withOpacity(0.55),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),

                              if (_otpSent) ...[
                                const SizedBox(height: 12),
                                TextFormField(
                                  controller: _otpCtrl,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(labelText: "Enter 6-digit OTP"),
                                  maxLength: 6,
                                  onChanged: (val) async {
                                    setState(() {});

                                    // ✅ AUTO VERIFY OTP when 6 digits entered
                                    if (val.trim().length == 6 && !_otpVerified && !_loading) {
                                      await _verifyOtp();
                                    }
                                  },
                                ),

                                const SizedBox(height: 10),

                                if (_otpVerified)
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.green.withOpacity(0.08),
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(color: Colors.green.withOpacity(0.25)),
                                    ),
                                    child: const Text(
                                      "OTP Verified ✅",
                                      style: TextStyle(fontWeight: FontWeight.w800),
                                    ),
                                  )
                                else
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.orange.withOpacity(0.08),
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(color: Colors.orange.withOpacity(0.25)),
                                    ),
                                    child: const Text(
                                      "Enter OTP to auto verify…",
                                      style: TextStyle(fontWeight: FontWeight.w700),
                                    ),
                                  ),
                              ],

                              const SizedBox(height: 16),

                              // ✅ Register shows only after OTP verified
                              if (_otpVerified)
                                SizedBox(
                                  width: double.infinity,
                                  height: 52,
                                  child: ElevatedButton(
                                    onPressed: _loading ? null : _register,
                                    child: _loading
                                        ? const SizedBox(
                                            height: 20,
                                            width: 20,
                                            child: CircularProgressIndicator(strokeWidth: 2),
                                          )
                                        : const Text("Complete Registration"),
                                  ),
                                )
                              else
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.withOpacity(0.06),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(color: Colors.blue.withOpacity(0.22)),
                                  ),
                                  child: const Text(
                                    "Complete Registration appears after OTP verification ✅",
                                    style: TextStyle(fontWeight: FontWeight.w700),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // ✅ Optional sections
                    ExpansionTile(
                      title: const Text("Optional: Bank Details"),
                      subtitle: const Text("Add later in Profile / Earnings."),
                      childrenPadding: const EdgeInsets.all(16),
                      children: [
                        TextFormField(
                          controller: _bankName,
                          decoration: const InputDecoration(labelText: "Bank Name"),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _bankAcc,
                          decoration: const InputDecoration(labelText: "Account Number"),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _ifsc,
                          decoration: const InputDecoration(labelText: "IFSC Code"),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _upi,
                          decoration: const InputDecoration(labelText: "UPI ID (Optional)"),
                        ),
                      ],
                    ),

                    ExpansionTile(
                      title: const Text("Optional: Working Schedule"),
                      subtitle: const Text("Set later in availability settings."),
                      childrenPadding: const EdgeInsets.all(16),
                      children: [
                        Wrap(
                          spacing: 8,
                          children: ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
                              .map(_dayChip)
                              .toList(),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => _pickTime(true),
                                child: Text("From: ${_fmt(_from)}"),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => _pickTime(false),
                                child: Text("To: ${_fmt(_to)}"),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<int>(
                          value: _slotSize,
                          decoration: const InputDecoration(labelText: "Slot Size"),
                          items: const [
                            DropdownMenuItem(value: 15, child: Text("15 minutes")),
                            DropdownMenuItem(value: 30, child: Text("30 minutes")),
                            DropdownMenuItem(value: 60, child: Text("60 minutes")),
                          ],
                          onChanged: (v) => setState(() => _slotSize = v ?? 30),
                        ),
                      ],
                    ),

                    const SizedBox(height: 22),
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

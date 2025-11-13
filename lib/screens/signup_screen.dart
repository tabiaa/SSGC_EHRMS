import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'login_screen.dart';
import 'package:flutter/services.dart';
class SignupScreen extends StatefulWidget {
  const SignupScreen({Key? key}) : super(key: key);

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final TextEditingController empIdController = TextEditingController();
  final TextEditingController otpController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  int currentStep = 1;
  bool isLoading = false;
  bool isPasswordVisible = false;
  bool isConfirmPasswordVisible = false;
  String message = "";

  Future<void> _requestOtp() async {
    final empId = empIdController.text.trim();
    if (empId.isEmpty) {
      setState(() => message = "Please enter Employee ID");
      return;
    }

    setState(() => isLoading = true);
    try {
      final res = await ApiService.requestOtp(empId);
      setState(() {
        message = res['message'] ?? '';
        if (res['success'] == true) currentStep = 2;
      });
    } catch (e) {
      setState(() => message = e.toString());
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _verifyOtp() async {
    final empId = empIdController.text.trim();
    final otp = otpController.text.trim();
    if (otp.isEmpty) {
      setState(() => message = "Please enter OTP");
      return;
    }

    setState(() => isLoading = true);
    try {
      final res = await ApiService.verifyOtp(employeeId: empId, otp: otp);
      setState(() {
        message = res['message'] ?? '';
        if (res['success'] == true) currentStep = 3;
      });
    } catch (e) {
      setState(() => message = e.toString());
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _createPassword() async {
    final empId = empIdController.text.trim();
    final password = passwordController.text.trim();
    final confirm = confirmPasswordController.text.trim();

    if (password.isEmpty || confirm.isEmpty) {
      setState(() => message = "Please fill all fields");
      return;
    }
    if (password != confirm) {
      setState(() => message = "Passwords do not match");
      return;
    }

    final passwordRegex =
        RegExp(r'^(?=.*[A-Za-z])(?=.*\d)(?=.*[^A-Za-z0-9]).{8,}$');

    if (!passwordRegex.hasMatch(password)) {
      setState(() => message =
          "Password must be at least 8 characters long and include:\n• 1 letter\n• 1 number\n• 1 special character");
      return;
    }

    setState(() => isLoading = true);
    try {
      final res =
          await ApiService.createPassword(employeeId: empId, password: password);

      if (res['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Account created! Redirecting..."),
            backgroundColor: Colors.green,
          ),
        );
        await Future.delayed(const Duration(seconds: 1));
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) =>  LoginScreen()), // ✅ Added const
        );
      } else {
        setState(() => message = res['message'] ?? 'Error creating account');
      }
    } catch (e) {
      setState(() => message = "Error: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  Widget _otpBoxes() {
    return TextField(
      controller: otpController,
      keyboardType: TextInputType.number,
      maxLength: 6,
      textAlign: TextAlign.center,
      decoration: InputDecoration(
        counterText: "",
        filled: true,
        fillColor: Colors.grey[100],
        hintText: "••••••",
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
      style: const TextStyle(letterSpacing: 8, fontSize: 20),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget stepWidget;

    if (currentStep == 1) {
      stepWidget = Column(
        children: [
          TextField(
            controller: empIdController,
            decoration: const InputDecoration(
              labelText: "Employee ID",
              border: OutlineInputBorder(),
            ),
             maxLength: 6,
                              inputFormatters: [
    FilteringTextInputFormatter.allow(RegExp(r'[0-9]')),
  ],
          ),
          const SizedBox(height: 30),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFFFF7A00),
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: isLoading ? null : _requestOtp,
            child: Text(isLoading ? "Sending..." : "Request OTP",
                style: const TextStyle(fontSize: 16, color: Colors.white)),
          ),
        ],
      );
    } else if (currentStep == 2) {
      stepWidget = Column(
        children: [
          const Text("Enter Verification Code",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
          const SizedBox(height: 20),
          _otpBoxes(),
          const SizedBox(height: 30),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orangeAccent,
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: isLoading ? null : _verifyOtp,
            child: Text(isLoading ? "Verifying..." : "Verify OTP",
                style: const TextStyle(fontSize: 16, color: Colors.white)),
          ),
        ],
      );
    } else {
      stepWidget = Column(
        children: [
          TextField(
            controller: passwordController,
            obscureText: !isPasswordVisible,
            decoration: InputDecoration(
              labelText: "Create Password",
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                icon: Icon(isPasswordVisible
                    ? Icons.visibility
                    : Icons.visibility_off),
                onPressed: () =>
                    setState(() => isPasswordVisible = !isPasswordVisible),
              ),
            ),
            
          ),
          const SizedBox(height: 20),
          TextField(
            controller: confirmPasswordController,
            obscureText: !isConfirmPasswordVisible,
            decoration: InputDecoration(
              labelText: "Confirm Password",
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                icon: Icon(isConfirmPasswordVisible
                    ? Icons.visibility
                    : Icons.visibility_off),
                onPressed: () => setState(
                    () => isConfirmPasswordVisible = !isConfirmPasswordVisible),
              ),
            ),
          ),
          const SizedBox(height: 30),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orangeAccent,
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: isLoading ? null : _createPassword,
            child: Text(isLoading ? "Creating..." : "Create Account",
                style: const TextStyle(fontSize: 16, color: Colors.white)),
          ),
        ],
      );
    }

    return Scaffold(
      
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFF7A00), Color(0xFFCC5500)], 
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(24),
            margin: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 4))
              ],
            ),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Text(
                    currentStep == 1
                        ? "Employee Signup"
                        : currentStep == 2
                            ? "Verify OTP"
                            : "Set Password",
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  stepWidget,
                  const SizedBox(height: 20),
                  if (message.isNotEmpty)
                    Text(
                      message,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: message.contains("Success")
                            ? Colors.green
                            : Colors.red,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
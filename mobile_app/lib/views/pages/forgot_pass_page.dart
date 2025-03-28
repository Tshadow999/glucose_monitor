import 'package:GlucoMonitor/data/notifiers.dart';
import 'package:GlucoMonitor/views/pages/login_page.dart';
import 'package:flutter/material.dart';
import 'package:GlucoMonitor/views/widgets/hero_widget.dart';

class ForgotPassPage extends StatefulWidget {
  const ForgotPassPage({super.key});

  @override
  State<ForgotPassPage> createState() => _ForgotPassPageState();
}

class _ForgotPassPageState extends State<ForgotPassPage> {
  TextEditingController emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();

    emailController.text = "test@email.com";
  }

  @override
  void dispose() {
    emailController.dispose();
    super.dispose();
  }

  bool isValidEmail(String email) {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(email);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: ClampingScrollPhysics(), // Prevents overscroll effects
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const HeroWidget(),
                  const SizedBox(height: 32),
                  TextFormField(
                    controller: emailController,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(32.0),
                      ),
                      labelText: "email",
                    ),
                    keyboardType: TextInputType.emailAddress,
                    // Add this to handle keyboard actions
                    textInputAction: TextInputAction.next,
                    validator: (emailValue) {
                      if (emailValue == null || emailValue.isEmpty) {
                        return "Email cannot be empty";
                      } else if (!isValidEmail(emailValue)) {
                        return "Enter a valid email address";
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 32),
                  FilledButton(
                    onPressed: () {
                      resetPassword();

                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => LoginPage()),
                      );
                    },
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(double.infinity, 48),
                    ),
                    child: const Text(
                      "Send email",
                      style: TextStyle(fontSize: 24),
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

  Future<void> resetPassword() async {
    await authService.value.resetPassword(email: emailController.text);
  }
}

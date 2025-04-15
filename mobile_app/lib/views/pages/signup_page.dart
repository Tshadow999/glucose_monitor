import 'package:sugar_daddy/data/notifiers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:sugar_daddy/views/widget_tree.dart';
import 'package:sugar_daddy/views/widgets/hero_widget.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  TextEditingController nameController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  TextEditingController confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  bool isValidEmail(String email) {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(email);
  }

  void validateAndSignup() async {
    if (_formKey.currentState!.validate()) {
      FocusManager.instance.primaryFocus?.unfocus();

      try {
        await authService.value.createAccount(
          email: emailController.text,
          password: passwordController.text,
        );

        await FirebaseFirestore.instance.collection("user_data").add({
          "name": nameController.text,
          "emal": emailController.text,
        });

        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => WidgetTree()),
        );
      } on FirebaseAuthException catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message ?? "An error occured")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("Create Account"),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const HeroWidget(),
                  const SizedBox(height: 24),

                  // Name field
                  TextFormField(
                    controller: nameController,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(32.0),
                      ),
                      labelText: "Full Name",
                      prefixIcon: const Icon(Icons.person),
                    ),
                    textInputAction: TextInputAction.next,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return "Name cannot be empty";
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),

                  // Email field
                  TextFormField(
                    controller: emailController,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(32.0),
                      ),
                      labelText: "Email",
                      prefixIcon: const Icon(Icons.email),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return "Email cannot be empty";
                      } else if (!isValidEmail(value)) {
                        return "Enter a valid email address";
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),

                  // Password field
                  TextFormField(
                    controller: passwordController,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(32.0),
                      ),
                      labelText: "Password",
                      prefixIcon: const Icon(Icons.lock),
                    ),
                    obscureText: true,
                    textInputAction: TextInputAction.next,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return "Password cannot be empty";
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),

                  // Confirm Password field
                  TextFormField(
                    controller: confirmPasswordController,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(32.0),
                      ),
                      labelText: "Confirm Password",
                      prefixIcon: const Icon(Icons.lock_outline),
                    ),
                    obscureText: true,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => validateAndSignup(),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return "Please confirm your password";
                      } else if (value != passwordController.text) {
                        return "Passwords do not match";
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 32),

                  // Signup button
                  FilledButton(
                    onPressed: validateAndSignup,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(double.infinity, 48),
                    ),
                    child: const Text(
                      "Create Account",
                      style: TextStyle(fontSize: 24),
                    ),
                  ),
                  const SizedBox(height: 14),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

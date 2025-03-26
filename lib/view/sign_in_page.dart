import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SignInPage extends StatefulWidget {
  const SignInPage({super.key});

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  List<KeyEvent> events = [];

  @override
  void initState() {
    super.initState();
    ServicesBinding.instance.keyboard.addHandler(onKeyPressed);
  }

  @override
  void dispose() {
    super.dispose();
    ServicesBinding.instance.keyboard.removeHandler(onKeyPressed);
  }

  bool onKeyPressed(KeyEvent event) {
    print(event is KeyUpEvent);
    if (event is KeyUpEvent) return false;
    setState(() {
      events.add(event);
    });
    if (event.logicalKey == LogicalKeyboardKey.enter) events.clear();

    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text(
          events.map((event) => event.logicalKey.keyLabel).join(),
          style: Theme.of(context).textTheme.headlineLarge,
        ),
      ),
    );
  }
}

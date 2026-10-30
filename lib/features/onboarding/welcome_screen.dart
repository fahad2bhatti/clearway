import 'package:flutter/material.dart';
import '../../core/clearway_strings.dart';
import '../../data/local_save.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({
    super.key,
    required this.save,
    required this.onContinue,
  });

  final LocalSave save;
  final VoidCallback onContinue;

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  bool _termsAccepted = false;
  bool _privacyAccepted = false;
  bool _busy = false;

  ClearwayStrings get strings => ClearwayStrings(widget.save.language);

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy) return;
    if (!_formKey.currentState!.validate() || !_termsAccepted || !_privacyAccepted) {
      return;
    }
    setState(() => _busy = true);
    try {
      await widget.save.setUsername(_usernameController.text);
      await widget.save.setTermsAccepted(true);
      widget.onContinue();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(strings.usernameError)),
      );
    } finally {
      setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(strings.welcomeTitle),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: <Widget> [
              Text(strings.welcomeMessage, style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 24),
              TextFormField(
                controller: _usernameController,
                decoration: InputDecoration(
                  labelText: strings.username,
                  hintText: strings.usernameHint,
                  border: const OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return strings.usernameRequired;
                  }
                  if (value.length < 3 || value.length > 15) {
                    return strings.usernameLength;
                  }
                  if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(value)) {
                    return strings.usernameInvalidChars;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              CheckboxListTile(
                title: Text(strings.terms),
                value: _termsAccepted,
                onChanged: (value) => setState(() => _termsAccepted = value ?? false),
              ),
              CheckboxListTile(
                title: Text(strings.privacyPolicy),
                value: _privacyAccepted,
                onChanged: (value) => setState(() => _privacyAccepted = value ?? false),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _busy ? null : _submit,
                child: _busy ? const CircularProgressIndicator() : Text(strings.continueButton),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
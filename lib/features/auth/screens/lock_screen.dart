import 'package:flutter/material.dart';
import '../../../core/services/biometric_service.dart';

/// Lock screen for biometric/PIN authentication
class LockScreen extends StatefulWidget {
  final VoidCallback onAuthenticated;

  const LockScreen({
    super.key,
    required this.onAuthenticated,
  });

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  final BiometricService _biometricService = BiometricService();
  final TextEditingController _pinController = TextEditingController();
  String _errorMessage = '';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tryBiometricAuth();
  }

  Future<void> _tryBiometricAuth() async {
    final biometricEnabled = await _biometricService.isBiometricEnabled();
    if (biometricEnabled) {
      final authenticated =
          await _biometricService.authenticateWithBiometrics();
      if (authenticated) {
        widget.onAuthenticated();
      }
    }
  }

  Future<void> _verifyPin() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    final isValid = await _biometricService.verifyPin(_pinController.text);

    setState(() => _isLoading = false);

    if (isValid) {
      widget.onAuthenticated();
    } else {
      setState(() {
        _errorMessage = 'Incorrect PIN';
        _pinController.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.lock_outline,
                size: 80,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 24),
              Text(
                'Yepsy is Locked',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Enter your PIN to unlock',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
              const SizedBox(height: 48),
              TextField(
                controller: _pinController,
                obscureText: true,
                keyboardType: TextInputType.number,
                maxLength: 4,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 24,
                  letterSpacing: 16,
                ),
                decoration: InputDecoration(
                  hintText: '••••',
                  errorText: _errorMessage.isEmpty ? null : _errorMessage,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  counterText: '',
                ),
                onSubmitted: (_) => _verifyPin(),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _verifyPin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text('Unlock'),
                ),
              ),
              const SizedBox(height: 16),
              FutureBuilder<bool>(
                future: _biometricService.isBiometricAvailable(),
                builder: (context, snapshot) {
                  if (snapshot.data == true) {
                    return TextButton.icon(
                      onPressed: _tryBiometricAuth,
                      icon: const Icon(Icons.fingerprint),
                      label: const Text('Use Biometric'),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }
}

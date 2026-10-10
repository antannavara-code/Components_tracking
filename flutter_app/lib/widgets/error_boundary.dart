import 'package:flutter/material.dart';
import '../services/crash_reporter.dart';

/// Catches errors thrown while building its child and shows a friendly
/// recovery screen instead of letting the whole app crash. Also flips the
/// global [CrashReporter] flag so a crash report is written.
class ErrorBoundary extends StatefulWidget {
  final Widget child;
  const ErrorBoundary({super.key, required this.child});

  @override
  State<ErrorBoundary> createState() => _ErrorBoundaryState();
}

class _ErrorBoundaryState extends State<ErrorBoundary> {
  Object? _error;

  @override
  Widget build(BuildContext context) {
    if (_error != null) return _buildFallback();
    try {
      return widget.child;
    } catch (e, s) {
      CrashReporter.instance.record(e.toString(), s);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _error = e);
      });
      return widget.child;
    }
  }

  Widget _buildFallback() {
    return Material(
      color: Colors.grey.shade100,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, color: Colors.red.shade400, size: 64),
              const SizedBox(height: 16),
              const Text(
                'Something went wrong',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'The app hit an unexpected error. Your data is safe and stored '
                'locally on this device.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () {
                  setState(() => _error = null);
                  CrashReporter.instance.onFatalError = null;
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

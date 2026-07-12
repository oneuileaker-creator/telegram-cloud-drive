
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../bloc/auth_bloc.dart';

class TelegramConnectScreen extends StatefulWidget {
  const TelegramConnectScreen({super.key});

  @override
  State<TelegramConnectScreen> createState() => _TelegramConnectScreenState();
}

class _TelegramConnectScreenState extends State<TelegramConnectScreen> {
  final _apiIdCtrl    = TextEditingController();
  final _apiHashCtrl  = TextEditingController();
  final _phoneCtrl    = TextEditingController();
  final _codeCtrl     = TextEditingController();

  bool _codeSent = false;
  String _phoneCodeHash = '';
  int _step = 0; // 0=credentials, 1=code

  @override
  void dispose() {
    _apiIdCtrl.dispose();
    _apiHashCtrl.dispose();
    _phoneCtrl.dispose();
    _codeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is TelegramCodeSent) {
            setState(() {
              _phoneCodeHash = state.phoneCodeHash;
              _step = 1;
            });
          }
          if (state is AuthAuthenticated) {
            context.go('/home');
          }
          if (state is AuthError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error,
              ),
            );
          }
        },
        builder: (context, state) {
          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),

                  // Telegram Icon Header
                  Center(
                    child: Container(
                      width: 80, height: 80,
                      decoration: BoxDecoration(
                        color: const Color(0xFF2AABEE).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: const Icon(
                        Icons.telegram,
                        color: Color(0xFF2AABEE),
                        size: 44,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  Center(
                    child: Text(
                      'Connect Telegram',
                      style: AppTextStyles.displayMedium,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: Text(
                      'Your Telegram account will be used\nas unlimited cloud storage',
                      style: AppTextStyles.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Step indicator
                  Row(
                    children: [
                      _StepChip(label: '1', title: 'Credentials', active: _step == 0, done: _step > 0),
                      Expanded(child: Divider(color: AppColors.surfaceLight)),
                      _StepChip(label: '2', title: 'Verify', active: _step == 1, done: false),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Step 0: Credentials
                  if (_step == 0) ...[
                    _infoCard(),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _apiIdCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'API ID',
                        prefixIcon: Icon(Icons.tag_rounded),
                        hintText: 'e.g. 12345678',
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _apiHashCtrl,
                      decoration: const InputDecoration(
                        labelText: 'API Hash',
                        prefixIcon: Icon(Icons.key_rounded),
                        hintText: 'e.g. abc123...',
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _phoneCtrl,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Phone Number',
                        prefixIcon: Icon(Icons.phone_rounded),
                        hintText: '+1234567890',
                      ),
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: state is AuthLoading ? null : () {
                          context.read<AuthBloc>().add(
                            TelegramConnectRequested(
                              int.parse(_apiIdCtrl.text.trim()),
                              _apiHashCtrl.text.trim(),
                              _phoneCtrl.text.trim(),
                            ),
                          );
                        },
                        child: state is AuthLoading
                          ? const SizedBox(
                              width: 20, height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2,
                              ),
                            )
                          : const Text('Send Code'),
                      ),
                    ),
                  ],

                  // Step 1: Verify code
                  if (_step == 1) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.bgCard,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.sms_rounded,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Code sent to ${_phoneCtrl.text}',
                              style: AppTextStyles.bodyMedium,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _codeCtrl,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.displayMedium.copyWith(
                        letterSpacing: 12,
                      ),
                      maxLength: 5,
                      decoration: const InputDecoration(
                        labelText: 'Verification Code',
                        counterText: '',
                        hintText: '· · · · ·',
                      ),
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: state is AuthLoading ? null : () {
                          context.read<AuthBloc>().add(
                            TelegramVerifyRequested(
                              _phoneCtrl.text.trim(),
                              _codeCtrl.text.trim(),
                              _phoneCodeHash,
                            ),
                          );
                        },
                        child: state is AuthLoading
                          ? const SizedBox(
                              width: 20, height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2,
                              ),
                            )
                          : const Text('Verify & Connect'),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: TextButton(
                        onPressed: () => setState(() => _step = 0),
                        child: const Text('← Change number'),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _infoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline, color: AppColors.primary, size: 18),
              const SizedBox(width: 8),
              Text('How to get API credentials',
                style: AppTextStyles.titleMedium.copyWith(
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '1. Go to my.telegram.org\n'
            '2. Log in with your phone number\n'
            '3. Click "API Development Tools"\n'
            '4. Create an app to get API ID & Hash',
            style: AppTextStyles.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _StepChip extends StatelessWidget {
  final String label;
  final String title;
  final bool active;
  final bool done;

  const _StepChip({
    required this.label,
    required this.title,
    required this.active,
    required this.done,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 32, height: 32,
          decoration: BoxDecoration(
            color: active || done
              ? AppColors.primary
              : AppColors.bgCard,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: done
              ? const Icon(Icons.check, color: Colors.white, size: 16)
              : Text(
                  label,
                  style: TextStyle(
                    color: active ? Colors.white : AppColors.textHint,
                    fontWeight: FontWeight.bold,
                  ),
                ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: AppTextStyles.caption.copyWith(
            color: active ? AppColors.primary : AppColors.textHint,
          ),
        ),
      ],
    );
  }
}

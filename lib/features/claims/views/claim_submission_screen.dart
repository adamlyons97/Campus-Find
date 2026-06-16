import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/theme.dart';
import '../../../data/models/item_model.dart';
import '../providers/claim_status_provider.dart';

class ClaimSubmissionScreen extends ConsumerStatefulWidget {
  const ClaimSubmissionScreen({super.key, required this.item});

  final ItemModel item;

  @override
  ConsumerState<ClaimSubmissionScreen> createState() =>
      _ClaimSubmissionScreenState();
}

class _ClaimSubmissionScreenState
    extends ConsumerState<ClaimSubmissionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _proof = TextEditingController();

  @override
  void dispose() {
    _proof.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final ok = await ref.read(claimControllerProvider.notifier).submit(
          itemId: widget.item.id,
          itemTitle: widget.item.title,
          reporterId: widget.item.reporterId,
          proofOfOwnership: _proof.text,
        );
    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Claim submitted. A verifier will review your proof shortly.'),
        ),
      );
      context.pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ref.read(claimControllerProvider).error.toString()),
          backgroundColor: AppTheme.danger,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(claimControllerProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Claim This Item')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.shield_outlined, color: AppTheme.primary),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        AppStrings.luqatahClaimantNotice,
                        style: TextStyle(fontSize: 12.5),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Text('Claiming: ${widget.item.title}',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextFormField(
                controller: _proof,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: 'Proof of Ownership',
                  hintText: AppStrings.claimVerificationHint,
                  alignLabelWithHint: true,
                ),
                validator: (v) {
                  if (v == null || v.trim().length < 10) {
                    return 'Please describe a specific private detail '
                        '(at least 10 characters).';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: state.isLoading ? null : _submit,
                icon: state.isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.verified_outlined),
                label: const Text('Submit Claim for Verification'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

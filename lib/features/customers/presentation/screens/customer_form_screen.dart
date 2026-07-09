import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../tenants/presentation/providers/tenant_provider.dart';
import '../../data/models/customer_model.dart';
import '../providers/customers_provider.dart';
import '../widgets/phone_country.dart';

class CustomerFormScreen extends ConsumerStatefulWidget {
  final String? customerId;

  const CustomerFormScreen({super.key, this.customerId});

  @override
  ConsumerState<CustomerFormScreen> createState() =>
      _CustomerFormScreenState();
}

class _CustomerFormScreenState extends ConsumerState<CustomerFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  PhoneCountry _country = PhoneCountry.us;
  bool _loading = false;
  bool _initialized = false;

  bool get isEditing => widget.customerId != null;

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  void _initFromCustomer(CustomerModel customer) {
    if (_initialized) return;
    _initialized = true;
    _firstNameCtrl.text = customer.firstName;
    _lastNameCtrl.text = customer.lastName;
    _emailCtrl.text = customer.email ?? '';
    _notesCtrl.text = customer.notes ?? '';

    final detected = PhoneCountry.detectFromE164(customer.phone);
    _country = detected;
    final local = detected.localDigitsFromE164(customer.phone);
    _phoneCtrl.text = detected.formatLocal(local);
  }

  void _applyPhoneFormatting(String raw) {
    final formatted = _country.formatLocal(raw);
    if (formatted == _phoneCtrl.text) return;
    _phoneCtrl.value = TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }

  Future<void> _pickCountry() async {
    final selected = await showModalBottomSheet<PhoneCountry>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _CountryPickerSheet(selected: _country),
    );
    if (selected == null || !mounted) return;
    setState(() {
      _country = selected;
      _applyPhoneFormatting(_phoneCtrl.text);
    });
  }

  String? _composePhoneForApi() => _country.composeE164(_phoneCtrl.text);

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    final fullName =
        '${_firstNameCtrl.text.trim()} ${_lastNameCtrl.text.trim()}'.trim();
    final phone = _composePhoneForApi();

    String? error;
    if (isEditing) {
      error = await ref.read(customersProvider.notifier).updateCustomer(
        widget.customerId!,
        {
          'full_name': fullName,
          if (_emailCtrl.text.isNotEmpty) 'email': _emailCtrl.text.trim(),
          if (phone != null) 'phone': phone,
          if (_notesCtrl.text.isNotEmpty) 'notes': _notesCtrl.text.trim(),
        },
      );
    } else {
      try {
        final tenantId = await ref.read(currentTenantIdProvider.future);
        error = await ref.read(customersProvider.notifier).createCustomer(
              CustomerCreateRequest(
                fullName: fullName,
                tenantId: tenantId,
                email: _emailCtrl.text.isNotEmpty
                    ? _emailCtrl.text.trim()
                    : null,
                phone: phone,
                notes: _notesCtrl.text.isNotEmpty
                    ? _notesCtrl.text.trim()
                    : null,
              ),
            );
      } catch (e) {
        error = e.toString().replaceFirst('Exception: ', '');
      }
    }

    if (mounted) {
      setState(() => _loading = false);
      if (error == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppStrings.savedSuccess),
            backgroundColor: AppColors.accent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
        );
        context.pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error),
            backgroundColor: AppColors.destructive,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isEditing) {
      final customerAsync =
          ref.watch(customerDetailProvider(widget.customerId!));
      customerAsync.whenData(_initFromCustomer);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Client' : AppStrings.newCustomer),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                AppTextField(
                  controller: _firstNameCtrl,
                  label: 'First Name',
                  hint: 'Jane',
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                AppTextField(
                  controller: _lastNameCtrl,
                  label: 'Last Name',
                  hint: 'Smith',
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                AppTextField(
                  controller: _emailCtrl,
                  label: 'Email (optional)',
                  hint: 'jane@example.com',
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),
                _PhoneField(
                  controller: _phoneCtrl,
                  country: _country,
                  onCountryTap: _pickCountry,
                  onChanged: _applyPhoneFormatting,
                  validator: _country.validateLocal,
                ),
                const SizedBox(height: 16),
                AppTextField(
                  controller: _notesCtrl,
                  label: 'Notes (optional)',
                  hint: 'Allergies, preferences…',
                  maxLines: 4,
                ),
                const SizedBox(height: 32),
                AppButton(
                  label: isEditing ? AppStrings.save : 'Add Client',
                  onPressed: _loading ? null : _submit,
                  isLoading: _loading,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PhoneField extends StatelessWidget {
  final TextEditingController controller;
  final PhoneCountry country;
  final VoidCallback onCountryTap;
  final ValueChanged<String>? onChanged;
  final String? Function(String?)? validator;

  const _PhoneField({
    required this.controller,
    required this.country,
    required this.onCountryTap,
    this.onChanged,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Phone (optional)',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: cs.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: TextInputType.phone,
          textInputAction: TextInputAction.next,
          validator: validator,
          onChanged: onChanged,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9 ]')),
            LengthLimitingTextInputFormatter(country.inputMaxChars),
          ],
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 15,
            color: cs.onSurface,
          ),
          decoration: InputDecoration(
            hintText: country.hint,
            prefixIcon: Padding(
              padding: const EdgeInsets.only(left: 8, right: 6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  InkWell(
                    onTap: onCountryTap,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.primary.withValues(alpha: 0.15)
                            : const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isDark
                              ? AppColors.primary.withValues(alpha: 0.3)
                              : const Color(0xFFBFDBFE),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(country.flag,
                              style: const TextStyle(fontSize: 14)),
                          const SizedBox(width: 6),
                          Text(
                            country.dialCodeLabel,
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: 2),
                          const Icon(
                            Icons.keyboard_arrow_down_rounded,
                            size: 18,
                            color: AppColors.primary,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    width: 1,
                    height: 24,
                    color: cs.outline,
                  ),
                ],
              ),
            ),
            prefixIconConstraints: const BoxConstraints(
              minWidth: 0,
              minHeight: 0,
            ),
          ),
        ),
      ],
    );
  }
}

class _CountryPickerSheet extends StatefulWidget {
  final PhoneCountry selected;

  const _CountryPickerSheet({required this.selected});

  @override
  State<_CountryPickerSheet> createState() => _CountryPickerSheetState();
}

class _CountryPickerSheetState extends State<_CountryPickerSheet> {
  final _searchCtrl = TextEditingController();
  late List<PhoneCountry> _filtered;

  @override
  void initState() {
    super.initState();
    _filtered = PhoneCountry.all;
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _filter(String query) {
    final q = query.trim().toLowerCase();
    setState(() {
      if (q.isEmpty) {
        _filtered = PhoneCountry.all;
        return;
      }
      _filtered = PhoneCountry.all.where((c) {
        return c.name.toLowerCase().contains(q) ||
            c.dialCode.contains(q) ||
            c.iso2.toLowerCase().contains(q) ||
            '+${c.dialCode}'.contains(q);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.72,
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: cs.outline,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Select country',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _searchCtrl,
                onChanged: _filter,
                decoration: const InputDecoration(
                  hintText: 'Search country or code',
                  prefixIcon: Icon(Icons.search_rounded),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.separated(
                itemCount: _filtered.length,
                separatorBuilder: (_, __) =>
                    Divider(height: 1, color: cs.outline.withValues(alpha: 0.4)),
                itemBuilder: (context, index) {
                  final country = _filtered[index];
                  final selected = country.iso2 == widget.selected.iso2 &&
                      country.dialCode == widget.selected.dialCode;
                  return ListTile(
                    onTap: () => Navigator.of(context).pop(country),
                    leading: Text(country.flag,
                        style: const TextStyle(fontSize: 22)),
                    title: Text(
                      country.name,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(country.dialCodeLabel),
                    trailing: selected
                        ? const Icon(Icons.check_rounded,
                            color: AppColors.primary)
                        : null,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

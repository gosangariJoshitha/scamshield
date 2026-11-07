import 'package:flutter/material.dart';

import '../../models/emergency_contact_models.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../services/emergency_contacts_service.dart';
import '../../theme/app_colors.dart';

class EmergencyContactsScreen extends StatefulWidget {
  const EmergencyContactsScreen({
    this.emergencyContactsService,
    this.authService,
    this.isDarkMode = false,
    super.key,
  });

  final EmergencyContactsService? emergencyContactsService;
  final AuthService? authService;
  final bool isDarkMode;

  @override
  State<EmergencyContactsScreen> createState() => _EmergencyContactsScreenState();
}

class _EmergencyContactsScreenState extends State<EmergencyContactsScreen> {
  late final EmergencyContactsService _service;
  List<EmergencyContact> _contacts = [];
  bool _isLoading = true;
  String? _errorMessage;
  bool _isSendingTestAlert = false;

  @override
  void initState() {
    super.initState();
    final auth = widget.authService ?? AuthService(api: ApiService());
    _service = widget.emergencyContactsService ??
        EmergencyContactsService(
          api: ApiService(),
          authService: auth,
        );
    _loadContacts();
  }

  Future<void> _loadContacts() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final contacts = await _service.getContacts();
      if (mounted) {
        setState(() {
          _contacts = contacts;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _showAddContactSheet() async {
    if (_contacts.length >= 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Maximum limit of 3 emergency contacts reached.'),
        ),
      );
      return;
    }

    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    String relationship = 'Family';
    bool notifySms = true;
    String? validationError;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: widget.isDarkMode ? AppColors.darkCard : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final isDark = widget.isDarkMode;
            final textColor = isDark ? AppColors.textMainDark : AppColors.textMainLight;
            final subtextColor = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
            final errorColor = isDark ? AppColors.riskCriticalDark : AppColors.riskCriticalLight;

            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 24,
                bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Add Emergency Contact',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.close, color: subtextColor),
                          onPressed: () => Navigator.of(sheetContext).pop(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'This contact will receive SMS warnings when Sentinel detects a high-risk scam call (>=70% risk).',
                      style: TextStyle(fontSize: 13, color: subtextColor),
                    ),
                    const SizedBox(height: 16),
                    if (validationError != null) ...[
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: errorColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          validationError!,
                          style: TextStyle(
                            color: errorColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    TextField(
                      controller: nameController,
                      style: TextStyle(color: textColor),
                      decoration: InputDecoration(
                        labelText: 'Full Name',
                        prefixIcon: const Icon(Icons.person_outline),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: phoneController,
                      keyboardType: TextInputType.phone,
                      style: TextStyle(color: textColor),
                      decoration: InputDecoration(
                        labelText: 'Phone Number (e.g. +1234567890)',
                        prefixIcon: const Icon(Icons.phone_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      initialValue: relationship,
                      dropdownColor: isDark ? AppColors.darkCard : Colors.white,
                      style: TextStyle(color: textColor),
                      decoration: InputDecoration(
                        labelText: 'Relationship',
                        prefixIcon: const Icon(Icons.people_outline),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'Family', child: Text('Family')),
                        DropdownMenuItem(value: 'Parent', child: Text('Parent')),
                        DropdownMenuItem(value: 'Spouse', child: Text('Spouse')),
                        DropdownMenuItem(value: 'Child', child: Text('Child')),
                        DropdownMenuItem(value: 'Sibling', child: Text('Sibling')),
                        DropdownMenuItem(value: 'Friend', child: Text('Friend')),
                        DropdownMenuItem(value: 'Guardian', child: Text('Guardian')),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setSheetState(() => relationship = val);
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        'Enable SMS Family Alerts',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: textColor,
                        ),
                      ),
                      subtitle: Text(
                        'Send immediate automated text on high-risk call',
                        style: TextStyle(fontSize: 12, color: subtextColor),
                      ),
                      value: notifySms,
                      onChanged: (val) => setSheetState(() => notifySms = val),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: FilledButton.icon(
                        icon: const Icon(Icons.check),
                        label: const Text('Save Contact'),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: () async {
                          final name = nameController.text.trim();
                          final phone = phoneController.text.trim();
                          if (name.isEmpty) {
                            setSheetState(() => validationError = 'Please enter contact name.');
                            return;
                          }
                          if (phone.length < 5) {
                            setSheetState(() => validationError = 'Please enter a valid phone number.');
                            return;
                          }

                          Navigator.of(sheetContext).pop();
                          try {
                            await _service.addContact(
                              name: name,
                              phoneNumber: phone,
                              relationshipType: relationship,
                              notifySms: notifySms,
                            );
                            await _loadContacts();
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Emergency contact added successfully.')),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Failed to add contact: $e')),
                              );
                            }
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _toggleContactSms(EmergencyContact contact, bool val) async {
    try {
      final updated = await _service.updateContact(contact.id, notifySms: val);
      setState(() {
        final index = _contacts.indexWhere((c) => c.id == contact.id);
        if (index != -1) {
          _contacts[index] = updated;
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not update contact: $e')),
        );
      }
    }
  }

  Future<void> _deleteContact(EmergencyContact contact) async {
    final isDark = widget.isDarkMode;
    final errorColor = isDark ? AppColors.riskCriticalDark : AppColors.riskCriticalLight;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Remove Contact?'),
        content: Text(
          'Are you sure you want to remove ${contact.name} from your emergency alerts list?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: errorColor),
            onPressed: () => Navigator.of(dialogCtx).pop(true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _service.deleteContact(contact.id);
        setState(() {
          _contacts.removeWhere((c) => c.id == contact.id);
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Emergency contact removed.')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to remove contact: $e')),
          );
        }
      }
    }
  }

  Future<void> _sendTestAlert() async {
    if (_contacts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one emergency contact first.')),
      );
      return;
    }

    final isDark = widget.isDarkMode;
    final successColor = isDark ? AppColors.riskLowDark : AppColors.riskLowLight;
    final errorColor = isDark ? AppColors.riskCriticalDark : AppColors.riskCriticalLight;

    setState(() => _isSendingTestAlert = true);
    try {
      final res = await _service.sendTestAlert(
        sessionId: 'test-${DateTime.now().millisecondsSinceEpoch}',
        riskScore: 92,
        detectedCategory: 'Urgent Impersonation Test',
      );
      final count = res['dispatched_count'] as int? ?? _contacts.length;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: successColor,
            content: Text('Test alert dispatched to $count contact(s)!'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: errorColor,
            content: Text('Failed to send test alert: $e'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSendingTestAlert = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDarkMode;
    final textColor = isDark ? AppColors.textMainDark : AppColors.textMainLight;
    final subtextColor = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final cardColor = isDark ? AppColors.darkCard : Colors.white;
    final errorColor = isDark ? AppColors.riskCriticalDark : AppColors.riskCriticalLight;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        title: const Text('Emergency Contacts'),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadContacts,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            children: [
              // Info Banner Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.shield_outlined,
                      color: AppColors.primary,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Sentinel Family Safety Net',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Add up to 3 trusted contacts. When Sentinel identifies high-risk scam calls (>=70% risk), automatic SMS alerts are immediately sent so your family can intervene.',
                            style: TextStyle(
                              fontSize: 13,
                              color: subtextColor,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Header Row with count
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Configured Contacts (${_contacts.length}/3)',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: textColor,
                    ),
                  ),
                  if (_contacts.length < 3)
                    TextButton.icon(
                      onPressed: _showAddContactSheet,
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Add Contact'),
                    ),
                ],
              ),
              const SizedBox(height: 8),

              // Contact List or Status
              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Column(
                    children: [
                      Icon(Icons.error_outline, size: 40, color: errorColor),
                      const SizedBox(height: 8),
                      Text(
                        _errorMessage!,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: subtextColor),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton(
                        onPressed: _loadContacts,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              else if (_contacts.isEmpty)
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 20),
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.06),
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.family_restroom_rounded,
                        size: 54,
                        color: subtextColor.withValues(alpha: 0.5),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'No Emergency Contacts Yet',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Add up to 3 family members or guardians to receive automated scam warnings.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 13, color: subtextColor),
                      ),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: _showAddContactSheet,
                        icon: const Icon(Icons.person_add_rounded),
                        label: const Text('Add First Contact'),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                )
              else
                ..._contacts.map((contact) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.06),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 20,
                              backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                              child: Text(
                                contact.name.isNotEmpty
                                    ? contact.name[0].toUpperCase()
                                    : '?',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Flexible(
                                        child: Text(
                                          contact.name,
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold,
                                            color: textColor,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.primary.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          contact.relationshipType,
                                          style: const TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.primary,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    contact.phoneNumber,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: subtextColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: Icon(
                                Icons.delete_outline_rounded,
                                color: errorColor,
                              ),
                              tooltip: 'Remove contact',
                              onPressed: () => _deleteContact(contact),
                            ),
                          ],
                        ),
                        const Divider(height: 18),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.sms_outlined,
                                  size: 16,
                                  color: contact.notifySms
                                      ? AppColors.primary
                                      : subtextColor,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'SMS Alerts on High Risk',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: contact.notifySms ? textColor : subtextColor,
                                  ),
                                ),
                              ],
                            ),
                            Switch.adaptive(
                              value: contact.notifySms,
                              activeTrackColor: AppColors.primary,
                              onChanged: (val) => _toggleContactSms(contact, val),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }),

              const SizedBox(height: 16),

              // Send Test Alert Section
              if (_contacts.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.06),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Test Family Alerts',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Send a safe simulated test SMS to all configured active contacts to verify delivery.',
                        style: TextStyle(fontSize: 12, color: subtextColor),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        height: 44,
                        child: OutlinedButton.icon(
                          onPressed: _isSendingTestAlert ? null : _sendTestAlert,
                          icon: _isSendingTestAlert
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.send_rounded, size: 16),
                          label: Text(_isSendingTestAlert ? 'Sending...' : 'Send Test Alert'),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

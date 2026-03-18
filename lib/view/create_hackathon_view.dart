import 'package:flutter/material.dart';
import '../model/hackathon.dart';
import '../viewmodel/create_hackathon_controller.dart';
import '../widgets/buildmate_app_bar.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CreateHackathonView extends StatefulWidget {
  const CreateHackathonView({super.key});

  @override
  State<CreateHackathonView> createState() => _CreateHackathonViewState();
}

class _CreateHackathonViewState extends State<CreateHackathonView> {
  final _formKey = GlobalKey<FormState>();
  final CreateHackathonController _controller = CreateHackathonController();

  // Text fields
  final TextEditingController nameController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController teamSizeController = TextEditingController();
  final TextEditingController cityController = TextEditingController();
  final TextEditingController locationController = TextEditingController();
  final TextEditingController otherDomainController = TextEditingController();
  List<TextEditingController> otherRoleControllers = [TextEditingController()];

  // Dropdown values
  String? selectedMode;
  String? selectedDomain;
  String? selectedEducation;

  // Dates
  DateTime? applicationOpenDate;
  DateTime? applicationDeadline;
  DateTime? startDate;
  DateTime? endDate;

  // Date errors
  String? applicationOpenDateError;
  String? applicationDeadlineError;
  String? startDateError;
  String? endDateError;

  // UI state
  bool isSubmitting = false;

  final List<String> domains = const [
    'AI & Data Science',
    'Healthtech',
    'FinTech',
    'EduTech',
    'Sustainability & Social Good',
    'Gaming & Entertainment',
    'General',
    'Other',
  ];

  final List<String> modes = const [
    'Online',
    'Onsite',
    'Hybrid',
  ];

  final List<String> educationOptions = const [
    'Any',
    'University Students',
    'High School',
    'Professionals',
  ];

  List<String> selectedRoles = [];

  final List<String> availableRoles = const [
    'Designer',
    'Flutter Developer',
    'Backend Developer',
    'UI/UX',
    'Data Analyst',
    'Other',
  ];

  static const Color purple = Color(0xFF6D56B3);

  int get _maxRoles {
    final n = int.tryParse(teamSizeController.text.trim());
    if (n != null && n >= 2) return n;
    return availableRoles.length;
  }

  @override
  void dispose() {
    nameController.dispose();
    descriptionController.dispose();
    teamSizeController.dispose();
    cityController.dispose();
    locationController.dispose();
    otherDomainController.dispose();
    for (final c in otherRoleControllers) {
      c.dispose();
    }
    super.dispose();
  }

  InputDecoration _fieldDecoration({
    required String label,
    required IconData icon,
    String? hint,
    String? errorText,
  }) {
    return InputDecoration(
      labelText: label,
      errorMaxLines: 2,
      hintText: hint,
      prefixIcon: Icon(icon, color: purple),
      errorText: errorText,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade400, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: purple, width: 1.6),
      ),
    );
  }

  ButtonStyle _primaryButtonStyle() {
    return ElevatedButton.styleFrom(
      backgroundColor: purple,
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 0,
    );
  }

  String _formatDate(DateTime? d) {
    if (d == null) return "";
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return "$y-$m-$day";
  }

  Future<void> _pickApplicationOpenDate() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final picked = await showDatePicker(
      context: context,
      initialDate: applicationOpenDate ?? today,
      firstDate: today,
      lastDate: DateTime(now.year + 5),
    );

    if (picked == null) return;

    setState(() {
      applicationOpenDate = picked;
      applicationOpenDateError = null;

      if (applicationDeadline != null &&
          applicationDeadline!.isBefore(picked)) {
        applicationDeadline = null;
      }

      if (startDate != null && startDate!.isBefore(picked)) {
        startDate = null;
      }

      if (endDate != null && startDate == null) {
        endDate = null;
      }

      applicationDeadlineError = null;
      startDateError = null;
      endDateError = null;
    });
  }

  Future<void> _pickApplicationDeadline() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final base = applicationOpenDate ?? today;

    final picked = await showDatePicker(
      context: context,
      initialDate: applicationDeadline ?? base,
      firstDate: base,
      lastDate: DateTime(now.year + 5),
    );

    if (picked == null) return;

    setState(() {
      applicationDeadline = picked;
      applicationDeadlineError = null;

      if (startDate != null && startDate!.isBefore(picked)) {
        startDate = null;
      }

      if (endDate != null && startDate == null) {
        endDate = null;
      }

      startDateError = null;
      endDateError = null;
    });
  }

  Future<void> _pickStartDate() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final base = applicationDeadline ?? today;

    final picked = await showDatePicker(
      context: context,
      initialDate: startDate ?? base,
      firstDate: base,
      lastDate: DateTime(now.year + 5),
    );

    if (picked == null) return;

    setState(() {
      startDate = picked;
      startDateError = null;

      if (endDate != null && endDate!.isBefore(picked)) {
        endDate = null;
      }
      endDateError = null;
    });
  }

  Future<void> _pickEndDate() async {
    final now = DateTime.now();
    final base = startDate ?? now;

    final picked = await showDatePicker(
      context: context,
      initialDate: endDate ?? base,
      firstDate: base,
      lastDate: DateTime(now.year + 5),
    );

    if (picked == null) return;

    setState(() {
      endDate = picked;
      endDateError = null;
    });
  }

  Future<void> _submit() async {
    final isFormValid = _formKey.currentState!.validate();

    setState(() {
      applicationOpenDateError =
      (applicationOpenDate == null) ? "Required" : null;
      applicationDeadlineError =
      (applicationDeadline == null) ? "Required" : null;
      startDateError = (startDate == null) ? "Required" : null;
      endDateError = (endDate == null) ? "Required" : null;
    });

    if (!isFormValid ||
        applicationOpenDate == null ||
        applicationDeadline == null ||
        startDate == null ||
        endDate == null) {
      return;
    }

    if (applicationDeadline!.isBefore(applicationOpenDate!)) {
      setState(() {
        applicationDeadlineError = "Must be after registration opens";
      });
      return;
    }

    if (startDate!.isBefore(applicationDeadline!)) {
      setState(() {
        startDateError = "Must be on or after registration deadline";
      });
      return;
    }

    if (endDate!.isBefore(startDate!)) {
      setState(() {
        endDateError = "Must be on or after start date";
      });
      return;
    }

    if (selectedRoles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select at least one role.")),
      );
      return;
    }

    setState(() => isSubmitting = true);

    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("You must be logged in")),
      );
      setState(() => isSubmitting = false);
      return;
    }

    final otherRoles = otherRoleControllers
        .map((c) => c.text.trim())
        .where((t) => t.isNotEmpty)
        .toList();

    final hackathon = Hackathon(
      organizationId: currentUserId,
      name: nameController.text.trim(),
      description: descriptionController.text.trim(),
      domain: selectedDomain == 'Other'
          ? otherDomainController.text.trim()
          : (selectedDomain ?? "").trim(),
      teamSize: int.tryParse(teamSizeController.text.trim()) ?? 0,
      city: cityController.text.trim(),
      location: locationController.text.trim(),
      mode: (selectedMode ?? "").trim(),
      rolesNeeded: [
        ...selectedRoles.where((r) => r != "Other"),
        ...otherRoles,
      ],
      educationCriteria: (selectedEducation ?? "").trim(),
      applicationOpenDate: applicationOpenDate!,
      applicationDeadline: applicationDeadline!,
      startDate: startDate!,
      endDate: endDate!,
    );

    try {
      await _controller.submit(hackathon);
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Hackathon saved successfully ✅")),
      );

      _formKey.currentState!.reset();
      nameController.clear();
      descriptionController.clear();
      teamSizeController.clear();
      cityController.clear();
      locationController.clear();
      otherDomainController.clear();

      for (final c in otherRoleControllers) {
        c.dispose();
      }

      setState(() {
        selectedMode = null;
        selectedDomain = null;
        selectedEducation = null;
        selectedRoles = [];
        applicationOpenDate = null;
        applicationDeadline = null;
        startDate = null;
        endDate = null;
        applicationOpenDateError = null;
        applicationDeadlineError = null;
        startDateError = null;
        endDateError = null;
        otherRoleControllers = [TextEditingController()];
      });
    } catch (e) {
      if (!mounted) return;

      String message = "Something went wrong. Please try again.";
      if (e.toString().contains("TimeoutException")) {
        message = "No internet connection. Please check your network.";
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } finally {
      if (mounted) setState(() => isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: BuildMateAppBar(
        titleText: "Create Hackathon",
        showBack: true,
        onBack: () => Navigator.pop(context),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                _sectionTitle("Basic Info"),

                _textField(
                  controller: nameController,
                  label: "Hackathon Name",
                  icon: Icons.flag_outlined,
                  maxLength: 40,
                  maxLines: null,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return "Required";
                    if (v.trim().length < 5) return "Minimum 5 characters";
                    return null;
                  },
                ),

                _textField(
                  controller: descriptionController,
                  label: "Description",
                  icon: Icons.description_outlined,
                  maxLines: 3,
                  maxLength: 100,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return "Required";
                    if (v.trim().length < 20) return "Minimum 20 characters";
                    return null;
                  },
                ),

                _dropdownField(
                  label: "Domain",
                  icon: Icons.category_outlined,
                  value: selectedDomain,
                  items: domains,
                  onChanged: (v) => setState(() => selectedDomain = v),
                ),

                if (selectedDomain == 'Other')
                  _textField(
                    controller: otherDomainController,
                    label: "Specify Domain",
                    icon: Icons.edit_outlined,
                    maxLength: 40,
                    maxLines: null,
                    validator: (v) {
                      if (selectedDomain == 'Other' &&
                          (v == null || v.trim().isEmpty)) {
                        return "Required";
                      }
                      if (v != null && RegExp(r'^\d+$').hasMatch(v.trim())) {
                        return "Cannot be numbers only";
                      }
                      return null;
                    },
                  ),

                const SizedBox(height: 14),
                _sectionTitle("Details"),

                Row(
                  children: [
                    Expanded(
                      child: _textField(
                        controller: teamSizeController,
                        label: "Team Size",
                        icon: Icons.groups_outlined,
                        keyboardType: TextInputType.number,
                        onChanged: (_) => setState(() {
                          final max = _maxRoles;
                          if (selectedRoles.length > max) {
                            selectedRoles = selectedRoles.sublist(0, max);
                          }
                        }),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return "Required";
                          final n = int.tryParse(v.trim());
                          if (n == null || n < 2) {
                            return "Team size must be 2 or more";
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _dropdownField(
                        label: "Mode",
                        icon: Icons.public_outlined,
                        value: selectedMode,
                        items: modes,
                        onChanged: (v) => setState(() => selectedMode = v),
                      ),
                    ),
                  ],
                ),

                _textField(
                  controller: cityController,
                  maxLength: 40,
                  maxLines: null,
                  label: "City",
                  icon: Icons.location_city_outlined,
                ),

                _textField(
                  controller: locationController,
                  maxLength: 40,
                  maxLines: null,
                  label: "Location (e.g., Venue / Address)",
                  icon: Icons.place_outlined,
                ),

                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      InkWell(
                        onTap: () async {
                          final maxRoles = _maxRoles;

                          final result = await showDialog<List<String>>(
                            context: context,
                            builder: (context) {
                              List<String> tempSelected =
                              List.from(selectedRoles);

                              return StatefulBuilder(
                                builder: (context, setDialogState) {
                                  return AlertDialog(
                                    title: Text("Select Roles (max $maxRoles)"),
                                    content: SingleChildScrollView(
                                      child: Column(
                                        children: availableRoles.map((role) {
                                          final isSelected =
                                          tempSelected.contains(role);
                                          final isDisabled = !isSelected &&
                                              tempSelected.length >= maxRoles;

                                          return CheckboxListTile(
                                            value: isSelected,
                                            title: Text(
                                              role,
                                              style: TextStyle(
                                                color: isDisabled
                                                    ? Colors.grey
                                                    : null,
                                              ),
                                            ),
                                            onChanged: isDisabled
                                                ? null
                                                : (checked) {
                                              setDialogState(() {
                                                if (checked == true) {
                                                  if (!tempSelected
                                                      .contains(role)) {
                                                    tempSelected.add(role);
                                                  }
                                                } else {
                                                  tempSelected.remove(
                                                      role);
                                                }
                                              });
                                            },
                                          );
                                        }).toList(),
                                      ),
                                    ),
                                    actions: [
                                      if (tempSelected.length >= maxRoles)
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 4,
                                          ),
                                          child: Text(
                                            "Max $maxRoles roles reached",
                                            style: const TextStyle(
                                              color: Colors.orange,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(context),
                                        child: const Text("Cancel"),
                                      ),
                                      ElevatedButton(
                                        onPressed: () => Navigator.pop(
                                          context,
                                          tempSelected,
                                        ),
                                        style: _primaryButtonStyle(),
                                        child: const Text("Done"),
                                      ),
                                    ],
                                  );
                                },
                              );
                            },
                          );

                          if (result != null) {
                            setState(() {
                              selectedRoles = result;
                              if (!result.contains("Other")) {
                                for (final c in otherRoleControllers) {
                                  c.dispose();
                                }
                                otherRoleControllers = [
                                  TextEditingController(),
                                ];
                              }
                            });
                          }
                        },
                        child: InputDecorator(
                          decoration: _fieldDecoration(
                            label: "Roles Needed",
                            icon: Icons.work_outline,
                          ),
                          child: Text(
                            selectedRoles.isEmpty
                                ? "Select roles"
                                : selectedRoles.join(", "),
                          ),
                        ),
                      ),
                      if (selectedRoles.contains("Other"))
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ...List.generate(
                                otherRoleControllers.length,
                                    (index) => Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: TextFormField(
                                          controller:
                                          otherRoleControllers[index],
                                          textInputAction:
                                          TextInputAction.next,
                                          decoration: _fieldDecoration(
                                            label: otherRoleControllers.length >
                                                1
                                                ? "Other Role #${index + 1}"
                                                : "Other Role",
                                            icon: Icons.edit_outlined,
                                          ),
                                          maxLength: 40,
                                          maxLines: null,
                                          validator: (v) {
                                            if (index == 0 &&
                                                selectedRoles
                                                    .contains("Other") &&
                                                (v == null ||
                                                    v.trim().isEmpty)) {
                                              return "Required";
                                            }
                                            if (v != null &&
                                                v.trim().isNotEmpty &&
                                                RegExp(r'^\d+$')
                                                    .hasMatch(v.trim())) {
                                              return "Cannot be numbers only";
                                            }
                                            return null;
                                          },
                                        ),
                                      ),
                                      if (otherRoleControllers.length > 1)
                                        IconButton(
                                          icon: const Icon(
                                            Icons.remove_circle_outline,
                                            color: Colors.red,
                                          ),
                                          onPressed: () => setState(() {
                                            otherRoleControllers[index]
                                                .dispose();
                                            otherRoleControllers
                                                .removeAt(index);
                                          }),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                              TextButton.icon(
                                onPressed: (selectedRoles
                                    .where((r) => r != "Other")
                                    .length +
                                    otherRoleControllers.length) >=
                                    _maxRoles
                                    ? null
                                    : () => setState(() {
                                  otherRoleControllers.add(
                                    TextEditingController(),
                                  );
                                }),
                                icon: const Icon(
                                  Icons.add_circle_outline,
                                  size: 18,
                                ),
                                label: const Text("Add another role"),
                                style: TextButton.styleFrom(
                                  foregroundColor: purple,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),

                _dropdownField(
                  label: "Education Criteria",
                  icon: Icons.school_outlined,
                  value: selectedEducation,
                  items: educationOptions,
                  onChanged: (v) => setState(() => selectedEducation = v),
                ),

                const SizedBox(height: 14),
                _sectionTitle("Team Registration"),

                Row(
                  children: [
                    Expanded(
                      child: _dateField(
                        label: "Open Date",
                        icon: Icons.how_to_reg_outlined,
                        valueText: _formatDate(applicationOpenDate),
                        onTap: _pickApplicationOpenDate,
                        errorText: applicationOpenDateError,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _dateField(
                        label: "Close Date",
                        icon: Icons.event_busy_outlined,
                        valueText: _formatDate(applicationDeadline),
                        onTap: _pickApplicationDeadline,
                        errorText: applicationDeadlineError,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),
                _sectionTitle("Hackathon Dates"),

                Row(
                  children: [
                    Expanded(
                      child: _dateField(
                        label: "Start Date",
                        icon: Icons.event_outlined,
                        valueText: _formatDate(startDate),
                        onTap: _pickStartDate,
                        errorText: startDateError,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _dateField(
                        label: "End Date",
                        icon: Icons.event_available_outlined,
                        valueText: _formatDate(endDate),
                        onTap: _pickEndDate,
                        errorText: endDateError,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 18),

                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: isSubmitting ? null : _submit,
                    style: _primaryButtonStyle(),
                    icon: isSubmitting
                        ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                        : const Icon(Icons.check_circle_outline),
                    label: Text(isSubmitting ? "Saving..." : "Submit"),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 6),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          text,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  Widget _textField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    int? maxLines = 1,
    int? maxLength,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        maxLength: maxLength,
        keyboardType: keyboardType,
        textInputAction: TextInputAction.next,
        onChanged: onChanged,
        validator: validator ??
                (value) =>
            (value == null || value.trim().isEmpty) ? "Required" : null,
        decoration: _fieldDecoration(label: label, icon: icon, hint: hint),
      ),
    );
  }

  Widget _dropdownField({
    required String label,
    required IconData icon,
    required String? value,
    required List<String> items,
    required void Function(String?) onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<String>(
        initialValue: value,
        items: items
            .map((e) => DropdownMenuItem<String>(value: e, child: Text(e)))
            .toList(),
        onChanged: onChanged,
        validator: (v) => (v == null || v.isEmpty) ? "Required" : null,
        decoration: _fieldDecoration(label: label, icon: icon),
      ),
    );
  }

  Widget _dateField({
    required String label,
    required IconData icon,
    required String valueText,
    required VoidCallback onTap,
    String? errorText,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        child: InputDecorator(
          decoration: _fieldDecoration(
            label: label,
            icon: icon,
            errorText: errorText,
          ),
          child: Text(valueText.isEmpty ? "Select date" : valueText),
        ),
      ),
    );
  }
}
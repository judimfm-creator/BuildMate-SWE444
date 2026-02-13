import 'package:flutter/material.dart';
import '../model/hackathon.dart';
import '../viewmodel/create_hackathon_controller.dart';

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
  final TextEditingController otherRoleController = TextEditingController();

  // Dropdown values
  String? selectedMode;
  String? selectedDomain;
  String? selectedEducation;

  // Dates
  DateTime? startDate;
  DateTime? endDate;

  // Date errors (for showing "Required" under date fields)
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
    'Other' ,
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

  final List<String> availableRoles = [
    'Designer',
    'Flutter Developer',
    'Backend Developer',
    'UI/UX',
    'Data Analyst',
    'Other' ,
  ];

  @override
  void dispose() {
    nameController.dispose();
    descriptionController.dispose();
    teamSizeController.dispose();
    cityController.dispose();
    locationController.dispose();
    otherDomainController.dispose();
    otherRoleController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime? d) {
    if (d == null) return "";
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return "$y-$m-$day";
  }

  Future<void> _pickStartDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: startDate ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
    );

    if (picked == null) return;

    setState(() {
      startDate = picked;
      startDateError = null;

      // لو endDate قبل startDate نخليه null
      if (endDate != null && endDate!.isBefore(picked)) {
        endDate = null;
      }

      // ما نخليها Required إلا وقت submit (عشان ما يزعج المستخدم)
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

  Future<void> _submit() async{
    final isFormValid = _formKey.currentState!.validate();


    setState(() {
      startDateError = (startDate == null) ? "Required" : null;
      endDateError = (endDate == null) ? "Required" : null;
    });


    if (!isFormValid || startDate == null || endDate == null) return;

    setState(() => isSubmitting = true);

    if (selectedRoles.isEmpty) return;

    final hackathon = Hackathon(
      name: nameController.text.trim(),
      description: descriptionController.text.trim(),
      domain: selectedDomain == 'Other'
          ? otherDomainController.text.trim()
          : selectedDomain!.trim(),
      teamSize: int.tryParse(teamSizeController.text.trim()) ?? 0,
      city: cityController.text.trim(),
      location: locationController.text.trim(),
      mode: selectedMode!.trim(),
      rolesNeeded: [
        ...selectedRoles.where((r) => r != "Other"),
        if (selectedRoles.contains("Other"))
          otherRoleController.text.trim(),
      ],
      educationCriteria: selectedEducation!.trim(),
      startDate: startDate!,
      endDate: endDate!,
    );

    try {
      await _controller.submit(hackathon);
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Hackathon saved successfully ✅")),
      );

      // Clear form after submit
      _formKey.currentState!.reset();
      nameController.clear();
      descriptionController.clear();
      teamSizeController.clear();
      cityController.clear();
      locationController.clear();
      otherRoleController.clear();

      setState(() {
        selectedMode = null;
        selectedDomain = null;
        selectedEducation = null;

        startDate = null;
        endDate = null;
        startDateError = null;
        endDateError = null;
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
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Create Hackathon"),
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
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return "Required";
                          final n = int.tryParse(v.trim());
                          if (n == null || n <= 0) return "Enter a valid number";
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
                  label: "City",
                  icon: Icons.location_city_outlined,
                ),
                _textField(
                  controller: locationController,
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
                          final result = await showDialog<List<String>>(
                            context: context,
                            builder: (context) {
                              List<String> tempSelected = List.from(selectedRoles);

                              return StatefulBuilder(
                                builder: (context, setDialogState) {
                                  return AlertDialog(
                                    title: const Text("Select Roles"),
                                    content: SingleChildScrollView(
                                      child: Column(
                                        children: availableRoles.map((role) {
                                          return CheckboxListTile(
                                            value: tempSelected.contains(role),
                                            title: Text(role),
                                            onChanged: (checked) {
                                              setDialogState(() {
                                                if (checked == true) {
                                                  tempSelected.add(role);
                                                } else {
                                                  tempSelected.remove(role);
                                                }
                                              });
                                            },
                                          );
                                        }).toList(),
                                      ),
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: const Text("Cancel"),
                                      ),
                                      ElevatedButton(
                                        onPressed: () =>
                                            Navigator.pop(context, tempSelected),
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
                            });
                          }
                        },
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: "Roles Needed",
                            border: OutlineInputBorder(),
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
                          child: _textField(
                            controller: otherRoleController,
                            label: "Specify Other Role",
                            icon: Icons.edit_outlined,
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
                _sectionTitle("Important Dates"),
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
                    icon: isSubmitting
                        ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                        : const Icon(Icons.check_circle_outline),
                    label: Text(isSubmitting ? "Saving..." : "Submit"),
                  ),
                ),

                const SizedBox(height: 10),
                Text(
                  "Tip: Roles example: Designer, Flutter Dev, UI/UX",
                  style: theme.textTheme.bodySmall,
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
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        textInputAction: TextInputAction.next,
        validator: validator ??
                (value) => (value == null || value.trim().isEmpty) ? "Required" : null,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(icon),
          border: const OutlineInputBorder(),
        ),
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
        value: value,
        items: items
            .map((e) => DropdownMenuItem<String>(value: e, child: Text(e)))
            .toList(),
        onChanged: onChanged,
        validator: (v) => (v == null || v.isEmpty) ? "Required" : null,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: const OutlineInputBorder(),
        ),
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
          decoration: InputDecoration(
            labelText: label,
            prefixIcon: Icon(icon),
            border: const OutlineInputBorder(),
            errorText: errorText,
          ),
          child: Text(valueText.isEmpty ? "Select date" : valueText),
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../viewmodel/register_view_model.dart';

class CompleteProfileView extends StatefulWidget {
  const CompleteProfileView({super.key});

  @override
  State<CompleteProfileView> createState() => _CompleteProfileViewState();
}

class _CompleteProfileViewState extends State<CompleteProfileView> {
  final _formKey = GlobalKey<FormState>();
  
  // تعريف الـ Controllers
  final TextEditingController _bioController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _portfolioController = TextEditingController();
  final TextEditingController _otherSkillController = TextEditingController();
  
  String? _selectedGender;
  final Color purple = const Color(0xFF6D56B3);

  // قائمة المهارات للاختيار المتعدد
  final List<String> _availableSkills = [
    'Flutter', 
    'UI/UX', 
    'Firebase', 
    'Python', 
    'Web Design', 
    'Other'
  ];
  final List<String> _selectedSkills = [];

  @override
  void dispose() {
    _bioController.dispose();
    _cityController.dispose();
    _portfolioController.dispose();
    _otherSkillController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // استدعاء الـ ViewModel الخاص بك
    final vm = context.watch<RegisterViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Complete Profile"),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: () => vm.skipProfileSetup(context),
            child: const Text(
              "Skip", 
              style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. اختيار الصورة الشخصية
                Center(
                  child: GestureDetector(
                    onTap: () => vm.pickImage(ImageSource.gallery),
                    child: CircleAvatar(
                      radius: 50,
                      backgroundColor: purple.withOpacity(0.1),
                      backgroundImage: vm.pickedImage != null 
                          ? FileImage(vm.pickedImage!) 
                          : null,
                      child: vm.pickedImage == null 
                          ? Icon(Icons.camera_alt, color: purple, size: 30) 
                          : null,
                    ),
                  ),
                ),
                const SizedBox(height: 30),

                // 2. البيوغرافي (Bio) - فحص 20 حرف على الأقل
                TextFormField(
                  controller: _bioController,
                  maxLines: 3,
                  decoration: _inputDeco("Biography", Icons.info_outline),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return "Required";
                    if (v.trim().length < 20) return "Bio must be at least 20 characters";
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // 3. المهارات (الاختيار المتعدد)
                const Text(
                  "Select Your Skills:", 
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 0,
                  children: _availableSkills.map((skill) {
                    final isSelected = _selectedSkills.contains(skill);
                    return FilterChip(
                      label: Text(skill),
                      selected: isSelected,
                      selectedColor: purple.withOpacity(0.2),
                      checkmarkColor: purple,
                      onSelected: (val) {
                        setState(() {
                          if (val) {
                            _selectedSkills.add(skill);
                          } else {
                            _selectedSkills.remove(skill);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),

                // حقل إضافي في حال اختيار Other
                if (_selectedSkills.contains('Other'))
                  Padding(
                    padding: const EdgeInsets.only(top: 15),
                    child: TextFormField(
                      controller: _otherSkillController,
                      decoration: _inputDeco("Type your other skills", Icons.add_circle_outline),
                      validator: (v) => (_selectedSkills.contains('Other') && (v == null || v.isEmpty)) ? "Please specify" : null,
                    ),
                  ),
                const SizedBox(height: 20),

                // 4. المدينة
                _buildField(_cityController, "City", Icons.location_city_outlined),
                
                // 5. روابط الأعمال (Portfolio) مع فحص الرابط
                TextFormField(
                  controller: _portfolioController,
                  decoration: _inputDeco("Portfolio Link", Icons.link),
                  validator: (v) {
                    if (v != null && v.isNotEmpty) {
                      final bool isUri = Uri.tryParse(v)?.hasAbsolutePath ?? false;
                      if (!isUri) return "Please enter a valid URL (e.g. https://...)";
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // 6. الجنس
                DropdownButtonFormField<String>(
                  value: _selectedGender,
                  decoration: _inputDeco("Gender", Icons.person_outline),
                  items: ["Male", "Female"]
                      .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                      .toList(),
                  onChanged: (v) => setState(() => _selectedGender = v),
                  validator: (v) => (v == null) ? "Required" : null,
                ),

                const SizedBox(height: 40),

                // زر الحفظ
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: purple,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: vm.isLoading ? null : () {
                      if (_formKey.currentState!.validate()) {
                        // دمج المهارات المختارة مع حقل Other
                        List<String> finalSkills = List.from(_selectedSkills);
                        if (finalSkills.contains('Other')) {
                          finalSkills.remove('Other');
                          if (_otherSkillController.text.isNotEmpty) {
                            finalSkills.add(_otherSkillController.text.trim());
                          }
                        }

                        // إرسال البيانات للـ ViewModel
                        vm.updateProfile(
                          bio: _bioController.text.trim(),
                          skills: finalSkills.join(", "), 
                          city: _cityController.text.trim(),
                          gender: _selectedGender!,
                          portfolio: _portfolioController.text.trim(),
                          context: context,
                        );
                      }
                    },
                    child: vm.isLoading 
                        ? const CircularProgressIndicator(color: Colors.white) 
                        : const Text("Save & Finish", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // دالة مساعدة لتصميم الحقول
  InputDecoration _inputDeco(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: purple),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: purple, width: 2),
      ),
    );
  }

  // دالة مساعدة لبناء الحقول البسيطة
  Widget _buildField(TextEditingController ctrl, String label, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: TextFormField(
        controller: ctrl, 
        decoration: _inputDeco(label, icon),
        validator: (v) => (v == null || v.isEmpty) ? "Required" : null,
      ),
    );
  }
}
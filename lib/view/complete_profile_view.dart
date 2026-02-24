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
  
  final _bioController = TextEditingController();
  final _cityController = TextEditingController();
  final _linkedinController = TextEditingController();
  final _githubController = TextEditingController();
  
  List<String> _selectedSkills = [];
  final List<String> _predefinedSkills = ["UI/UX", "Flutter", "Python", "Java", "Teamwork"];
  List<TextEditingController> _otherSkillControllers = [];

  String? _selectedGender; 
  final Color deepMediumPurple = const Color(0xFF7A62B3);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RegisterViewModel>().clearPickedImage();
    });
  }

  void _addOtherSkillField() {
    setState(() {
      _otherSkillControllers.add(TextEditingController());
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<RegisterViewModel>();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Complete Profile", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: () => Navigator.pushReplacementNamed(context, '/home'),
            child: const Text("Skip", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: deepMediumPurple.withOpacity(0.1),
                      backgroundImage: vm.pickedImage != null ? FileImage(vm.pickedImage!) : null,
                      child: vm.pickedImage == null ? Icon(Icons.person, color: deepMediumPurple, size: 50) : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: () => _showPicker(context, vm),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(color: deepMediumPurple, shape: BoxShape.circle),
                          child: const Icon(Icons.camera_alt, color: Colors.white, size: 18),
                        ),
                      ),
                    ),
                    if (vm.pickedImage != null)
                      Positioned(
                        top: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: () => vm.clearPickedImage(),
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                            child: const Icon(Icons.close, color: Colors.white, size: 16),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              _buildSectionTitle("Location & Bio"),
              _buildManagementField("City", "e.g. Riyadh", Icons.location_city_outlined, _cityController),
              _buildManagementField("Biography", "Tell us about yourself", Icons.info_outline, _bioController),

              _buildSectionTitle("Skills"),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: _predefinedSkills.map((skill) {
                  final isSelected = _selectedSkills.contains(skill);
                  return GestureDetector(
                    onTap: () => setState(() => isSelected ? _selectedSkills.remove(skill) : _selectedSkills.add(skill)),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: isSelected ? deepMediumPurple : Colors.grey.shade100, width: isSelected ? 1.5 : 1),
                      ),
                      child: Text(skill, style: TextStyle(color: isSelected ? deepMediumPurple : Colors.black87, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                    ),
                  );
                }).toList(),
              ),

              ..._otherSkillControllers.asMap().entries.map((entry) => Padding(
                padding: const EdgeInsets.only(top: 10),
                child: _buildManagementField("Other Skill", "Add skill", Icons.star_border, entry.value),
              )),

              TextButton.icon(
                onPressed: _addOtherSkillField,
                icon: Icon(Icons.add, size: 18, color: deepMediumPurple),
                label: Text("Add Other Skill", style: TextStyle(color: deepMediumPurple, fontWeight: FontWeight.bold)),
              ),

              const SizedBox(height: 15),
              _buildSectionTitle("Social Links"),
              _buildManagementField(
                "LinkedIn Profile", "https://linkedin.com/in/...", Icons.link, _linkedinController, 
                type: TextInputType.url,
                exampleText: " Example: https://linkedin.com/in/Sara-Mohammed", 
                validator: (val) {
                  if (val == null || val.isEmpty) return null;
                  if (!val.toLowerCase().contains("linkedin.com/")) return "Enter a valid LinkedIn URL";
                  return null;
                }
              ),
              _buildManagementField(
                "GitHub Profile", "https://github.com/...", Icons.code_rounded, _githubController, 
                type: TextInputType.url,
                exampleText: "Example: https://github.com/Sara-Mohammed", 
                validator: (val) {
                  if (val == null || val.isEmpty) return null;
                  if (!val.toLowerCase().contains("github.com/")) return "Enter a valid GitHub URL";
                  return null;
                }
              ),

              _buildSectionTitle("Gender"),
              _buildGenderDropdown(),

              const SizedBox(height: 30),
              
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: deepMediumPurple,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  onPressed: vm.isLoading ? null : _submit,
                  child: vm.isLoading 
                    ? const CircularProgressIndicator(color: Colors.white) 
                    : const Text("FINISH SETUP", style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) => Padding(
    padding: const EdgeInsets.only(bottom: 12, left: 5, top: 10),
    child: Text(title, style: TextStyle(color: deepMediumPurple, fontSize: 14, fontWeight: FontWeight.bold)),
  );

  Widget _buildManagementField(
    String label, 
    String helper, 
    IconData icon, 
    TextEditingController ctrl, {
    TextInputType type = TextInputType.text, 
    String? Function(String?)? validator,
    String? exampleText,
  }) {
    // تحديد ما إذا كان الحقل هو Biography لتطبيق العداد و100 حرف
    bool isBio = label == "Biography";

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(bottom: 4),
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade100, width: 1),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start, // جعل الأيقونة في الأعلى عند النزول لسطر جديد
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Icon(icon, color: deepMediumPurple, size: 20),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: TextFormField(
                  controller: ctrl,
                  maxLength: isBio ? 100 : 40, // 100 للبيو و 40 للبقية
                  maxLines: null, // يسمح بالنزول لسطر جديد تلقائياً (Wrap)
                  keyboardType: isBio ? TextInputType.multiline : type,
                  validator: validator,
                  onChanged: (val) => setState(() {}), // لتحديث العداد فوراً
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87),
                  decoration: InputDecoration(
                    labelText: label,
                    counterText: isBio ? null : "", // إظهار العداد فقط للبيو وإخفائه للبقية
                    labelStyle: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                    hintText: helper,
                    hintStyle: TextStyle(color: Colors.grey.shade300, fontSize: 13, fontWeight: FontWeight.normal),
                    border: InputBorder.none,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (exampleText != null)
          Padding(
            padding: const EdgeInsets.only(left: 15, bottom: 12),
            child: Text(
              exampleText,
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 11,
                fontWeight: FontWeight.normal,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildGenderDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        children: [
          Icon(Icons.wc_outlined, color: deepMediumPurple, size: 20),
          const SizedBox(width: 15),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedGender,
                hint: const Text(
                  "Choose Gender", 
                  style: TextStyle(
                    fontSize: 14, 
                    color: Colors.grey, 
                    fontWeight: FontWeight.normal
                  )
                ),
                isExpanded: true,
                dropdownColor: Colors.white,
                items: ["Male", "Female"].map((String value) {
                  return DropdownMenuItem<String>(
                    value: value, 
                    child: Center(
                      child: Text(
                        value, 
                        style: const TextStyle(
                          fontSize: 14, 
                          fontWeight: FontWeight.normal,
                          color: Colors.black87
                        )
                      ),
                    ),
                  );
                }).toList(),
                onChanged: (newValue) => setState(() => _selectedGender = newValue),
                icon: Icon(Icons.arrow_drop_down, color: deepMediumPurple),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showPicker(BuildContext context, RegisterViewModel vm) {
    showModalBottomSheet(context: context, builder: (_) => SafeArea(child: Wrap(children: [
      ListTile(leading: const Icon(Icons.photo_library), title: const Text('Gallery'), onTap: () { vm.pickImage(ImageSource.gallery); Navigator.pop(context); }),
      ListTile(leading: const Icon(Icons.camera_alt), title: const Text('Camera'), onTap: () { vm.pickImage(ImageSource.camera); Navigator.pop(context); }),
    ])));
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    List<String> finalSkillsList = [..._selectedSkills];
    for (var controller in _otherSkillControllers) {
      if (controller.text.trim().isNotEmpty) finalSkillsList.add(controller.text.trim());
    }

    context.read<RegisterViewModel>().updateProfile(
      bio: _bioController.text.trim(),
      skills: finalSkillsList, 
      city: _cityController.text.trim(),
      gender: _selectedGender ?? "Not Specified",
      linkedin: _linkedinController.text.trim(),
      github: _githubController.text.trim(),
      context: context,
    );
  }
}
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
  
  // controllers بنفس مسميات المانجمنت لتوحيد البيانات
  final _bioController = TextEditingController();
  final _cityController = TextEditingController();
  final _linkedinController = TextEditingController();
  final _githubController = TextEditingController();
  
  List<String> _selectedSkills = [];
  final List<String> _predefinedSkills = ["UI/UX", "Flutter", "Python", "Java", "Teamwork"];
  List<TextEditingController> _otherSkillControllers = [];

  String _selectedGender = 'Male';
  final Color deepMediumPurple = const Color(0xFF7A62B3); // نفس لون المانجمنت بالضبط

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
            onPressed: () => vm.skipProfileSetup(context),
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
              // قسم الصورة (نفس ستايل المانجمنت)
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
                          child: const CircleAvatar(radius: 12, backgroundColor: Colors.red, child: Icon(Icons.close, size: 14, color: Colors.white)),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              _buildSectionTitle("Location & Bio"),
              _buildManagementField("City", "e.g. Riyadh", Icons.location_city_outlined, _cityController),
              _buildManagementField("Biography", "Tell us about yourself", Icons.info_outline, _bioController, maxLines: 2),

              _buildSectionTitle("Skills"),
              // بوكسات المهارات البيضاء (نفس تصميم المانجمنت في البطاقات)
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
              // حقول الروابط - تأكدي أن المسميات هنا تطابق المانجمنت
              _buildManagementField("LinkedIn Profile", "Paste Link", Icons.link, _linkedinController, type: TextInputType.url),
              _buildManagementField("GitHub Profile", "Paste Link", Icons.code_rounded, _githubController, type: TextInputType.url),

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

  // الوجت المساعدة المطابقة للمانجمنت
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 5, top: 10),
      child: Text(title, style: TextStyle(color: deepMediumPurple, fontSize: 14, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildManagementField(String label, String helper, IconData icon, TextEditingController ctrl, {int maxLines = 1, TextInputType type = TextInputType.text}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade100, width: 1),
      ),
      child: Row(
        children: [
          Icon(icon, color: deepMediumPurple, size: 20),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
                TextField(
                  controller: ctrl,
                  maxLines: maxLines,
                  keyboardType: type,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  decoration: InputDecoration(
                    hintText: helper,
                    hintStyle: TextStyle(color: Colors.grey.shade300, fontSize: 13, fontWeight: FontWeight.normal),
                    isDense: true,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.only(top: 4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGenderDropdown() {
    return Container(
      padding: const EdgeInsets.all(15),
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
                isDense: true,
                items: ["Male", "Female"].map((String value) {
                  return DropdownMenuItem<String>(value: value, child: Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)));
                }).toList(),
                onChanged: (newValue) => setState(() => _selectedGender = newValue!),
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
    List<String> finalSkills = [..._selectedSkills];
    for (var controller in _otherSkillControllers) {
      if (controller.text.trim().isNotEmpty) finalSkills.add(controller.text.trim());
    }

    context.read<RegisterViewModel>().updateProfile(
      bio: _bioController.text.trim(),
      skills: finalSkills.join(", "), 
      city: _cityController.text.trim(),
      gender: _selectedGender,
      linkedin: _linkedinController.text.trim(),
      github: _githubController.text.trim(),
      context: context,
    );
  }
}
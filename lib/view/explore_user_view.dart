import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../viewmodel/org_hackathons_view_model.dart';
import '../model/hackathon.dart';
import '../widgets/user_hackathon_card.dart';

class ExploreUserView extends StatefulWidget {
  final int initialTabIndex;
  const ExploreUserView({super.key, this.initialTabIndex = 0});

  @override
  State<ExploreUserView> createState() => _ExploreUserViewState();
}

class _ExploreUserViewState extends State<ExploreUserView> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // متغيرات الفلترة
  final TextEditingController _cityController = TextEditingController();
  String? selectedMode;
  String? selectedStatus;
  DateTime? selectedStartDate;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTabIndex,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Explore", style: TextStyle(color: Color(0xFF7A62B3), fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF7A62B3)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: TabBar(
            controller: _tabController,
            indicatorColor: const Color(0xFF7A62B3),
            labelColor: const Color(0xFF7A62B3),
            unselectedLabelColor: Colors.grey,
            tabs: const [
              Tab(text: "Hackathons"),
              Tab(text: "Teams"),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildHackathonsSection(),
          _buildEmptyTeamsSection(),
        ],
      ),
    );
  }

  Widget _buildHackathonsSection() {
    final vm = context.watch<OrgHackathonsViewModel>();

    return Column(
      children: [
        // صف أزرار الفلترة
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showFilterDialog(context),
                  icon: const Icon(Icons.tune, color: Color(0xFF7A62B3)),
                  label: const Text("Filter Hackathons", style: TextStyle(color: Color(0xFF7A62B3))),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF7A62B3)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              if (_cityController.text.isNotEmpty || selectedMode != null || selectedStartDate != null || selectedStatus != null)
                IconButton(
                  onPressed: () => setState(() {
                    _cityController.clear();
                    selectedMode = null;
                    selectedStatus = null;
                    selectedStartDate = null;
                  }),
                  icon: const Icon(Icons.filter_alt_off, color: Colors.red),
                ),
            ],
          ),
        ),

        Expanded(
          child: StreamBuilder<List<Hackathon>>(
            stream: vm.exploreHackathonsStream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: Color(0xFF7A62B3)));
              }

              var list = snapshot.data ?? [];
              DateTime now = DateTime.now();

              // تطبيق الفلاتر
              if (_cityController.text.isNotEmpty) {
                list = list.where((h) => h.city.toLowerCase().contains(_cityController.text.toLowerCase())).toList();
              }

              if (selectedMode != null) {
                list = list.where((h) => h.mode == selectedMode).toList();
              }

              if (selectedStatus != null) {
                list = list.where((h) {
                  if (selectedStatus == "Upcoming Registration") {
                    return now.isBefore(h.applicationOpenDate);
                  } else if (selectedStatus == "Registration Open") {
                    return now.isAfter(h.applicationOpenDate) && now.isBefore(h.applicationDeadline);
                  }
                  return true;
                }).toList();
              }

              if (selectedStartDate != null) {
                list = list.where((h) =>
                h.startDate.year == selectedStartDate!.year &&
                    h.startDate.month == selectedStartDate!.month &&
                    h.startDate.day == selectedStartDate!.day
                ).toList();
              }

              // التعديل هنا: إضافة أيقونة ورسالة مختصرة في حال عدم وجود نتائج
              if (list.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.search_off_rounded, size: 60, color: Colors.grey[400]),
                      const SizedBox(height: 12),
                      Text(
                        "No results found",
                        style: TextStyle(color: Colors.grey[600], fontSize: 16, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: list.length,
                itemBuilder: (context, index) => UserHackathonCard(hackathon: list[index]),
              );
            },
          ),
        ),
      ],
    );
  }

  void _showFilterDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text("Filter Options"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _cityController,
                  decoration: const InputDecoration(labelText: "City", border: OutlineInputBorder()),
                ),
                const SizedBox(height: 20),

                const Text("Registration Status:", style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8.0,
                  children: [
                    ChoiceChip(
                      label: const Text("Upcoming"),
                      selected: selectedStatus == "Upcoming Registration",
                      selectedColor: const Color(0xFF7A62B3).withOpacity(0.2),
                      onSelected: (selected) {
                        setDialogState(() => selectedStatus = selected ? "Upcoming Registration" : null);
                      },
                    ),
                    ChoiceChip(
                      label: const Text("Open Now"),
                      selected: selectedStatus == "Registration Open",
                      selectedColor: const Color(0xFF7A62B3).withOpacity(0.2),
                      onSelected: (selected) {
                        setDialogState(() => selectedStatus = selected ? "Registration Open" : null);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                DropdownButtonFormField<String>(
                  value: selectedMode,
                  decoration: const InputDecoration(labelText: "Mode", border: OutlineInputBorder()),
                  items: ["Onsite", "Online"].map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                  onChanged: (val) => setDialogState(() => selectedMode = val),
                ),
                const SizedBox(height: 20),

                ListTile(
                  tileColor: Colors.grey[100],
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  title: Text(selectedStartDate == null
                      ? "Select Start Date"
                      : DateFormat('yyyy-MM-dd').format(selectedStartDate!)),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final DateTime? picked = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime(2030),
                    );
                    if (picked != null) setDialogState(() => selectedStartDate = picked);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                setState(() {});
                Navigator.pop(context);
              },
              child: const Text("Apply", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF7A62B3))),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyTeamsSection() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.group_add_outlined, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 10),
          Text(
            "Teams feature is coming soon!",
            style: TextStyle(color: Colors.grey[600], fontSize: 16),
          ),
        ],
      ),
    );
  }
}
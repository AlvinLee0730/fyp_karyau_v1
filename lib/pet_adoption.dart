import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PetAdoptionPage extends StatefulWidget {
  const PetAdoptionPage({super.key});

  @override
  State<PetAdoptionPage> createState() => _PetAdoptionPageState();
}

class _PetAdoptionPageState extends State<PetAdoptionPage> {
  final _supabase = Supabase.instance.client;

  // Controllers
  final _nameController = TextEditingController();
  final _breedController = TextEditingController();
  final _ageController = TextEditingController();
  final _locationController = TextEditingController();
  final _descController = TextEditingController();
  final _contactController = TextEditingController();
  final _searchController = TextEditingController();

  // Filter States
  String _searchQuery = "";
  String _filterSize = 'All';
  String _filterGender = 'All';

  // Form State
  String _selectedGender = 'Male';
  String _selectedSize = 'Medium';
  bool _isVaccinated = false;
  File? _imageFile;
  bool _isSaving = false;

  // Optimized Stream with explicit Primary Key for Realtime updates
  Stream<List<Map<String, dynamic>>> get _adoptionStream => _supabase
      .from('adoption_pets')
      .stream(primaryKey: ['id'])
      .order('created_at', ascending: false);

  // --- LOGIC: CLEAR FILTERS ---
  void _clearAllFilters() {
    setState(() {
      _filterSize = 'All';
      _filterGender = 'All';
      _searchQuery = "";
      _searchController.clear();
    });
  }

  // --- LOGIC: DELETE (With Immediate UI Refresh) ---
  Future<void> _deletePet(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Remove Listing?"),
        content: const Text("Are you sure this pet is no longer available for adoption?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancel")),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text("Remove", style: TextStyle(color: Colors.red))
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _supabase.from('adoption_pets').delete().eq('id', id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Pet removed successfully")),
          );
          // Manually trigger a rebuild in case the stream is lagging
          setState(() {});
        }
      } catch (e) {
        debugPrint("Error deleting: $e");
      }
    }
  }

  // --- LOGIC: SAVE / EDIT ---
  Future<void> _saveAdoption({int? existingId, String? existingImageUrl}) async {
    if (_nameController.text.isEmpty || _locationController.text.isEmpty) return;

    setState(() => _isSaving = true);
    try {
      String? imageUrl = existingImageUrl;
      if (_imageFile != null) {
        final fileName = 'adopt_${DateTime.now().millisecondsSinceEpoch}.jpg';
        await _supabase.storage.from('pet_images').upload(fileName, _imageFile!);
        imageUrl = _supabase.storage.from('pet_images').getPublicUrl(fileName);
      }

      final data = {
        'name': _nameController.text.trim(),
        'breed': _breedController.text.trim(),
        'age': _ageController.text.trim(),
        'gender': _selectedGender,
        'size': _selectedSize,
        'vaccinated': _isVaccinated,
        'description': _descController.text.trim(),
        'location': _locationController.text.trim(),
        'contact_info': _contactController.text.trim(),
        'image_url': imageUrl,
      };

      if (existingId == null) {
        await _supabase.from('adoption_pets').insert(data);
      } else {
        await _supabase.from('adoption_pets').update(data).eq('id', existingId);
      }

      if (mounted) {
        Navigator.pop(context);
        setState(() {}); // Refresh UI
      }
    } catch (e) {
      debugPrint("Error saving: $e");
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showAdoptionForm({Map<String, dynamic>? pet}) {
    if (pet != null) {
      _nameController.text = pet['name'] ?? '';
      _breedController.text = pet['breed'] ?? '';
      _ageController.text = pet['age'] ?? '';
      _locationController.text = pet['location'] ?? '';
      _descController.text = pet['description'] ?? '';
      _contactController.text = pet['contact_info'] ?? '';
      _selectedGender = pet['gender'] ?? 'Male';
      _selectedSize = pet['size'] ?? 'Medium';
      _isVaccinated = pet['vaccinated'] ?? false;
    } else {
      _nameController.clear(); _breedController.clear(); _ageController.clear();
      _locationController.clear(); _descController.clear(); _contactController.clear();
      _imageFile = null; _isVaccinated = false;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, top: 20, left: 20, right: 20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(pet == null ? "Put Pet Up for Adoption" : "Edit Adoption Info", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                const SizedBox(height: 15),
                InkWell(
                  onTap: () async {
                    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 50);
                    if (pickedFile != null) setModalState(() => _imageFile = File(pickedFile.path));
                  },
                  child: Container(
                    height: 120, width: double.infinity,
                    decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.grey.shade300)),
                    child: _imageFile != null
                        ? ClipRRect(borderRadius: BorderRadius.circular(15), child: Image.file(_imageFile!, fit: BoxFit.cover))
                        : (pet?['image_url'] != null ? ClipRRect(borderRadius: BorderRadius.circular(15), child: Image.network(pet!['image_url'], fit: BoxFit.cover)) : const Icon(Icons.add_a_photo, color: Colors.orange)),
                  ),
                ),
                TextField(controller: _nameController, decoration: const InputDecoration(labelText: "Pet Name")),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField(
                        value: _selectedGender,
                        items: ['Male', 'Female'].map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
                        onChanged: (val) => setModalState(() => _selectedGender = val!),
                        decoration: const InputDecoration(labelText: "Gender"),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: DropdownButtonFormField(
                        value: _selectedSize,
                        items: ['Small', 'Medium', 'Large'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                        onChanged: (val) => setModalState(() => _selectedSize = val!),
                        decoration: const InputDecoration(labelText: "Size"),
                      ),
                    ),
                  ],
                ),
                TextField(controller: _breedController, decoration: const InputDecoration(labelText: "Breed")),
                TextField(controller: _ageController, decoration: const InputDecoration(labelText: "Age")),
                SwitchListTile(
                  title: const Text("Vaccinated?"),
                  value: _isVaccinated,
                  onChanged: (val) => setModalState(() => _isVaccinated = val),
                ),
                TextField(controller: _descController, maxLines: 2, decoration: const InputDecoration(labelText: "About the pet")),
                TextField(controller: _locationController, decoration: const InputDecoration(labelText: "Location")),
                TextField(controller: _contactController, decoration: const InputDecoration(labelText: "Contact Info")),
                const SizedBox(height: 20),
                _isSaving ? const CircularProgressIndicator() : ElevatedButton(
                  onPressed: () => _saveAdoption(existingId: pet?['id'], existingImageUrl: pet?['image_url']),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white, minimumSize: const Size(double.infinity, 45)),
                  child: Text(pet == null ? "POST ADOPTION" : "UPDATE INFO"),
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool hasFilters = _filterSize != 'All' || _filterGender != 'All' || _searchQuery.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Pet Adoption"),
        actions: [
          if (hasFilters) IconButton(icon: const Icon(Icons.refresh), onPressed: _clearAllFilters),
        ],
      ),
      body: Column(
        children: [
          // 1. SEARCH BAR
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: "Search breed or name...",
                prefixIcon: const Icon(Icons.search),
                filled: true, fillColor: Colors.grey[100],
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
              ),
              onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
            ),
          ),

          // 2. DROPDOWN FILTERS
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(child: _buildDropdownFilter("Size", _filterSize, ['All', 'Small', 'Medium', 'Large'], (val) => setState(() => _filterSize = val!))),
                const SizedBox(width: 15),
                Expanded(child: _buildDropdownFilter("Gender", _filterGender, ['All', 'Male', 'Female'], (val) => setState(() => _filterGender = val!))),
              ],
            ),
          ),
          const Divider(),

          // 3. GRID LIST WITH REFRESH INDICATOR
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async => setState(() {}),
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: _adoptionStream,
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                  final filtered = snapshot.data!.where((p) {
                    final name = (p['name'] ?? '').toString().toLowerCase();
                    final breed = (p['breed'] ?? '').toString().toLowerCase();
                    bool matchesSearch = name.contains(_searchQuery) || breed.contains(_searchQuery);
                    bool matchesSize = _filterSize == 'All' || p['size'] == _filterSize;
                    bool matchesGender = _filterGender == 'All' || p['gender'] == _filterGender;
                    return matchesSearch && matchesSize && matchesGender;
                  }).toList();

                  if (filtered.isEmpty) return const Center(child: Text("No pets match your criteria."));

                  return GridView.builder(
                    padding: const EdgeInsets.all(10),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.75,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10
                    ),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final pet = filtered[index];
                      return Card(
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => AdoptionDetailPage(pet: pet))),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Stack(
                                  children: [
                                    pet['image_url'] != null
                                        ? Image.network(pet['image_url'], width: double.infinity, height: double.infinity, fit: BoxFit.cover)
                                        : Container(width: double.infinity, color: Colors.orange.shade50, child: const Icon(Icons.pets, size: 40, color: Colors.orange)),

                                    // FIXED ACTION BUTTONS
                                    Positioned(
                                      top: 5, right: 5,
                                      child: Row(
                                        children: [
                                          _actionCircle(Icons.edit, Colors.blue, () => _showAdoptionForm(pet: pet)),
                                          const SizedBox(width: 4),
                                          _actionCircle(Icons.delete, Colors.red, () => _deletePet(pet['id'])),
                                        ],
                                      ),
                                    )
                                  ],
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(pet['name'], style: const TextStyle(fontWeight: FontWeight.bold), maxLines: 1),
                                    Text("${pet['age']} • ${pet['breed']}", style: const TextStyle(fontSize: 12), maxLines: 1),
                                  ],
                                ),
                              )
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
          backgroundColor: Colors.orange,
          onPressed: () => _showAdoptionForm(),
          child: const Icon(Icons.add, color: Colors.white)
      ),
    );
  }

  Widget _actionCircle(IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: CircleAvatar(
        radius: 14,
        backgroundColor: Colors.white.withOpacity(0.9),
        child: Icon(icon, size: 14, color: color),
      ),
    );
  }

  Widget _buildDropdownFilter(String label, String value, List<String> items, ValueChanged<String?> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
        DropdownButton<String>(
          value: value,
          isExpanded: true,
          underline: Container(height: 1, color: Colors.orange),
          onChanged: onChanged,
          items: items.map((i) => DropdownMenuItem(value: i, child: Text(i, style: const TextStyle(fontSize: 13)))).toList(),
        ),
      ],
    );
  }
}

// --- DETAIL PAGE ---
class AdoptionDetailPage extends StatelessWidget {
  final Map<String, dynamic> pet;
  const AdoptionDetailPage({super.key, required this.pet});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(pet['name'])),
      body: SingleChildScrollView(
        child: Column(
          children: [
            if (pet['image_url'] != null) Image.network(pet['image_url'], height: 300, width: double.infinity, fit: BoxFit.cover),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(spacing: 8, children: [
                    Chip(label: Text(pet['gender'])),
                    Chip(label: Text(pet['size'])),
                    if (pet['vaccinated'] == true) const Chip(label: Text("Vaccinated"), backgroundColor: Colors.greenAccent),
                  ]),
                  const SizedBox(height: 10),
                  Text("About ${pet['name']}", style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Text(pet['description'] ?? "No description provided.", style: const TextStyle(fontSize: 16)),
                  const Divider(height: 40),
                  ListTile(leading: const Icon(Icons.location_on, color: Colors.orange), title: Text(pet['location'])),
                  ListTile(leading: const Icon(Icons.contact_phone, color: Colors.orange), title: const Text("Contact for Adoption"), subtitle: Text(pet['contact_info'])),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
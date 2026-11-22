import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import '../../data/karagars_provider.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../shared/widgets/gc_ui.dart';

class AddKaragarScreen extends ConsumerStatefulWidget {
  const AddKaragarScreen({super.key});

  @override
  ConsumerState<AddKaragarScreen> createState() => _AddKaragarScreenState();
}

class _AddKaragarScreenState extends ConsumerState<AddKaragarScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _specCtrl = TextEditingController();
  final _imagePicker = ImagePicker();
  String _meltingGroup = 'Group A';
  XFile? _profilePicture;
  Uint8List? _profilePictureBytes;
  String? _profilePictureError;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _codeCtrl.dispose();
    _phoneCtrl.dispose();
    _specCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final formIsValid = _formKey.currentState!.validate();
    final profilePicture = _profilePicture;
    final profilePictureBytes = _profilePictureBytes;
    if (profilePicture == null || profilePictureBytes == null) {
      setState(() => _profilePictureError = 'A profile picture is required');
    }
    if (!formIsValid || profilePicture == null || profilePictureBytes == null) {
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final dio = ref.read(dioProvider);
      await dio.post('/karagars', data: FormData.fromMap({
        'name': _nameCtrl.text.trim(),
        'employeeCode': _codeCtrl.text.trim(),
        'meltingGroup': _meltingGroup,
        'specialization': _specCtrl.text.trim(),
        if (_phoneCtrl.text.trim().isNotEmpty) 'phone': _phoneCtrl.text.trim(),
        'avatar': MultipartFile.fromBytes(
          profilePictureBytes,
          filename: profilePicture.name,
        ),
      }));
      if (!mounted) return;
      ref.invalidate(karagarsProvider);
      gcSnack(context, 'Karagar registered successfully');
      context.pop();
    } on DioException catch (e) {
      if (!mounted) return;
      gcSnack(context, mapDioError(e).message, error: true);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _chooseProfilePicture() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Take a photo'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from gallery'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;

    try {
      final image = await _imagePicker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1600,
        maxHeight: 1600,
      );
      if (image == null || !mounted) return;
      final imageBytes = await image.readAsBytes();
      if (!mounted) return;
      if (imageBytes.isEmpty) {
        setState(() => _profilePictureError = 'Selected photo is empty');
        return;
      }
      setState(() {
        _profilePicture = image;
        _profilePictureBytes = imageBytes;
        _profilePictureError = null;
      });
    } on PlatformException catch (e) {
      if (mounted) {
        gcSnack(
          context,
          e.message ?? 'Unable to select the profile picture',
          error: true,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GcScaffold(
      isAdmin: false,
      header: const GcPageHeader(
        title: 'Add Karagar',
        subtitle: 'Register a new craftsman',
        showBell: false,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            const GcSectionLabel('Profile Picture (required)'),
            _profilePictureField(),
            const GcSectionLabel('Profile Details'),
            _field(_nameCtrl, 'Full Name', icon: Icons.person_outline_rounded),
            _field(_codeCtrl, 'Employee Code',
                hint: 'e.g. GC-005', icon: Icons.badge_outlined),
            _field(_phoneCtrl, 'Phone Number',
                required: false,
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone),
            _field(_specCtrl, 'Specialization',
                hint: 'e.g. Bangles & Chains', icon: Icons.diamond_outlined),
            const SizedBox(height: 6),
            const GcSectionLabel('Melting Group'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: ['Group A', 'Group B', 'Group C']
                  .map((g) => GcChoiceChip(
                        label: g,
                        selected: _meltingGroup == g,
                        onTap: () => setState(() => _meltingGroup = g),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 32),
            GcPrimaryButton(
              label: 'Register Karagar',
              icon: Icons.how_to_reg_rounded,
              loading: _isSubmitting,
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }

  Widget _profilePictureField() => Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: GcUi.card(radius: 18),
              child: Row(
                children: [
                  ClipOval(
                    child: _profilePicture == null
                        ? Container(
                            width: 72,
                            height: 72,
                            color: GcUi.ivory,
                            child: const Icon(
                              Icons.person_outline_rounded,
                              color: GcUi.hint,
                              size: 36,
                            ),
                          )
                        : Image.memory(
                            _profilePictureBytes!,
                            width: 72,
                            height: 72,
                            fit: BoxFit.cover,
                          ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isSubmitting ? null : _chooseProfilePicture,
                      icon: Icon(_profilePicture == null
                          ? Icons.add_a_photo_outlined
                          : Icons.edit_outlined),
                      label: Text(_profilePicture == null
                          ? 'Choose photo'
                          : 'Change photo'),
                    ),
                  ),
                ],
              ),
            ),
            if (_profilePictureError != null)
              Padding(
                padding: const EdgeInsets.only(left: 12, top: 6),
                child: Text(
                  _profilePictureError!,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                    fontSize: 12,
                  ),
                ),
              ),
          ],
        ),
      );

  Widget _field(
    TextEditingController ctrl,
    String label, {
    String? hint,
    IconData? icon,
    bool required = true,
    TextInputType keyboardType = TextInputType.text,
  }) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: TextFormField(
          controller: ctrl,
          keyboardType: keyboardType,
          decoration: GcUi.input(label: label, hint: hint, icon: icon),
          validator: required
              ? (v) => (v == null || v.trim().isEmpty) ? 'Required' : null
              : null,
        ),
      );
}
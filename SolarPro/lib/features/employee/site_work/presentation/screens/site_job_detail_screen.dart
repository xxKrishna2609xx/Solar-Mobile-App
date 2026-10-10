import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:solar_pro/core/theme/app_theme.dart';
import 'package:solar_pro/features/employee/site_work/presentation/widgets/scope_of_work_card.dart';
import 'package:solar_pro/features/employee/site_work/presentation/widgets/site_photo_grid.dart';
import 'package:solar_pro/features/work_assignment/data/models/site_customer_scope.dart';
import 'package:solar_pro/features/work_assignment/data/models/work_assignment_model.dart';
import 'package:solar_pro/features/work_assignment/data/repositories/work_assignment_repository.dart';

class SiteJobDetailScreen extends StatefulWidget {
  final WorkAssignmentModel initialJob;
  final WorkAssignmentRepository? repository;

  const SiteJobDetailScreen({
    super.key,
    required this.initialJob,
    this.repository,
  });

  @override
  State<SiteJobDetailScreen> createState() => _SiteJobDetailScreenState();
}

class _SiteJobDetailScreenState extends State<SiteJobDetailScreen> {
  late WorkAssignmentRepository _repo;
  late WorkAssignmentModel _job;
  late SiteCustomerScope _scope;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _repo = widget.repository ?? WorkAssignmentRepository();
    _job = widget.initialJob;
    _scope = const SiteCustomerScope();
  }

  Future<void> _handleStartWork() async {
    setState(() => _isLoading = true);
    try {
      final updated = await _repo.startWork(_job.id);
      if (mounted) {
        setState(() {
          _job = updated;
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              updated.isPendingSync
                  ? 'Work started locally (queued for sync).'
                  : 'Work started successfully!',
            ),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to start work: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _handleCompleteWork() async {
    // CRITICAL BACKEND RULE: Completing requires at least 1 uploaded photo
    if (_job.photos.isEmpty) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppColors.navy800,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: AppColors.warning),
              SizedBox(width: 8),
              Text('Photo Proof Required', style: TextStyle(color: Colors.white, fontSize: 16)),
            ],
          ),
          content: const Text(
            'Backend rules strictly require at least 1 site verification photo proof before completing this assignment.\n\nPlease capture or upload completion photos first.',
            style: TextStyle(color: AppColors.grey300, fontSize: 13, height: 1.4),
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                _showAddPhotosSheet();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.gold500,
                foregroundColor: AppColors.navy900,
              ),
              child: const Text('Add Photo Proof Now'),
            ),
          ],
        ),
      );
      return;
    }

    // Confirmation dialog before completing
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.navy800,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
        title: const Text('Confirm Completion', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text(
          'Are you sure you want to mark this ${_job.workType.displayName} installation job as Completed?\n\n${_job.photos.length} photo proof(s) will be submitted for customer stage advancement.',
          style: const TextStyle(color: AppColors.grey300, fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel', style: TextStyle(color: AppColors.grey400)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: Colors.white,
            ),
            child: const Text('Mark Complete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);
    try {
      final updated = await _repo.completeWork(_job.id, existingPhotos: _job.photos);
      if (mounted) {
        setState(() {
          _job = updated;
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              updated.isPendingSync
                  ? 'Job marked complete locally (queued for sync).'
                  : 'Job successfully completed! Backend updated customer stage.',
            ),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to complete job: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _showAddPhotosSheet() {
    final captionCtrl = TextEditingController();
    int photoCount = 1;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.navy800,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (sheetContext, setSheetState) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.grey600,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Row(
                children: [
                  Icon(Icons.add_a_photo_outlined, color: AppColors.gold500),
                  SizedBox(width: 8),
                  Text(
                    'Upload Site Photo Proof',
                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              const Text(
                'Upload 1 to 10 photos of the installed equipment or structure.',
                style: TextStyle(color: AppColors.grey400, fontSize: 12),
              ),
              const SizedBox(height: 16),

              // Photo count selector
              Row(
                children: [
                  const Text('Number of Photos: ', style: TextStyle(color: Colors.white, fontSize: 13)),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline, color: AppColors.gold500),
                    onPressed: photoCount > 1
                        ? () => setSheetState(() => photoCount--)
                        : null,
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.navy700,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '$photoCount',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline, color: AppColors.gold500),
                    onPressed: photoCount < 10
                        ? () => setSheetState(() => photoCount++)
                        : null,
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Caption input
              TextField(
                controller: captionCtrl,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: InputDecoration(
                  labelText: 'Caption / Work Note (Optional)',
                  labelStyle: const TextStyle(color: AppColors.grey400),
                  hintText: 'e.g. Inverter ACDB wiring verified',
                  hintStyle: TextStyle(color: AppColors.grey600),
                  filled: true,
                  fillColor: AppColors.navy700,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Submit button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    Navigator.of(ctx).pop();
                    setState(() => _isLoading = true);

                    // Generate simulated local photo file paths for upload
                    final paths = List.generate(
                      photoCount,
                      (i) => 'site_proof_${_job.workType.toBackendString()}_${DateTime.now().millisecondsSinceEpoch}_$i.jpg',
                    );
                    final captions = List.generate(
                      photoCount,
                      (i) => captionCtrl.text.isNotEmpty
                          ? captionCtrl.text
                          : '${_job.workType.displayName} verification photo ${i + 1}',
                    );

                    try {
                      final uploaded = await _repo.uploadPhotos(_job.id, paths, captions: captions);
                      if (mounted) {
                        setState(() {
                          _job = _job.copyWith(
                            photos: [..._job.photos, ...uploaded],
                            isPendingSync: uploaded.any((p) => p.isLocal),
                          );
                          _isLoading = false;
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('${uploaded.length} photo(s) added successfully!'),
                            backgroundColor: AppColors.success,
                          ),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        setState(() => _isLoading = false);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error uploading photos: $e'),
                            backgroundColor: AppColors.error,
                          ),
                        );
                      }
                    }
                  },
                  icon: const Icon(Icons.cloud_upload_outlined),
                  label: Text('Upload $photoCount Photo(s)'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.gold500,
                    foregroundColor: AppColors.navy900,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    textStyle: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd MMM yyyy');

    return Scaffold(
      backgroundColor: AppColors.navy900,
      appBar: AppBar(
        backgroundColor: AppColors.navy800,
        elevation: 0,
        title: Text(
          '${_job.workType.displayName} Job Details',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 17),
        ),
        actions: [
          if (_job.isPendingSync)
            Container(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
              child: const Row(
                children: [
                  Icon(Icons.sync_problem_rounded, color: AppColors.warning, size: 14),
                  SizedBox(width: 4),
                  Text(
                    'Offline Queued',
                    style: TextStyle(color: AppColors.warning, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.gold500))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Banner: Status & Work Type
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.navy800,
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                      border: Border.all(color: _job.workType.color.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: _job.workType.color.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(_job.workType.icon, color: _job.workType.color, size: 24),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${_job.workType.displayName} Assignment',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _job.teamName ?? 'Assigned Team',
                                style: const TextStyle(color: AppColors.grey400, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: _job.status.color.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                          ),
                          child: Text(
                            _job.status.displayName.toUpperCase(),
                            style: TextStyle(
                              color: _job.status.color,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Limited Customer Card (Name, Mobile with Call, Address with Directions)
                  // CRITICAL: NEVER show prices, payments, or documents to site employees!
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.navy800,
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                      border: Border.all(color: AppColors.navy700),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.person_pin_rounded, color: AppColors.gold500, size: 18),
                            SizedBox(width: 8),
                            Text(
                              'Customer & Site Contact',
                              style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _job.customer?.name ?? 'Customer Name',
                          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 8),

                        // Mobile with Call button
                        Row(
                          children: [
                            const Icon(Icons.phone_rounded, color: AppColors.grey400, size: 15),
                            const SizedBox(width: 8),
                            Text(
                              _job.customer?.mobile.isNotEmpty == true ? _job.customer!.mobile : 'No Mobile',
                              style: const TextStyle(color: AppColors.grey300, fontSize: 13, fontWeight: FontWeight.w500),
                            ),
                            const Spacer(),
                            ElevatedButton.icon(
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Dialing ${_job.customer?.mobile}...'),
                                    backgroundColor: AppColors.success,
                                  ),
                                );
                              },
                              icon: const Icon(Icons.call, size: 14),
                              label: const Text('Call'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.teal500,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 20, color: AppColors.navy700),

                        // Address with Map Directions button
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.place_rounded, color: AppColors.grey400, size: 15),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _job.customer?.address.isNotEmpty == true
                                    ? _job.customer!.address
                                    : 'Site Address Not Provided',
                                style: const TextStyle(color: AppColors.grey300, fontSize: 13, height: 1.3),
                              ),
                            ),
                            const SizedBox(width: 8),
                            OutlinedButton.icon(
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Opening Google Maps navigation for site address...'),
                                    backgroundColor: AppColors.navy700,
                                  ),
                                );
                              },
                              icon: const Icon(Icons.navigation_outlined, size: 14),
                              label: const Text('Maps'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.gold500,
                                side: const BorderSide(color: AppColors.gold500),
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Scope of Work Card (Technical specs only, zero financial info)
                  ScopeOfWorkCard(workType: _job.workType, scope: _scope),
                  const SizedBox(height: 16),

                  // Schedule & Notes Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.navy800,
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                      border: Border.all(color: AppColors.navy700),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.calendar_month_rounded, color: AppColors.gold500, size: 18),
                            SizedBox(width: 8),
                            Text(
                              'Schedule & Instructions',
                              style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const Text('Planned Schedule:', style: TextStyle(color: AppColors.grey400, fontSize: 13)),
                            const Spacer(),
                            Text(
                              '${dateFormat.format(_job.scheduledStart)} - ${dateFormat.format(_job.scheduledEnd)}',
                              style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                        if (_job.actualStart != null) ...[
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Text('Actual Start:', style: TextStyle(color: AppColors.grey400, fontSize: 13)),
                              const Spacer(),
                              Text(
                                DateFormat('dd MMM yyyy, hh:mm a').format(_job.actualStart!),
                                style: const TextStyle(color: AppColors.gold500, fontSize: 13, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ],
                        if (_job.actualEnd != null) ...[
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Text('Actual End:', style: TextStyle(color: AppColors.grey400, fontSize: 13)),
                              const Spacer(),
                              Text(
                                DateFormat('dd MMM yyyy, hh:mm a').format(_job.actualEnd!),
                                style: const TextStyle(color: AppColors.success, fontSize: 13, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ],
                        if (_job.notes?.isNotEmpty == true) ...[
                          const Divider(height: 20, color: AppColors.navy700),
                          const Text('Site Instructions:', style: TextStyle(color: AppColors.grey400, fontSize: 12)),
                          const SizedBox(height: 4),
                          Text(
                            _job.notes!,
                            style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.3),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Site Photos Grid
                  SitePhotoGrid(
                    photos: _job.photos,
                    onAddPhotos: _showAddPhotosSheet,
                    readOnly: _job.status == WorkStatus.completed,
                  ),
                  const SizedBox(height: 80),
                ],
              ),
            ),
      bottomSheet: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.navy800,
          border: Border(top: BorderSide(color: AppColors.navy700)),
        ),
        child: SafeArea(
          child: Row(
            children: [
              if (_job.status == WorkStatus.pending) ...[
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _handleStartWork,
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: const Text('Start Work On-Site'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.gold500,
                      foregroundColor: AppColors.navy900,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                    ),
                  ),
                ),
              ] else if (_job.status == WorkStatus.inProgress) ...[
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _handleCompleteWork,
                    icon: const Icon(Icons.check_circle_rounded),
                    label: const Text('Complete Job with Proof'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                    ),
                  ),
                ),
              ] else if (_job.status == WorkStatus.completed) ...[
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(color: AppColors.success.withValues(alpha: 0.4)),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.verified_rounded, color: AppColors.success, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Job Completed & Verified',
                          style: TextStyle(
                            color: AppColors.success,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

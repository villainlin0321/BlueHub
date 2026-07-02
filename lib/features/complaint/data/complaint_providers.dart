import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/network/page_result.dart';
import '../../../shared/network/providers.dart';
import '../../../shared/network/services/complaint_service.dart';
import 'complaint_models.dart';

final complaintServiceProvider = Provider<ComplaintService>((ref) {
  return ComplaintService(apiClient: ref.watch(apiClientProvider));
});

final myComplaintsProvider = FutureProvider.autoDispose
    .family<PageResult<ComplaintVO>, ComplaintListQuery>((ref, query) async {
      final ComplaintService service = ref.watch(complaintServiceProvider);
      return service.listMyComplaints(
        page: query.page,
        pageSize: query.pageSize,
      );
    });

final complaintDetailProvider = FutureProvider.autoDispose
    .family<ComplaintVO, int>((ref, complaintId) async {
      final ComplaintService service = ref.watch(complaintServiceProvider);
      return service.getComplaintDetail(complaintId: complaintId);
    });

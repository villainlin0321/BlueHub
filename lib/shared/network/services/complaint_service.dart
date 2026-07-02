import 'package:bluehub_app/shared/network/api_client.dart';
import 'package:bluehub_app/shared/network/api_decoders.dart';
import 'package:bluehub_app/shared/network/page_result.dart';

import '../../../features/complaint/data/complaint_models.dart';

class ComplaintService {
  ComplaintService({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  Future<int> createComplaint({required CreateComplaintBO request}) async {
    final int response = await _apiClient.post<int>(
      '/complaints',
      data: request.toJson(),
      decode: (data) {
        if (data is int) {
          return data;
        }
        if (data is num) {
          return data.toInt();
        }
        if (data is String) {
          return int.tryParse(data) ?? 0;
        }
        return 0;
      },
    );
    return response;
  }

  Future<ComplaintVO> getComplaintDetail({required int complaintId}) async {
    final ComplaintVO response = await _apiClient.get<ComplaintVO>(
      '/complaints/$complaintId',
      decode: (data) => ComplaintVO.fromJson(asJsonMap(data)),
    );
    return response;
  }

  Future<PageResult<ComplaintVO>> listMyComplaints({
    int page = 1,
    int pageSize = 20,
  }) async {
    final PageResult<ComplaintVO> response = await _apiClient
        .get<PageResult<ComplaintVO>>(
          '/complaints/mine',
          queryParameters: <String, dynamic>{
            'page': page,
            'page_size': pageSize,
          },
          decode: (data) => PageResult<ComplaintVO>.fromJson(
            asJsonMap(data),
            fromJson: ComplaintVO.fromJson,
          ),
        );
    return response;
  }
}

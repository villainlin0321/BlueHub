import 'package:bluehub_app/shared/network/api_client.dart';
import 'package:bluehub_app/shared/network/api_decoders.dart';
import 'package:bluehub_app/shared/network/page_result.dart';
import 'visa_order_models.dart';

class VisaOrderService {
  VisaOrderService({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  Future<VisaOrderVO> createOrder({required CreateVisaOrderBO request}) async {
    final response = await _apiClient.post<VisaOrderVO>(
      '/visa-orders',
      data: request.toJson(),
      decode: (data) => VisaOrderVO.fromJson(asJsonMap(data)),
    );
    return response;
  }

  Future<PageResult<VisaOrderVO>> listMyOrders({
    int? page,
    int? pageSize,
    String? status,
  }) async {
    final queryParameters = <String, dynamic>{
      if (page != null) 'page': page,
      if (pageSize != null) 'page_size': pageSize,
      if (status != null) 'status': status,
    };
    final response = await _apiClient.get<PageResult<VisaOrderVO>>(
      '/visa-orders/mine',
      queryParameters: queryParameters.isEmpty ? null : queryParameters,
      decode: (data) => PageResult<VisaOrderVO>.fromJson(
        asJsonMap(data),
        fromJson: VisaOrderVO.fromJson,
      ),
    );
    return response;
  }

  Future<PageResult<VisaOrderVO>> listProviderOrders({
    int? page,
    int? pageSize,
    String? status,
    String? country,
  }) async {
    final queryParameters = <String, dynamic>{
      if (page != null) 'page': page,
      if (pageSize != null) 'page_size': pageSize,
      if (status != null) 'status': status,
      if (country != null) 'country': country,
    };
    final response = await _apiClient.get<PageResult<VisaOrderVO>>(
      '/visa-orders/provider',
      queryParameters: queryParameters.isEmpty ? null : queryParameters,
      decode: (data) => PageResult<VisaOrderVO>.fromJson(
        asJsonMap(data),
        fromJson: VisaOrderVO.fromJson,
      ),
    );
    return response;
  }

  Future<VisaOrderVO> getOrderDetail({required int orderId}) async {
    final response = await _apiClient.get<VisaOrderVO>(
      '/visa-orders/$orderId',
      decode: (data) => VisaOrderVO.fromJson(asJsonMap(data)),
    );
    return response;
  }

  Future<void> uploadMaterials({
    required int orderId,
    required UploadOrderMaterialsBO request,
  }) async {
    return _apiClient.postVoid(
      '/visa-orders/$orderId/materials',
      data: request.toJson(),
    );
  }

  Future<void> payOrder({required int orderId}) async {
    return _apiClient.postVoid('/visa-orders/$orderId/pay');
  }

  Future<void> processOrder({
    required int orderId,
    required ProcessOrderBO request,
  }) async {
    return _apiClient.putVoid(
      '/visa-orders/$orderId/process',
      data: request.toJson(),
    );
  }

  Future<void> uploadVisaDocuments({
    required int orderId,
    required UploadVisaDocumentsBO request,
  }) async {
    return _apiClient.postVoid(
      '/visa-orders/$orderId/visa-documents',
      data: request.toJson(),
    );
  }
}

import 'package:bluehub_app/shared/network/api_client.dart';
import 'package:bluehub_app/shared/network/api_decoders.dart';
import 'package:bluehub_app/shared/network/page_result.dart';
import 'visa_order_models.dart';

class VisaOrderService {
  VisaOrderService({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  /// 创建签证订单，提交下单所需业务参数并返回最新订单信息。
  Future<VisaOrderVO> createOrder({required CreateVisaOrderBO request}) async {
    final response = await _apiClient.post<VisaOrderVO>(
      '/visa-orders',
      data: request.toJson(),
      decode: (data) => VisaOrderVO.fromJson(asJsonMap(data)),
    );
    return response;
  }

  /// 获取当前用户的订单列表，支持分页与按订单状态筛选。
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

  /// 获取服务商视角的订单列表，支持分页、状态和国家维度筛选。
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

  /// 按订单 ID 获取订单详情。
  Future<VisaOrderVO> getOrderDetail({required int orderId}) async {
    final response = await _apiClient.get<VisaOrderVO>(
      '/visa-orders/$orderId',
      decode: (data) => VisaOrderVO.fromJson(asJsonMap(data)),
    );
    return response;
  }

  /// 上传用户侧补件材料，通常用于订单材料提交流程。
  Future<void> uploadMaterials({
    required int orderId,
    required UploadOrderMaterialsBO request,
  }) async {
    return _apiClient.postVoid(
      '/visa-orders/$orderId/materials',
      data: request.toJson(),
    );
  }

  /// 触发订单支付。
  Future<void> payOrder({required int orderId}) async {
    return _apiClient.postVoid('/visa-orders/$orderId/pay');
  }

  /// 提交服务商侧订单处理结果或处理动作。
  Future<void> processOrder({
    required int orderId,
    required ProcessOrderBO request,
  }) async {
    return _apiClient.putVoid(
      '/visa-orders/$orderId/process',
      data: request.toJson(),
    );
  }

  /// 上传签证办理过程中产生的签证文件或出签材料。
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

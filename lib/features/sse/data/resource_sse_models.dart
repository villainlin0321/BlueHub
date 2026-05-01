import 'package:bluehub_app/shared/network/api_decoders.dart';

class RVoid {
  const RVoid({required this.code, required this.msg, required this.data});

  final int code;
  final String msg;
  final dynamic data;

  factory RVoid.fromJson(JsonMap json) {
    return RVoid(
      code: (json['code'] as num?)?.toInt() ?? 0,
      msg: json['msg'] as String? ?? '',
      data: json['data'],
    );
  }

  JsonMap toJson() {
    return <String, dynamic>{'code': code, 'msg': msg, 'data': data};
  }
}

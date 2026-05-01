import 'package:bluehub_app/shared/network/api_decoders.dart';

class CreateReviewBO {
  const CreateReviewBO({
    required this.orderId,
    required this.providerId,
    required this.rating,
    required this.content,
    required this.images,
  });

  final int orderId;
  final int providerId;
  final int rating;
  final String content;
  final List<String> images;

  factory CreateReviewBO.fromJson(JsonMap json) {
    return CreateReviewBO(
      orderId: (json['orderId'] as num?)?.toInt() ?? 0,
      providerId: (json['providerId'] as num?)?.toInt() ?? 0,
      rating: (json['rating'] as num?)?.toInt() ?? 0,
      content: json['content'] as String? ?? '',
      images: decodeStringList(json['images'] ?? const <dynamic>[]),
    );
  }

  JsonMap toJson() {
    return <String, dynamic>{
      'orderId': orderId,
      'providerId': providerId,
      'rating': rating,
      'content': content,
      'images': images,
    };
  }
}

import 'package:europepass/shared/network/api_decoders.dart';

class CreateReviewBO {
  const CreateReviewBO({
    required this.orderId,
    required this.providerId,
    required this.rating,
    required this.content,
    required this.imageFileIds,
  });

  final int orderId;
  final int providerId;
  final int rating;
  final String content;
  final List<int> imageFileIds;

  factory CreateReviewBO.fromJson(JsonMap json) {
    return CreateReviewBO(
      orderId: readInt(json, 'orderId'),
      providerId: readInt(json, 'providerId'),
      rating: readInt(json, 'rating'),
      content: readString(json, 'content'),
      imageFileIds: readIntList(json, 'imageFileIds'),
    );
  }

  JsonMap toJson() {
    return <String, dynamic>{
      'orderId': orderId,
      'providerId': providerId,
      'rating': rating,
      'content': content,
      'imageFileIds': imageFileIds,
    };
  }
}

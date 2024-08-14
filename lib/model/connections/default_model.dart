class DefaultModel {
  bool success = false;
  String? message;
  dynamic error;
  dynamic data;

  DefaultModel({this.success = false, this.message, this.error, this.data});

  DefaultModel.fromJson(Map<String, dynamic>? json) {
    success = json?['success'];
    message = json?['message'];
    data = json?['data'];
    error = json?['error'];
  }

  Map<String, dynamic> toJson(DefaultModel model) => <String, dynamic>{
        'success': model.success,
        'message': model.message,
        'error': model.error,
        'data': model.data
      };
}
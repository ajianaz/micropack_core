import 'default_model.dart';
import 'failure_model.dart';
import 'status_request_model.dart';

FailureModel failure(int? code, DefaultModel model) {
  String message;
  switch (code) {
    case 401:
      message = "Unauthorized";
      break;
    default:
      message = model.message ?? "An Error Occurred";
  }
  return FailureModel(code, message, message);
}

FailureModel toFailureModel(dynamic e, {String? message}) {
  if (e is StatusRequestModel<dynamic>) {
    return FailureModel(
        400, message == null ? "${e.failure?.msgShow}" : "$message. $e", "$e");
  }
  return FailureModel(400, message ?? "$e", "$e");
}

DefaultModel toDefaultModel(dynamic response) {
  String message = "An Error Occurred";
  message = response["message"] ?? message;
  message = response["msg"] ?? message;
  if (response == null) {
    return DefaultModel(
        success: false,
        message: message,
        error: response["error"] ?? "An Error Occurred");
  } else {
    Map<String, dynamic> data = response as Map<String, dynamic>;
    data["success"] = data["success"] ?? false;
    data["message"] = message;
    data["data"] = data["data"];
    return DefaultModel.fromJson(data);
  }
}

StatusRequestModel<T> catchError<T>(Object e) {
  if (e is StatusRequestModel<dynamic>) {
    return StatusRequestModel<T>.error(e.failure);
  } else {
    return StatusRequestModel<T>.error(toFailureModel(e));
  }
}

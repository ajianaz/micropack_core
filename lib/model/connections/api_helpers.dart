import '../../micropack_core.dart';

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
    return FailureModel(e.failure?.code ?? 400,
        message == null ? "${e.failure?.msgShow}" : "$message. $e", "$e");
  }
  return FailureModel(400, message ?? "$e", "$e");
}

DefaultModel toDefaultModel(dynamic response, {int statusCode = 200}) {
  String message = "An Error Occurred";
  message = response["message"] ?? message;
  message = response["msg"] ?? message;

  if (response == null) {
    return DefaultModel(
      success: false,
      message: message,
      error: response["error"] ?? "An Error Occurred",
      statusCode: response["statusCode"] ?? statusCode,
    );
  } else {
    Map<String, dynamic> data = response as Map<String, dynamic>;
    data["success"] = data["success"] ?? false;
    data["message"] = message;
    data["data"] = data["data"];
    data["statusCode"] = response["statusCode"] ?? statusCode;
    return DefaultModel.fromJson(data);
  }
}

StatusRequestModel<T> catchError<T>(Object e) {
  if (e is StatusRequestModel<dynamic>) {
    return StatusRequestModel<T>.error(e.failure);
  } else if (e is Map<String, dynamic>) {
    // Jika e adalah Map (response dari API)
    final statusCode = e["statusCode"] as int?;
    final message = e["message"] as String?;

    // Handle khusus untuk statusCode 401
    if (statusCode == 401) {
      // Panggil fungsi logout atau tindakan lain
      _logoutUser();
      return StatusRequestModel<T>.error(
        FailureModel(
          statusCode,
          message ?? "Unauthorized",
          "Session expired. Please log in again.",
        ),
      );
    }

    // Jika bukan 401, kembalikan FailureModel biasa
    return StatusRequestModel<T>.error(
      FailureModel(
        statusCode ?? 500, // Default to 500 if statusCode is null
        message ?? "An error occurred",
        "An unexpected error occurred.",
      ),
    );
  } else {
    // Jika e bukan Map atau StatusRequestModel, kembalikan FailureModel default
    return StatusRequestModel<T>.error(toFailureModel(e));
  }
}

// Fungsi untuk logout
void _logoutUser() {
  // Implementasi logout di sini
  MicropackStorage.deleteAll();
}

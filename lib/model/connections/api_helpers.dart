import '../../micropack_core.dart';

/// Mengubah kode HTTP & pesan mentah menjadi pesan yang mudah dipahami user.
/// - message: pesan ramah pengguna (ID)
/// - developerMessage: pesan asli dari server/exception untuk debugging
FailureModel failure(int? code, DefaultModel model) {
  // Pesan asli dari backend/exception (jika ada)
  final raw = (model.message ?? '').trim();
  final rawLower = raw.toLowerCase();

  String message;

  switch (code) {
    // 2xx tidak dianggap failure, tapi kalau sampai sini jadikan generik
    case 200:
    case 201:
      message = "Permintaan berhasil.";
      break;

    // Client errors
    case 400:
      message = "Permintaan tidak valid. Cek kembali data yang dikirim.";
      break;
    case 401:
      message = "Sesi berakhir atau tidak sah. Silakan login kembali.";
      break;
    case 403:
      message = "Akses ditolak. Anda tidak memiliki izin untuk aksi ini.";
      break;
    case 404:
      message = "Data tidak ditemukan.";
      break;
    case 408:
      message = "Permintaan terlalu lama. Coba lagi.";
      break;
    case 409:
      message = "Terjadi konflik data. Muat ulang lalu coba lagi.";
      break;
    case 413:
      message = "Ukuran data terlalu besar. Kurangi ukuran file/data.";
      break;
    case 415:
      message = "Tipe konten tidak didukung.";
      break;
    case 422:
      message = "Data tidak dapat diproses. Periksa isian Anda.";
      break;
    case 429:
      message = "Terlalu banyak permintaan. Coba lagi beberapa saat.";
      break;

    // Server errors
    case 500:
      message = "Terjadi gangguan pada server. Coba lagi nanti.";
      break;
    case 502:
      message = "Server bermasalah (Bad Gateway). Coba lagi nanti.";
      break;
    case 503:
      message = "Layanan sedang tidak tersedia. Coba lagi nanti.";
      break;
    case 504:
      message = "Server tidak merespons (Gateway Timeout). Coba lagi.";
      break;

    // Tanpa kode / kode lain -> coba deteksi dari pesan mentah
    default:
      // Heuristik dari pesan yang sering dilempar Dio di service Anda
      if (rawLower.contains('no internet')) {
        message = "Tidak ada koneksi internet. Periksa jaringan Anda.";
      } else if (rawLower.contains('timeout')) {
        message = "Koneksi lambat. Permintaan kedaluwarsa, coba lagi.";
      } else if (rawLower.contains('connection error') ||
          rawLower.contains('socket') ||
          rawLower.contains('failed host') ||
          rawLower.contains('connection refused')) {
        message = "Gagal terhubung ke server. Periksa jaringan Anda.";
      } else if (rawLower.contains('bad response format') ||
          rawLower.contains('format')) {
        message = "Format respons tidak sesuai. Coba lagi nanti.";
      } else if (rawLower.contains('unauthorized')) {
        message = "Sesi tidak valid. Silakan login kembali.";
      } else if (rawLower.isNotEmpty) {
        // Jika backend sudah memberi pesan yang jelas, gunakan itu
        message = raw;
      } else {
        message = "Terjadi kesalahan. Coba lagi beberapa saat.";
      }
  }

  // Kembalikan FailureModel dengan:
  // - code apa adanya (bisa null)
  // - message ramah pengguna
  // - developerMessage tetap membawa pesan asli (fallback ke message ramah)
  return FailureModel(code, message, raw.isEmpty ? message : raw);
}

FailureModel toFailureModel(dynamic e, {String? message}) {
  if (e is StatusRequestModel<dynamic>) {
    return FailureModel(e.failure?.code ?? 400,
        message == null ? "${e.failure?.msgShow}" : "$message. $e", "$e");
  }

  if (e is DefaultModel) {
    return FailureModel(
        e.statusCode ?? 400,
        message == null ? "${e.message}" : "$message. ${e.message}",
        "${e.error}");
  }
  return FailureModel(400, message ?? "$e", "$e");
}

DefaultModel toDefaultModel(dynamic response, {int statusCode = 200}) {
  String message = "An Error Occurred";
  if (response is Map) {
    message = response["message"] ?? message;
    message = response["msg"] ?? message;
  }

  if (response is! Map<String, dynamic>) {
    // Null / List / tipe lain — jangan cast paksa (crash
    // "type 'Null' is not a subtype of Map<String, dynamic>").
    // Anggap failure generik dengan payload aslinya dipertahankan.
    return DefaultModel(
      success: false,
      message: message,
      error: "Format respons tidak valid",
      statusCode: (response is Map && response["statusCode"] is int)
          ? response["statusCode"] as int
          : statusCode,
    );
  } else {
    final Map<String, dynamic> data = response;
    data["success"] = data["success"] ?? false;
    data["message"] = message;
    data["data"] = data["data"];
    data["statusCode"] = response["statusCode"] ?? statusCode;
    return DefaultModel.fromJson(data);
  }
}

StatusRequestModel<T> catchError<T>(Object e) {
  if (e is StatusRequestModel<dynamic>) {
    logSys("CATCH ERROR Micropack : Unknown");
    return StatusRequestModel<T>.error(e.failure);
  } else if (e is Map<String, dynamic>) {
    // Jika e adalah Map (response dari API)
    final statusCode = e["statusCode"] as int?;
    final message = e["message"] as String?;

    // Handle khusus untuk statusCode 401
    if (statusCode == 401) {
      logSys("CATCH ERROR Micropack : 401");
      // CATATAN: JANGAN hapus storage di sini. Dulu branch ini memanggil
      // _logoutUser() -> MicropackStorage.deleteAll() yang menghapus
      // refresh token yang masih valid secara diam-diam — user terlogout
      // permanen padahal sesinya bisa dipulihkan lewat refresh token.
      // Kebijakan logout/token sepenuhnya milik host app (TokenService).
      return StatusRequestModel<T>.error(
        FailureModel(
          statusCode,
          message ?? "Unauthorized",
          "Session expired. Please log in again.",
        ),
      );
    }

    logSys("CATCH ERROR Micropack : NOT 401");
    // Jika bukan 401, kembalikan FailureModel biasa
    return StatusRequestModel<T>.error(
      FailureModel(
        statusCode ?? 500, // Default to 500 if statusCode is null
        message ?? "An error occurred",
        "An unexpected error occurred.",
      ),
    );
  } else {
    //FROM else in api
    // Jika e bukan Map atau StatusRequestModel, kembalikan FailureModel default
    logSys("CATCH ERROR Micropack ");
    return StatusRequestModel<T>.error(toFailureModel(e));
  }
}

// (Fungsi _logoutUser yang dulu menghapus seluruh storage saat 401
// sudah dihapus — perilaku wipe diam-diam itu berbahaya dan menghapus
// refresh token yang masih valid. Logout adalah keputusan host app.)

import 'micropack_config.dart';

class MicropackInit {
  // Setup fungsi untuk inisialisasi parameter aplikasi, termasuk logEnabled
  static setup({
    /// [REQUIRED] Setup base url Development
    required String urlDev,

    /// [OPTIONAL] Setup base url Stagging
    String? urlStag,

    /// [OPTIONAL] Setup base url Production
    String? urlProd,

    /// [REQUIRED] Setup Apikey
    required String apiKey,

    /// [REQUIRED] Setup Apikey
    required String apiDevKey,

    /// [REQUIRED] Setup Apikey
    required String appName,

    /// [REQUIRED] Setup Mode Flavor
    required Flavor appFlavor,

    /// [OPTIONAL] Setup base url Production
    String? boxToken,

    /// [OPTIONAL] Setup base request timeout
    int? requestTimeout,

    /// [OPTIONAL] Setup log enabled globally
    bool logEnabled = true, // Default value is true (logging enabled)
  }) {
    // Assign to static fields
    MicropackInit.urlDev = urlDev;
    urlStag != null
        ? MicropackInit.urlStag = urlStag
        : MicropackInit.urlStag = urlDev;
    urlProd != null
        ? MicropackInit.urlProd = urlProd
        : MicropackInit.urlProd = urlDev;

    MicropackInit.apiKey = apiKey;
    MicropackInit.apiDevKey = apiDevKey;
    MicropackInit.appName = appName;
    MicropackInit.appFlavor = appFlavor;

    if (boxToken != null) MicropackInit.boxToken = boxToken;
    if (requestTimeout != null) MicropackInit.requestTimeout = requestTimeout;

    // Set the global logging enabled flag
    MicropackInit.logEnabled = logEnabled;
  }

  // Default values
  static String urlDev = "http://localhost:3000";
  static String urlStag = "http://localhost:3000";
  static String urlProd = "http://localhost:3000";

  static String apiKey = "ajianaz.dev";
  static String apiDevKey = "ajianaz.dev";

  static String appName = "APPNAME";
  static Flavor appFlavor = Flavor.development;

  static String boxToken = "token";

  static int requestTimeout = 60;

  // Global logging enabled flag
  static bool logEnabled = true;
}

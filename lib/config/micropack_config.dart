import 'package:micropack_core/config/micropack_init.dart';

enum Flavor { development, staging, production }

class MicropackConfig {
  static final urlDev = MicropackInit.urlDev;
  static final urlStaging = MicropackInit.urlStag;
  static final urlProd = MicropackInit.urlProd;

  static final apiKey = MicropackInit.apiKey;

  static Flavor appFlavor = MicropackInit.appFlavor;

  static bool get isDevelopment {
    return appFlavor == Flavor.development;
  }

  static bool get isStaging {
    return appFlavor == Flavor.staging;
  }

  static bool get isProduction {
    return appFlavor == Flavor.production;
  }

  static String get baseUrl {
    switch (appFlavor) {
      case Flavor.development:
        return urlDev;

      case Flavor.production:
        return urlProd;

      case Flavor.staging:
        return urlStaging;
    }
  }
}

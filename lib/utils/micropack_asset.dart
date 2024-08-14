class MicropackAsset {
  static String icon(String s) {
    return 'assets/icons/$s';
  }

  static String logo(String s) {
    return 'assets/logos/$s';
  }

  static String image(String s) {
    return 'assets/images/$s';
  }

  static String custom(String folder, String s) {
    return 'assets/$folder/$s';
  }
}

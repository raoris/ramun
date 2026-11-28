import 'package:flutter/foundation.dart';

const _releaseUrl = 'https://github.com/raoris/ramun/releases/latest';
const _apkUrl =
    'https://github.com/raoris/ramun/releases/latest/download/app-release.apk';

Uri updateUri() {
  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
    return Uri.parse(_apkUrl);
  }
  return Uri.parse(_releaseUrl);
}

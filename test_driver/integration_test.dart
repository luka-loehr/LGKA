// Flutter integration test driver.
// Receives screenshot bytes from the device and saves them to the host filesystem.
// The output directory is controlled by the SCREENSHOT_OUTPUT_DIR env var,
// which the Fastfile sets before each flutter drive invocation.

import 'dart:io';
import 'package:integration_test/integration_test_driver_extended.dart';

Future<void> main() async {
  final outputDir =
      Platform.environment['SCREENSHOT_OUTPUT_DIR'] ?? 'build/screenshots';

  await integrationDriver(
    onScreenshot: (String name, List<int> bytes, [Map<String, Object?>? args]) async {
      final file = File('$outputDir/$name.png');
      await file.create(recursive: true);
      await file.writeAsBytes(bytes);
      return true;
    },
  );
}

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
      // Use xcrun to capture the full simulator screen (includes status bar + Dynamic Island).
      // onScreenshot fires after the test ends, so the simulator is still on the correct screen.
      // Use SCREENSHOT_DEVICE_UDID when set so we target the correct device when multiple
      // simulators are booted simultaneously (e.g. phone + tablet).
      final udid = Platform.environment['SCREENSHOT_DEVICE_UDID'] ?? 'booted';
      final result = await Process.run('xcrun', [
        'simctl', 'io', udid, 'screenshot', file.path,
      ]);
      if (result.exitCode != 0) {
        // Fallback to Flutter bytes if simctl fails.
        await file.writeAsBytes(bytes);
      }
      return true;
    },
  );
}

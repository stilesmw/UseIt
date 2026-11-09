import 'dart:io';

import 'Square.dart';

Future<void> main() async {
  final gan = Platform.environment['SQUARE_TEST_GAN']?.trim();
  if (gan == null || gan.isEmpty) {
    stderr.writeln(
      'Set SQUARE_TEST_GAN to a sandbox card GAN before running this test.',
    );
    exitCode = 1;
    return;
  }

  try {
    final card = await getCard(gan);
    stdout.writeln('Square gift card lookup succeeded.');
    stdout.writeln('Status: ${card.state}');
    stdout.writeln(
      'Balance: ${(card.balanceCents / 100).toStringAsFixed(2)} ${card.currency}',
    );
  } catch (error) {
    stderr.writeln(
      'Square gift card lookup failed: ${error.toString().replaceFirst('Exception: ', '')}',
    );
    exitCode = 1;
  }
}

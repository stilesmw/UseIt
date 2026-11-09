# useit

A new Flutter project.

## Square Sandbox gift card lookup

The scanner sends the barcode's GAN to the Azure Functions API. The function
looks up the card in Square Sandbox and returns its status and current balance.
The Square access token belongs in the backend's `SQUARE_ACCESS_TOKEN` app
setting; do not put it in Flutter source or commit it.

To run the lookup smoke test from PowerShell, set a sandbox GAN for the current
terminal session and run:

```powershell
$env:SQUARE_TEST_GAN = '<sandbox-gift-card-GAN>'
dart run lib\Pages\Test.dart
```

The test calls the deployed Azure lookup function, so the function must have
`SQUARE_ACCESS_TOKEN` configured and be deployed first.

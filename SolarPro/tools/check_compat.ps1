# Windows PowerShell runner for SolarPro Compatibility Check
Write-Host "Running SolarPro Compatibility Checker..." -ForegroundColor Cyan
dart run tools/check_compat.dart

Write-Host "🧹 Deep cleaning LGKA Flutter project (Windows PowerShell)..." -ForegroundColor Green
Write-Host ""

# Remove ALL iOS build and derived data
Write-Host "📱 Deep cleaning iOS..." -ForegroundColor Yellow
Remove-Item -Path "ios\Pods" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item -Path "ios\.symlinks" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item -Path "ios\Flutter\ephemeral" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item -Path "ios\Flutter\Flutter-Generated.xcconfig" -Force -ErrorAction SilentlyContinue
Remove-Item -Path "ios\Flutter\flutter_export_environment.sh" -Force -ErrorAction SilentlyContinue
Remove-Item -Path "ios\Flutter\Generated.xcconfig" -Force -ErrorAction SilentlyContinue
Remove-Item -Path "ios\Runner.xcworkspace\xcuserdata" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item -Path "ios\Runner.xcodeproj\project.xcworkspace\xcuserdata" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item -Path "ios\Podfile.lock" -Force -ErrorAction SilentlyContinue
Remove-Item -Path "ios\Flutter\.last_build_id" -Force -ErrorAction SilentlyContinue
Write-Host "✅ iOS deep cleaned" -ForegroundColor Green

# Remove macOS build artifacts
Write-Host "🖥️  Deep cleaning macOS..." -ForegroundColor Yellow
Remove-Item -Path "macos\Flutter\ephemeral" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item -Path "macos\Flutter\Flutter-Generated.xcconfig" -Force -ErrorAction SilentlyContinue
Remove-Item -Path "macos\Flutter\flutter_export_environment.sh" -Force -ErrorAction SilentlyContinue
Remove-Item -Path "macos\Podfile.lock" -Force -ErrorAction SilentlyContinue
Write-Host "✅ macOS deep cleaned" -ForegroundColor Green

# Remove ALL Android build artifacts and generated files
Write-Host "🤖 Deep cleaning Android..." -ForegroundColor Yellow
Remove-Item -Path "android\.gradle" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item -Path "android\app\build" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item -Path "android\build" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item -Path "android\.kotlin" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item -Path "android\local.properties" -Force -ErrorAction SilentlyContinue
Remove-Item -Path "android\app\src\main\java\io\flutter\plugins\GeneratedPluginRegistrant.java" -Force -ErrorAction SilentlyContinue
Remove-Item -Path "android\*.iml" -Force -ErrorAction SilentlyContinue
Remove-Item -Path "android\app\*.iml" -Force -ErrorAction SilentlyContinue
Write-Host "✅ Android deep cleaned" -ForegroundColor Green

# Remove ALL Flutter generated files
Write-Host "🦋 Deep cleaning Flutter files..." -ForegroundColor Yellow
Remove-Item -Path ".flutter-plugins-dependencies" -Force -ErrorAction SilentlyContinue
Remove-Item -Path ".flutter-plugins" -Force -ErrorAction SilentlyContinue
Remove-Item -Path ".dart_tool" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item -Path ".packages" -Force -ErrorAction SilentlyContinue
Remove-Item -Path ".metadata" -Force -ErrorAction SilentlyContinue
Remove-Item -Path "pubspec.lock" -Force -ErrorAction SilentlyContinue
Remove-Item -Path ".idea" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item -Path "*.iml" -Force -ErrorAction SilentlyContinue
Write-Host "✅ Flutter files deep cleaned" -ForegroundColor Green

# Remove OS-specific files
Write-Host "🗑️  Removing OS-specific files..." -ForegroundColor Yellow
Get-ChildItem -Path . -Include .DS_Store,Thumbs.db,*.swp,*.swo,*~ -Recurse -Force | Remove-Item -Force
Write-Host "✅ OS files cleaned" -ForegroundColor Green

# Remove any log files
Write-Host "📝 Removing log files..." -ForegroundColor Yellow
Get-ChildItem -Path . -Include *.log,*.tmp -Recurse -Force | Remove-Item -Force
Write-Host "✅ Log files cleaned" -ForegroundColor Green

# Remove build directory if exists
if (Test-Path "build") {
    Write-Host "🏗️  Removing build directory..." -ForegroundColor Yellow
    Remove-Item -Path "build" -Recurse -Force
    Write-Host "✅ Build directory cleaned" -ForegroundColor Green
}

# Remove any backup files
Write-Host "💾 Removing backup files..." -ForegroundColor Yellow
Get-ChildItem -Path . -Include *.bak,*.backup -Recurse -Force | Remove-Item -Force
Write-Host "✅ Backup files cleaned" -ForegroundColor Green

Write-Host ""
Write-Host "✨ Deep cleaning completed!" -ForegroundColor Green
Write-Host "📦 Only essential source code and config files remain." -ForegroundColor Cyan
Write-Host ""
Write-Host "📊 Final project size:" -ForegroundColor Yellow
$size = (Get-ChildItem -Path . -Recurse | Measure-Object -Property Length -Sum).Sum / 1MB
Write-Host ("   {0:N2} MB" -f $size) -ForegroundColor Cyan

Write-Host ""
Write-Host "Press any key to continue..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown") 
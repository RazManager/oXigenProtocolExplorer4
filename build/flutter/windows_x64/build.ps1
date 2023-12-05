cd ../../../flutter
flutter build windows
cd ../build/flutter/windows_x64
Compress-Archive -Force -Path ../../../flutter/build/windows/x64/runner/Release/* -DestinationPath oxigen_protocol_explorer_4_windows_x64.zip

pause

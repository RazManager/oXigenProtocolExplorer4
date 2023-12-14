cd ../../../flutter
flutter build linux
cd ../build/flutter/linux_arm64
tar -czvf oxigen_protocol_explorer_4_linux_arm64.tar.gz --directory=../../../flutter/build/linux/arm64/release/bundle .

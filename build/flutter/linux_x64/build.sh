cd ../../../flutter
flutter build linux
cd ../build/flutter/linux_x64
tar -czvf oxigen_protocol_explorer_4_linux_x64.tar.gz --directory=../../../flutter/build/linux/x64/release/bundle .

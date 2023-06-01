#!/bin/bash

set -e
set -o pipefail

printf '\n\n\n================\n'
printf       '     general    \n'
printf       '================\n\n'


sudo apt-get purge unattended-upgrades

sudo apt-get dist-upgrade

sudo apt-get install ubuntu-restricted-extras build-essential gcc-multilib g++-multilib autoconf automake cmake valgrind curl
sudo apt-get install flatpak sqlite3 brasero vim vim-gtk3 git ffmpeg flac vlc mpv gimp audacity
sudo apt-get install cd-paranoia libcdio-utils cdrdao libcue-dev libxml2-utils libbluray2 libaacs0 libbdplus0
sudo apt-get install libdvd-pkg
sudo dpkg-reconfigure libdvd-pkg

#sudo apt-get --no-install-recommends install python3-pyxattr




printf '\n\n\n================\n'
printf       '     mozjpeg    \n'
printf       '================\n\n'

sudo apt-get install libtool

#====sudo apt-get install nasm




printf '\n\n\n================\n'
printf       '      godot     \n'
printf       '================\n\n'

sudo apt-get install pkg-config libx11-dev libxcursor-dev libxinerama-dev libgl1-mesa-dev libglu1-mesa-dev libasound2-dev libpulse-dev libfreetype6-dev libssl-dev libudev-dev libxi-dev libxrandr-dev

# (also included in godot repo):
sudo apt-get install libfreetype-dev libogg-dev libpng-dev libtheora-dev libvorbis-dev libvpx-dev libwebp-dev libminiupnpc-dev libopus-dev libpcre2-dev zlib1g-dev libzstd-dev

sudo apt-get install scons

#====sudo apt-get install yasm




printf '\n\n\n================\n'
printf       '    aesprite    \n'
printf       '================\n\n'

sudo apt-get install g++ cmake libx11-dev libxcursor-dev libxi-dev libgl1-mesa-dev libfontconfig1-dev curl libfreetype6-dev libgif-dev libharfbuzz-dev libjpeg-dev libpng-dev libpixman-1-dev zlib1g-dev

sudo apt-get install ninja-build




printf '\n\n\n================\n'
printf       '      skia      \n'
printf       '================\n\n'

sudo apt-get install build-essential libfontconfig1-dev libfreetype6-dev libgif-dev libgl1-mesa-dev libglu1-mesa-dev libharfbuzz-dev libicu-dev libjpeg-dev libpng-dev libwebp-dev

#====sudo apt-get install freeglut3-dev




printf '\n\n\n================\n'
printf       '     dolphin    \n'
printf       '================\n\n'

sudo apt-get install libevdev-dev libudev-dev libxrandr-dev libxi-dev libpangocairo-1.0-0 git cmake make gcc g++ ffmpeg libavcodec-dev libavformat-dev libavutil-dev libswscale-dev libmbedtls-dev

# (also included in dolphin repo):
sudo apt-get install ca-certificates pkg-config libminiupnpc-dev libcurl4-openssl-dev libsystemd-dev libbluetooth-dev libasound2-dev libpulse-dev libbz2-dev libzstd-dev liblzo2-dev libpng-dev libusb-1.0-0-dev gettext

# (qt5 packages):
#====sudo apt-get install qtbase5-dev qtchooser qt5-qmake qtbase5-dev-tools qtbase5-private-dev

# (also included in dolphin repo):
#====sudo apt-get install libsfml-dev libhidapi-dev libpugixml-dev




printf '\n\n\n================\n'
printf       '      rpcs3     \n'
printf       '================\n\n'

sudo apt-get install build-essential libasound2-dev libpulse-dev zlib1g-dev libedit-dev libvulkan-dev libudev-dev libevdev-dev

sudo apt-get install libopenal-dev libglew-dev libsdl2-2.0-0 libsdl2-dev

# (qt5 packages):
#====sudo apt-get install qtbase5-dev libqt5svg5-dev




printf '\n\n\n================\n'
printf       '      PCSX2     \n'
printf       '================\n\n'

sudo apt-get install cmake gcc-multilib g++-multilib libaio-dev:i386 libbz2-dev:i386 libegl1-mesa-dev:i386 libgles2-mesa-dev:i386 libjpeg-dev:i386 zlib1g-dev:i386 libjack-jackd2-dev:i386 liblzma-dev:i386 libxml2-dev:i386 libpcap0.8-dev:i386 libgtk2.0-dev:i386

sudo apt-get install libsdl1.2-dev:i386 libwxgtk3.0-gtk3-dev:i386 libsdl2-dev:i386 libportaudiocpp0:i386 portaudio19-dev:i386 libsoundtouch-dev:i386

# not in repos in 20.04+?
#sudo apt-get install libglew-dev:i386

# (optional):
#====sudo apt-get install libcggl:i386 nvidia-cg-toolkit




printf '\n\n\n================\n'
printf       '   DuckStation  \n'
printf       '================\n\n'

sudo apt-get install cmake libxrandr-dev pkg-config libevdev-dev libwayland-dev libwayland-egl-backend-dev

# (optional):
sudo apt-get install libcurl4-openssl-dev libgbm-dev libdrm-dev

sudo apt-get install libsdl2-dev extra-cmake-modules

# (qt5 packages):
#====sudo apt-get install qtbase5-dev qtbase5-private-dev qtbase5-dev-tools qttools5-dev

# (optional):
#====sudo apt-get install ninja-build




printf '\n\n\n================\n'
printf       '     whipper    \n'
printf       '================\n\n'

sudo apt-get install python3-pip cd-paranoia cdrdao gobject-introspection libsndfile1-dev flac sox git libdiscid-dev libiso9660-dev




printf '\n\n\n================\n'
printf       '     cyanrip    \n'
printf       '================\n\n'

sudo apt-get install meson ninja-build libavcodec-dev libswresample-dev libavutil-dev libavformat-dev libavfilter-dev libcdio-paranoia-dev libmusicbrainz5-dev libcurl4-openssl-dev




printf '\n\n\n================\n'
printf       '      FCEUX     \n'
printf       '================\n\n'

sudo apt-get install cmake qtbase5-dev libqt5widgets5 libqt5opengl5-dev liblua5.3-dev libminizip-dev zlib1g-dev libopengl-dev
sudo apt-get install libsdl2-dev
#sudo apt-get install libavcodec-dev libavformat-dev libavutil-dev libswresample-dev libswscale-dev
#sudo apt-get install libx264-dev libx265-dev




printf '\n\n\n================\n'
printf       '    All done!   \n'
printf       '================\n\n'


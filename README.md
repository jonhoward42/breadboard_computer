# Breadboard 6502 Computer
Code for 8-bit Breadboard computer (based on Ben Eater's project @ eater.net)

# Minipro programmer for Ubuntu
  # Dependencies
  sudo apt-get install build-essential pkg-config git libusb-1.0-0-dev zlib1g-dev
  
  # Clone Repo
  git clone https://gitlab.com/DavidGriffith/minipro.git
  cd minipro
  make
  sudo make install

  # UDEV configuration
  sudo cp udev/*.rules /etc/udev/rules.d/
  sudo udevadm trigger
  sudo usermod -a -G plugdev YOUR-USER

  # BASH completion
  sudo cp bash_completion.d/minipro /etc/bash_completion.d/

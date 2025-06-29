# Breadboard 6502 Computer
Code for 8-bit Breadboard computer (based on Ben Eater's project @ eater.net)

# Obtain the toolset
## Minipro programmer for Ubuntu
  ### Dependencies
  ```
  sudo apt-get install build-essential pkg-config git libusb-1.0-0-dev zlib1g-dev
  ```

  ### Clone Repo
  ```
  git clone https://gitlab.com/DavidGriffith/minipro.git
  cd minipro
  make
  sudo make install
  ```

  ### UDEV configuration
  ```
  sudo cp udev/*.rules /etc/udev/rules.d/
  sudo udevadm trigger
  sudo usermod -a -G plugdev YOUR-USER
  111

  ### BASH completion
  ```
  sudo cp bash_completion.d/minipro /etc/bash_completion.d/
  ```

## 6502 assembler
  ### Download from:
  http://sun.hasenbraten.de/vasm/index.php?view=relsrc

  ### Make
  ```
  make CPU=6502 SYNTAX=oldstyle
  ```

  This will create a executable called **vasm6502_oldstyle**

## CC65 Assembler & Linker
  ### Download from:
  https://github.com/cc65/cc65

# Common Commands
  ```
  ./vasm6502_oldstyle -Fbin -dotdir -c02 <input_file>
  ./ca65 <input_file>
  ./ld65 -C bios.cfg <input_file.o> -Ln bios.sym
  
  minipro -p AT28C256 -w a.out
  ```
  

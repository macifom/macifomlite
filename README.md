# macifomlite

Macifomlite is the official iOS port of Macifom - a highly-accurate NES emulator and debugger for OS X written in Objective-C.
The latest version of Macifomlite features:

 * Cycle-exact CPU (2A03) emulation for valid opcodes
 * Scanline-accurate PPU (2C02) emulation
 * Excellent sound reproduction care of Blargg's Nes_snd_emu library
 * Supports external video for play on TV (requires HDMI adapter)
 * Support for touch and iCade controls
 * Supports games designed for NROM, UxROM, CNROM, AxROM, SNROM, SUROM, TxROM, VRC1, VRC2a, VRC2b, and iNES #184 (Sunsoft) boards.
 * Automatic saving of cartridge SRAM to flash

## About our License

The Macifomlite sources are provided under the MIT License, but embeds Shay Green's Nes_snd_emu library which is licensed under the GNU LGPL. See http://www.slack.net/~ant/libs/audio.html for details and visit http://www.gnu.org/licenses/lgpl.html for a copy of the LGPL License. Macifomlite also includes Stuart Carnie's MIT Licensed iCade reader library.

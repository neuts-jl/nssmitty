# nssmitty
Description : 
NSMITTY is nostalgically and heavily inspired by SMITTY AIX.
NSSMITY is an interactive interface application designed to
simplify system management tasks. The nssmitty command displays
a hierarchy of menus that can lead to interactive dialogs.
NSSMITY creates and executes commands according to the user's
instructions. Since NSSMITTY executes commands, you must have
the necessary authority to execute the commands it executes.

## Features : 
- Interactive menu interface
- User assistance
- Traceability of operations
- Shortcuts to screens example: nsmitty chuser
- Scalable system: some programs also install nssmitty menu entries
- Possibility of displaying online commands performed
 (to be able to make scripts later for example)

## Command line :
Usage: nssmitty [options] [shortcut]
Available options:
  -h, --help      Show this help
  -v, --version   Show the version
  -a, --ascii     Run in ascii characters
  -n, --nolog     No log file generation, for console trouble or other
  -w, --wsl       Use Windows Subsystem for Linux
  -l, --log       (-l File) Redirects the nssmitty.log file to the specified File.
  -s, --script    (-s File) Redirects the nssmitty.sh script file to the specified File.
  -U, --update    Build screens database, connects new screens to existing menus
  -V, --verify    Verify screens database
  -B, --build     Build shortcuts dico

## WARNING : 
This program does not use the CRT unit, because it disrupts
the proper functioning of the console, especially for launched
shells.

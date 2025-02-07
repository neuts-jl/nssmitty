# nssmitty a lightweight SMITTY(AIX) for linux

NSMITTY is nostalgically and heavily inspired by SMITTY AIX.
NSSMITY is an interactive interface application designed to
simplify system management tasks. The nssmitty command displays
a hierarchy of menus that can lead to interactive dialogs.
NSSMITY creates and executes commands according to the user's
instructions. Since NSSMITTY executes commands, you must have
the necessary authority to execute the commands it executes.
It is compiled under LAZARUS with my lib [ttyconsole](https://github.com/neuts-jl/ttyconsole)

## Contribute: 
You can contribute to this development by creating the screen files, 
this will allow you to share your LINUX knowledge.

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

## Screen file structure :
[specification screens](https://github.com/neuts-jl/ttyconsole/spec-screens.pdf

## screen file example
```ini
title = Change User Password
type = form
shortcut = passwd
parent = user_mgmt_menu
logconsole = no
action = \
    CMD="passwd"
    CMD="$CMD $Username"
    echo "Changing password for user: $Username"
    eval "$CMD"
    if [ $? -eq 0 ]; then
        echo "Password changed successfully."
    else
        echo "Error while changing the password."
    fi

caption = User name
name = Username
help = Select the username of the account to change the password for.
type = list
values = $(cut -d: -f1 /etc/passwd)
required = yes

## WARNING : 
This program does not use the CRT unit, because it disrupts
the proper functioning of the console, especially for launched
shells.

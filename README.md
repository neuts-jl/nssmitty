# nssmitty a lightweight SMITTY(AIX) for linux

NSMITTY is nostalgically and heavily inspired by SMITTY AIX.
NSSMITY is an interactive interface application designed to
simplify system management tasks. The nssmitty command displays
a hierarchy of menus that can lead to interactive dialogs.
NSSMITY creates and executes commands according to the user's
instructions. Since NSSMITTY executes commands, you must have
the necessary authority to execute the commands it executes.

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
| Tag        | Position in file | Default | Position  | Description                                                                                  |
|------------|----------------|---------|-----------|----------------------------------------------------------------------------------------------|
| title      | yes            | yes     | yes       | Required File begin Defines the title of the screen.                                         |
| type       | menu           | report  | form      | menu Anywhere Specifies the type of the screen.                                              |
| help       | yes            | yes     | yes       | Provides contextual help to explain the purpose of the screen.                               |
| action     | no             | yes     | yes       | Required Anywhere Contains the script or command that will be executed when the user submits the screen. |
| parent     | yes            | yes     | yes       | Indicates the parent menu to which this screen belongs.                                      |
| logconsole | no             | no      | yes       | Allows capturing of the console display, to be disabled if display problem and/or interactive shell. |
| shortcut   | yes            | yes     | yes       | Sets a shortcut to execute the screen.                                                      |
| caption    | yes            | no      | yes       | Required To start field Defines the label displayed for the field.                          |
| type       | action         | no      | input     | Specifies the type of the field.                                                            |
| name       | no             | no      | yes       | Defines the internal name of the field, used in the script. It must be unique.              |
| help       | yes            | no      | yes       | Provides contextual help to explain the purpose of the field.                               |
| default    | no             | no      | yes       | Specifies the default value based on the user's selection.                                  |
| condition  | no             | no      | yes       | Set a condition to display or enable the field. You must specify the name of another field. If this condition field is empty, the field will be invisible. |
| values     | no             | no      | yes       | (Only for lists) Defines the available options. If the content starts with `$(...)`, the shell provides the values, otherwise fixed values are separated by commas. |
| required   | no             | no      | yes       | Indicates whether the field is mandatory.                                                   |
| action     | yes            | no      | no        | Required if menu Anywhere Contains the script or command that will be executed when the user submits the item. |

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

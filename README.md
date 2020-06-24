## Home Automat

Home Automat is a smarthome hub, which unifies the way you talk to your smarthome devices via different protocolls. It is written in Bash only, so it should be easily deployable on Ubuntu-Based systems, as well as on other Linux Distributions

# Setup

## Requirements
- nmap, arp \[for detetmining IPs from MACs\]
- fping \[to determine Power status\]
- wakeonlan \[for the ON-Command on many devices\]
- php-cgi \[for the viera plugin\]
- ssh \[for the SSH Plugin\]
- lsof \[for managing Sockets in the SSH Plugin\]
- pacmd \[for determining media-status in SSH Plugin\]
- curl \[for the http Plugin\]
- irsend \[for the lirc Plugin\]
- python \[for the python Plugin\]


## Install
The homeAutomat is mainly a bash script, which can be called for every command that should be send to any of the configured devices. It does not need to be installed. However for maintaining the connections and to provide reverse IP Lookup, the script connectionCheck.sh should be executed in the background periodically (1/min). This is achieved easiest by adding it to the crontab:
- input into a terminal: crontab -e
- add the following line to the bottom of the file:
 * *  *   *   *     /home/pi/homeAutomat/connectionCheck.sh

The SSH Plugin uses PrivatKeyAuthentication. In order for this to work an SSH key needs to be created (ssh-keygen) and then authenticated on all SSH devices (ssh-copy-id). This has the added benefit, that no cleartext passwords have to be stored in the configuration files for homeAutomat.
After having copied the key, try to connect manually via SSH once to prevent any problems with the SSH-fingerprint.

## Configuration
All configurations are bundled into the file ha.conf. Copy the file ha.conf.example into a new file ha.conf and change the correct settings.

The general settings are:
- ha_user: name of the user the homeAutomat should execute commands as
- primary_iface: Name of the network interface, network devices should be contacted.

The main part of the configuration are the configurations of the devices. For each protocol there is one example in the example file. The main settings are:
- type: The protocol with which this device should be handled.
- ips: The IP addresses for this device, devided by |
- macs: The MAC addresses for this device, devided by |. The MAC is used for WakeOnLan and to reverse-lookup the ip, if non is given
- wol: Set to any value, if the device supports WakeOnLan
- playback: Set to any value, if this device should be considered for playback

Some parameters are dependent on the plugin:
- user \[SSH\]: Name of the remote user
- cmd \[http, pathon\]: path/script that should be executed for every send command of this device (replacing the ip of the device by \_\_IP\_\_ and the command by \_\_CMD\_\_).

Additionally any device might overwrite some commands. This is dann by setting overwritten command to DEVICE|cmd|CMD, where DEVICE is the name of the device and CMD is the command that should be executed.
Also for lirc devices the number of repetitions for any device can be set by setting a number to DEVICE|CMD|repeat, where DEVICE is the name of the device and CMD is the command that sould be executed multiple times, when requested.


# Protocolls
Each Protocol is packaged into its own script, for example ha_ssh.sh for ssh devices. 

Each Plugin implements some of the following hooks:
- update: This hook is triggered, when the connections are checked, might establish a new connection, if necessary
- is_availabe: This hook is triggered to determine, if this device is available.
- is_playing: This hook is triggered to determine, if this device is currently playing media
- lookup_cmd: This hook is triggered when a command is to be send. The requested command is passed as parameter. The function should return the actual command to be send
- send: This hook is called, if a command is to be send to this device
- get: This hook is called, if a command with an expected return-value is to be send to this device

The following Plugins are implemented right now:
## lirc
Sends IR commands via LIRc (seperate configuration of lirc needed)
## http
Sends commands via http (can be used for example for Tasmota/Sonoff devices)
## python
Executes a python command for every command. Can for example command a TP-Link smartSocket with the kasa.py script
## SSH
The SSH Plugin connects to a device via SSH. It maintains an SSH connection with all currently available devices using files in the folder SSHSockets for input and output.
## viera
Sends RemoteControll commands to Toshiba TVs

## Adding Protocolls
New Plugins can be added easily, by using the following steps:
- Create a new sh file in the homeAutomat folder.
- Implement the needed hooks. Each hook needs to be implemented as TYPE_HOOK, where TYPE is the name for the newly implemented protocol and HOOK is the function that is impelemented. For example "ssh_is_available" implements the "is_available" hook for the ssh protocol.
- Add the plugin-file to ha_plugins.sh
- Create a new configuration with a device, setting the new plugin as type.

Each non-implemented hook is replaced by a default value.

# Usage
## Sending commands
Sending a command is as easy as executing the script send.sh with the name of the device and the command to be send.
## The __CURRENT__ Device
For easy control of multiple multimedia devices, the script tracks the most-current device. It takes into account, which devices are available, have playback enabled and the time of the last command send to all devices. Instead of sending commands to any device, the command can be send to the virtual device \_\_CURRENT\_\_ and it will be send to the last used available device.
## General Commands
homeAutomat also has some commands, which are correctly replaced by any plugin.
- \_\_PLAY\_\_, \_\_PAUSE\_\_: Starts/Pauses playback
- \_\_ON\-\-, \_\_OFF\_\_: turns the device on/off
- \_\_NETFLIX\_\_: Starts Netflix
- \_\_FULLSCREEN\_\_: enables fullscreen for the currently running media

# Suggestions
## Deployment:
The Code runs well on a Raspberry Pi 3B. 

## Interfaces:
- XDoTool can be used to simulate mouse and keyboard-inputs on an SSH device.
- Since the send.sh command is a bash script, it can be called from [HA Bridge](https://github.com/bwssytems/ha-bridge). Simply create a new Bridge Device with the Device Type "Execute Script/Program" and call send.sh from the Target Item in On/Off Items
- From the HA Bridge Alexa can find the devices and thus access the SmartHome Devices configured with Home Automat
- The Android APP [Home Remote Control](https://play.google.com/store/apps/details?id=com.inspiredandroid.linuxcontrolcenter&hl=en) can call the send.sh script via SSH. This way all SmartHome Devices configured with Home Automat can be controlled from your phone. As an added benefit this way the Mouse and Keyboard control in HomeRemote can always be send the CURRENT device
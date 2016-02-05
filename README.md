#pimatic-arduino-manager
=======================

Plugin to manage and update the Software for every "Arduino" connected to Pimatic.

This plugin provides the serial connection for other plugins and handles software
updates on our Arduinos.

Every Plugin, which will profit from this behavior must implement the SerialPort from this plugin.
And it must provide informations for the Arduino and the sourcecode for this.
Also an function which returns an path to the neu updated source code.

![Schematic](https://raw.githubusercontent.com/Icesory/pimatic-arduino-manager/master/arduino-manager-sch.jpg)
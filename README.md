# check_ipp.pl

File: check_iprinters.pl

Author: dbenjamin

Created: Aug 4, 2015

Release: 0.0.3


Tested against Novell iPrint Server 6.7.0.20150629-0.6.6, running on SLES 11, SP3 with OES 11, SP2.

***

Usage: check_iprinters.pl -I <host address> -Q <queue name> [-P <port> default=631] [-v enable verbose] [--version]

## Required
* -I  Host IP address.
* -Q  Queue name. This can be found by browsing to your iPrint server at `http://<server ip address>:<port, default=631>/ipp/` each printer queue name should be listed.

## Options
* -P  Port to use for testing, the default is 631.
* -F  Filter in regular expression format.
* -v  Enable verbose output for testing, do not use this in your monitoring software.
* --version   Output some version information, do not use this in your monitoring software.

## Integration
You can integrate with Icinga2 following these instructions.

1. Download the check_ipp.pl script.
1. Find the CustomPluginDir path in /etc/icinga2/constants.conf or where your distro may have placed the config file.
1. Place the check_ipp.pl script in the CustomPluginDir directory and make the file executable.
1. Define the service.
   * I created a file in /etc/icinga2.conf/ named iprinters.conf containing:
   ```C
   object CheckCommand "iprinters" {
      import "plugin-check-command"
   
      command = [ CustomPluginDir + "/check_iprinters.pl" ]
   
      arguments = {
         "-I" = "$address$"
         "-Q" = "$iprint_queue$"
         "-F" = "(empty)|(shut down)"
      }
   }
   apply Service for (iPrint => config in host.vars.iprinters) {
      import "generic-service"
      
      check_command = "iprinters"
      
      vars += config
   }
   ```
1. Define iPrint queue attributes in your host definitions.
   * Mine looks like this, *yes the queue name is "7UP"*:
   ```C
   /* Define iPrint queue attributes for service apply rules. */
      vars.iprinters["iprint 7UP"] = {
         iprint_queue = "7UP"
      }
   ```

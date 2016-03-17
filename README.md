# dd-wrt
svn://svn.dd-wrt.com/DD-WRT

**Fork for Huawei WS880 router support**

- Have fixes for buld, web UI, services
- Included USB audio support
- Dark interface switch
- Entware-ng install script
- Proper russian language

and more...

FW for WS880 available in **[downloads](https://github.com/tsynik/dd-wrt/tree/master/downloads)** directory

Also possible to build for other Northstar routers:
Asus AC-56/68/87U, Netgear R6300v2/R7000/R8000 etc

Look at build.sh for some info and initial configuration.

You also need musl-1.1.11 toolchain, which can be obtained from dd-wrt ftp:

ftp://ftp.dd-wrt.com/toolchains/

Yeah, it's dumb to pack it like this! Blame BrainSlayer for that size.

Recommended build system: *Ubuntu 14.04 LTS 32/64bit*

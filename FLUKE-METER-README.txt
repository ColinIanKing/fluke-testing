== Configuration of 8846A Fluke Meter ==

We need to ensure the Fluke Meter is connected to a network
and that the DHCP server is configured to provided the meter
with a static IP.

a) Connect the Fluke meter to the network

b) Ensure the Fluke meter is configured to boot and configure it's
ethernet using DHCP:

1. Press "INSTR SETUP"
2. Press "F1" (PORT IF)
3. Press "F3" (LAN)
4. Press "F1" to ensure the "DHCP" setting is highlighted"
5. Press "Memory"
6. Press "F3" (STORE CONFIG)
7. Press "F3" (STORE POWER-UP)

c) Now turn off power (at back) and power up, it should be configured up
with the appropriate IP address and should be ping'able. Test if you can
ping it.

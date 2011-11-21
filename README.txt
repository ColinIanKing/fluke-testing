-- Server --

Configure Fluke 8846A to accept telnet on port 3490

Build and run udp-relay as a background task, this listens to UDP
message from the client on port 9999 and relays this to port 3500.

Run logdata.sh, this measures current readings from the Fluke
and waits for messages from the client via udp-relay.

-- Client --

Clone this git repo onto the client, when the server is configured
and running logdata.sh, run the test script test.sh

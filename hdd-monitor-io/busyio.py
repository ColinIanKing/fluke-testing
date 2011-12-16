#!/usr/bin/python

import select
import subprocess
import sys
import os

if os.geteuid() != 0:
	print "This needs to be run as root."
	exit(0)

if not os.path.isfile("/usr/bin/stap"):
	print "systemtap needs to be installed."
	exit(0)

#
#  Default to run for 60 seconds
#
duration = 60

if len(sys.argv) > 1:
	duration=int(sys.argv[1])

cmd = [ "stap", "-g", "busyio.stp", "5", str(duration) ]
proc = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE)

stderr_open = True
stdout_open = True

while stderr_open or stdout_open:
	try:
		readable, writeable, exceptional = select.select([proc.stderr.fileno(), proc.stdout.fileno()], [], [])
		for i in readable:
			if i == proc.stderr.fileno():
				line = proc.stderr.readline()
				if line == "":
					stderr_open = False
				#else:
					#sys.stderr.write(line)
			
			if i == proc.stdout.fileno():
				line = proc.stdout.readline()
				if line == "":
					stdout_open = False
				else:
					if line.find("SYNC",0) == 0:
						print "Syncing.."
						subprocess.call(["sync"])
					else:			
						sys.stdout.write(line)
	except IOError, x:
		if x.errno != errno.EAGAIN:
			raise
					
proc.wait()

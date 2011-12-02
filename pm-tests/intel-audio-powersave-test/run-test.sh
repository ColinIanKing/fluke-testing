run_test()
{

	# play samples so driver can enter power save mode
	(dd if=/dev/zero bs=1024 count=1 | aplay) >& /dev/null
	
	/usr/lib/pm-utils/power.d/intel-audio-powersave $1

	${SENDTAG_BEGIN}
	sleep ${SLEEP_DURATION}
	${SENDTAG_END}

	/usr/lib/pm-utils/power.d/intel-audio-powersave false
}

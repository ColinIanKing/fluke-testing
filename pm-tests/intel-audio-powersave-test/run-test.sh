run_test()
{
	chmod -x /usr/lib/pm-utils/power.d/*
	chmod +x /usr/lib/pm-utils/power.d/intel-audio-powersave

	# play samples so driver can enter power save mode
	(dd if=/dev/zero bs=1024 count=1 | aplay) >& /dev/null
	
	${SENDTAG_BEGIN}
	sleep ${SLEEP_DURATION}
	${SENDTAG_END}

	chmod +x /usr/lib/pm-utils/power.d/*
}

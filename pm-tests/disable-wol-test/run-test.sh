run_test()
{
	
	${SENDTAG_BEGIN}
	sleep ${SLEEP_DURATION}
	/usr/lib/pm-utils/power.d/disable_wol $1
	${SENDTAG_END}

	#
	# And disable afterwards
	#
	/usr/lib/pm-utils/power.d/disable_wol false
}

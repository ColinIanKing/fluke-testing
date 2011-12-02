run_test()
{
	/usr/lib/pm-utils/power.d/wireless $1

	${SENDTAG_BEGIN}
	sleep ${SLEEP_DURATION}
	${SENDTAG_END}

	/usr/lib/pm-utils/power.d/wireless false
}

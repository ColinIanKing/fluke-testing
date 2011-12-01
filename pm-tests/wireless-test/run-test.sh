run_test()
{
	chmod -x /usr/lib/pm-utils/power.d/*
	chmod +x /usr/lib/pm-utils/power.d/wireless

	${SENDTAG_BEGIN}
	sleep ${SLEEP_DURATION}
	${SENDTAG_END}

	chmod +x /usr/lib/pm-utils/power.d/*
}

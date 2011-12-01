run_test_idle()
{
	chmod -x /usr/lib/pm-utils/power.d/*
	chmod +x /usr/lib/pm-utils/power.d/sata_alpm
	
	${SENDTAG_BEGIN}
	sleep ${SLEEP_DURATION}
	${SENDTAG_END}

	chmod +x /usr/lib/pm-utils/power.d/*
}


run_test_make()
{
	chmod -x /usr/lib/pm-utils/power.d/*
	chmod +x /usr/lib/pm-utils/power.d/sata_alpm
	
	pushd ../busybox-src/busybox-1.18.4 >& /dev/null
	${SENDTAG_BEGIN}
	make clean
	make
	make clean
	${SENDTAG_END}
	popd >& /dev/null

	chmod +x /usr/lib/pm-utils/power.d/*
}

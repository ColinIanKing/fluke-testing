run_test_idle()
{
	mkdir -p /var/run/pm-utils/storage
	/usr/lib/pm-utils/power.d/laptop-mode $1
	
	${SENDTAG_BEGIN}
	sleep ${SLEEP_DURATION}
	${SENDTAG_END}

	/usr/lib/pm-utils/power.d/laptop-mode false
}


run_test_make()
{
	mkdir -p /var/run/pm-utils/storage
	/usr/lib/pm-utils/power.d/laptop-mode $1
	
	pushd ../busybox-src/busybox-1.18.4 >& /dev/null
	${SENDTAG_BEGIN}
	make clean
	make
	make clean
	${SENDTAG_END}
	popd >& /dev/null

	/usr/lib/pm-utils/power.d/laptop-mode false
}

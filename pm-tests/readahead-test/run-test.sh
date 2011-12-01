run_test()
{
	chmod -x /usr/lib/pm-utils/power.d/*
	chmod +x /usr/lib/pm-utils/power.d/readahead
	
	pushd ../busybox-src/busybox-1.18.4 >& /dev/null
	${SENDTAG_BEGIN}
	make clean
	make
	make clean
	${SENDTAG_END}
	popd >& /dev/null

	chmod +x /usr/lib/pm-utils/power.d/*
}

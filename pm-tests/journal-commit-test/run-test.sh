run_test()
{
	chmod -x /usr/lib/pm-utils/power.d/*
	chmod +x /usr/lib/pm-utils/power.d/journal-commit
	
	pushd ../busybox-src/busybox-1.18.4 >& /dev/null
	${SENDTAG_BEGIN}
	make clean
	make -j 4
	make clean
	${SENDTAG_END}
	popd >& /dev/null

	chmod +x /usr/lib/pm-utils/power.d/*
}

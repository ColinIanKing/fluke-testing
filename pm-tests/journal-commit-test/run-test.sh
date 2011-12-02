run_test()
{
	/usr/lib/pm-utils/power.d/journal-commit $1
	
	pushd ../busybox-src/busybox-1.18.4 >& /dev/null
	${SENDTAG_BEGIN}
	make clean
	make -j 4
	make clean
	${SENDTAG_END}
	popd >& /dev/null

	/usr/lib/pm-utils/power.d/journal-commit false
}

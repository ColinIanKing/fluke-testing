run_test()
{
	/usr/lib/pm-utils/power.d/readahead $1
	
	pushd ../busybox-src/busybox-1.18.4 >& /dev/null
	${SENDTAG_BEGIN}
	make clean
	make
	make clean
	${SENDTAG_END}
	popd >& /dev/null

	/usr/lib/pm-utils/power.d/readahead false
}

run_apps_test()
{
	/usr/lib/pm-utils/power.d/readahead $1
	rm -rf ~/.mozilla/firefox

	${SENDTAG_BEGIN}
	banshee --play-enqueued --stop-when-finished ../assets/sample-audio.mp3 &
	sleep 60
	firefox smackerelofopinion.blogspot.com &
	sleep 60
	firefox lego-maker.blogspot.com &
	sleep 60
	firefox slashdot.com &
	sleep 60
	firefox boingboing.com &
	sleep 60
	thunderbird &
	sleep 60
	killall -9 banshee
	sleep 60
	killall -9 firefox
	sleep 60
	killall -9 thunderbird-bin
	sleep 20
	${SENDTAG_END}
	
	/usr/lib/pm-utils/power.d/readahead false
}

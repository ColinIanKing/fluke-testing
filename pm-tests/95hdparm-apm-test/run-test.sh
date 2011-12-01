run_test()
{
	chmod -x /usr/lib/pm-utils/power.d/*
	chmod +x /usr/lib/pm-utils/power.d/95hdparm-apm
	
	${SENDTAG_BEGIN}
	for I in {1..6}
	do
		find /usr/lib/pm-utils > /tmp/find.$$
		rm /tmp/find.$$
		sleep 10
	done
	${SENDTAG_END}

	chmod +x /usr/lib/pm-utils/power.d/*
}

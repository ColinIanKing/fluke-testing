run_test()
{
	if $1 ; then
		export AC_POWER_SETTING=$AC_POWER_OFF
		/usr/lib/pm-utils/power.d/95hdparm-apm true
	else
		export AC_POWER_SETTING=$AC_POWER_ON
		/usr/lib/pm-utils/power.d/95hdparm-apm false
	fi
	
	${SENDTAG_BEGIN}
	for I in {1..6}
	do
		find /usr/lib/pm-utils > /tmp/find.$$
		rm /tmp/find.$$
		sleep 10
	done
	${SENDTAG_END}

	# and disable afterwards
	export AC_POWER_SETTING=$AC_POWER_ON
	/usr/lib/pm-utils/power.d/95hdparm-apm false
}

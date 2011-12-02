run_test_set()
{
	if $1 ; then
		export AC_POWER_SETTING=$AC_POWER_OFF
		/usr/lib/pm-utils/power.d/95hdparm-apm true
	else
		export AC_POWER_SETTING=$AC_POWER_ON
		/usr/lib/pm-utils/power.d/95hdparm-apm false
	fi

	/usr/lib/pm-utils/power.d/disable_wol $1

	(dd if=/dev/zero bs=1024 count=1 | aplay) >& /dev/null

	/usr/lib/pm-utils/power.d/intel-audio-powersave $1

	/usr/lib/pm-utils/power.d/journal-commit $1

	mkdir -p /var/run/pm-utils/storage
	/usr/lib/pm-utils/power.d/laptop-mode $1

	/usr/lib/pm-utils/power.d/pcie_aspm $1

	echo "SATA_ALPM_ENABLE=true" > /etc/pm/config.d/sata_alpm 
	/usr/lib/pm-utils/power.d/sata_alpm $1

	/usr/lib/pm-utils/power.d/sched-powersave $1

	/usr/lib/pm-utils/power.d/wireless $1
}

run_test_unset()
{
	export AC_POWER_SETTING=$AC_POWER_ON
	/usr/lib/pm-utils/power.d/95hdparm-apm false

	/usr/lib/pm-utils/power.d/disable_wol false

	(dd if=/dev/zero bs=1024 count=1 | aplay) >& /dev/null
	/usr/lib/pm-utils/power.d/intel-audio-powersave false

	/usr/lib/pm-utils/power.d/journal-commit false

	mkdir -p /var/run/pm-utils/storage
	/usr/lib/pm-utils/power.d/laptop-mode false

	/usr/lib/pm-utils/power.d/pcie_aspm false

	echo "SATA_ALPM_ENABLE=true" > /etc/pm/config.d/sata_alpm 
	/usr/lib/pm-utils/power.d/sata_alpm false
	rm -f /etc/pm/config.d/sata_alpm

	/usr/lib/pm-utils/power.d/sched-powersave false

	/usr/lib/pm-utils/power.d/wireless false
}

run_test_idle()
{
	${SENDTAG_BEGIN}
	sleep ${SLEEP_DURATION}
	${SENDTAG_END}
}


run_test_make()
{
	pushd ../busybox-src/busybox-1.18.4 >& /dev/null
	${SENDTAG_BEGIN}
	make clean
	make
	make clean
	${SENDTAG_END}
	popd >& /dev/null
}

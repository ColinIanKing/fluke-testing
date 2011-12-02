run_test_idle()
{
	echo "SATA_ALPM_ENABLE=true" > /etc/pm/config.d/sata_alpm 
	/usr/lib/pm-utils/power.d/sata_alpm $1
	
	${SENDTAG_BEGIN}
	sleep ${SLEEP_DURATION}
	${SENDTAG_END}

	/usr/lib/pm-utils/power.d/sata_alpm false
	rm /etc/pm/config.d/sata_alpm
}


run_test_make()
{
	echo "SATA_ALPM_ENABLE=true" > /etc/pm/config.d/sata_alpm 
	/usr/lib/pm-utils/power.d/sata_alpm $1
	
	pushd ../busybox-src/busybox-1.18.4 >& /dev/null
	${SENDTAG_BEGIN}
	make clean
	make
	make clean
	${SENDTAG_END}
	popd >& /dev/null

	/usr/lib/pm-utils/power.d/sata_alpm false
	rm /etc/pm/config.d/sata_alpm
}

{
	if ($1 == "User") {
		u++
		if (u == 1)
			next
	} else {
		u = 0
	}
	if ($1 == "Test")
		next
	if ($1 == "exit")
		next
	if ($1 == "Release:") {
		#print ""
		c=index($2, ",")
		if (c)
			rel= substr($2, 1, c - 1)
		else
			rel = $2
		#print "Release: ", rel
		r=1
		t=""
		for (i = 4; i <= NF; i++) {
			#printf $i
			t = t "" $i
			if (i != NF) {
				#printf " "
				t = t " "
			}
		}
		
		#print ""
		#print t
		idx = 0

		releases[rel] = rel
		tests[t]++

		next

	}

	str=""
	for (i = 1; i <= NF; i++) {
		if ($i == "W")
			continue

		s=$i

		if ($i == "User")
			s = "User %"
		if ($i == "Nice")
			s = "Nice %"
		if ($i == "Sys")
			s = "Sys %"
		if ($i == "Idle")
			s = "Idle %"
		if ($i == "IO")
			s = "IO %"
		if ($i == "Fork")
			s = "Forks/s"
		if ($i == "Exec")
			s = "Exec/s"
		if ($i == "Exit")
			s = "Exit/s"
		if ($i == "GPU")
			s = "GPU W"
		if ($i == "uncore")
			s = "uncore W"
		if ($i == "core")
			s = "core W"
		if ($i == "pkg-0")
			s = "package W"
		if ($i == "x86_pk")
			s = "x86_pk C"
		if ($i == "acpitz")
			s = "acpitz C"

		#printf "%s", s
		str = str "" s
		if (i != NF) {
			#printf ","
			str = str ","
		}
	}
	data[t][rel][idx] = str
	idx = idx + 1
	#print str
}

END {
	nt = asorti(tests)
	nr = asorti(releases)
	for (it = 1; it <= nt; it++) {
		t = tests[it]
		l = 0
		print "Test: ", t
		l = l + 1
		print ""
		l = l + 1
		for (ir = nr; ir > 0; ir--) {
			rel = releases[ir]
			print rel
			l = l + 1
			for (i = 0; i < 6; i++) {
				print ","data[t][rel][i]
				l = l + 1
			}
			printf "Average:"
			for (i = 1; i <= 19; i++) {
				c = substr("BCDEFGHIJKLMNOPQRSTUVWXYZ", i, 1)
				printf(",=average(%s%d:%s%d)", c, l - 4, c, l)
			}
			print ""
			l = l + 1

			printf "Std.Dev.:"
			for (i = 1; i <= 19; i++) {
				c = substr("BCDEFGHIJKLMNOPQRSTUVWXYZ", i, 1)
				printf(",=stdev(%s%d:%s%d)", c, l - 4, c, l)
			}
			print ""
			l = l + 1
			print ""
			l = l + 1
		}
		print ""
		l = l + 1
	}
}

busyio.py is a wrapper for the systemtap script busyio.stp

Run with:

./busyio.py [ duration ]

e.g.

./busyio.py 60

Fri Dec 16 18:53:30 2011 , Average: 865Kb/sec, Read:    4328Kb, Write:      1Kb

     UID      PID     PPID             Cmd   Device T Size,inode/Filename
    1001     2780     2761 npviewer.bin        sda2 R     4M,  396806
    1001    13626        1 gnome-terminal      sda2 W    53B,  396809
    1001    13626        1 gnome-terminal      sda2 W    16B,  396810
    1001    13626        1 gnome-terminal      sda2 R     1K,  396810
    1001    13626        1 gnome-terminal      sda2 R     2K,  396809
    1001     2227        1 xchat-gnome         sda5 W   197B,11403631
    1001     1916     1855 gnome-settings-     sda2 R   979B, 1439110
    1001     2227        1 xchat-gnome         sda5 W   105B,11403577
    1001     1950     1855 indicator-weath     sda5 W   205B,11798403
    1001     2025        1 unity-panel-ser     sda2 R    14B, 1439190
    1001     2227        1 xchat-gnome         sda5 W    97B,11403412
    1001     2227        1 xchat-gnome         sda2 R   734B, 1315488
    1001     1923        1 gconfd-2            sda5 W   710B,11145381
    1001     2761     2731 plugin-containe   pipefs D 
    1001     3212        1 thunderbird-bin   pipefs D 
    1001     2731        1 firefox           pipefs D 
       0    21609    21608 stapio            pipefs D 
       0    21446    21445 busyio.py         pipefs D 
    1001    13626        1 gnome-terminal      sda2 D 
       0     1115        2 jbd2/sda5-8              D 
    1001     2227        1 xchat-gnome         sda5 D Canonical-#canonical.log
       0      315        2 jbd2/sda2-8              D 
    1001     1916     1855 gnome-settings-     sda5 D 
    1001     1916     1855 gnome-settings-     sda5 D user
    1001     2227        1 xchat-gnome         sda5 D FreeNode-#ubuntu-devel.log
    1001     1950     1855 indicator-weath     sda5 D indicator-weather.log
    1001     2227        1 xchat-gnome         sda5 D FreeNode-#ubuntu-kernel.log
    1001     1923        1 gconfd-2            sda5 D %gconf.xml.new
    1001     1923        1 gconfd-2            sda5 D 
 
The T column is either:
	R - read
	W - write
	D - dirty pages 


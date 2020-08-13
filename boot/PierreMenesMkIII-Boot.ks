core:part:getmodule("kOSProcessor"):doevent("Open Terminal").
// runpath("0:/FlantierIV-Mk2.ks").

CLEARSCREEN.
PRINT "Pierre Ménès Mk III
Copyright 2020, 2020
Bristol Inc.
Pierre Ménès Mk III kOS script
Copyright 2020, 2020
Exo Corp.
Tous droits réservés.
Si vous plagiez on vous nique.".
PRINT " ".
PRINT "PierreMenesMkIII-Boot.ks Build 101".
PRINT " ".
PRINT "CPU : KR-2042 b Scriptable Control System
Disk 0 : kOS Hard Disk 20000 Bytes".
PRINT " ".
PRINT "BOOT OPTIONS :
10 : LAUNCH SEQUENCE
9 : Node Autopilot
".

ON AG10 {
	PRINT "INITIATING LAUNCH SEQUENCE".
	WAIT 1.
	runpath("0:/PierreMenesMkIII.ks").
	PRESERVE.
}

ON AG9 {
	PRINT "LAUNCHING NODE AUTOPILOT SCRIPT".
	WAIT 1.
	runpath("0:/FlantierIV-Mk2-NodeAP.ks").
	PRESERVE.
}

WAIT UNTIL False.
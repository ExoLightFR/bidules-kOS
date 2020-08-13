core:part:getmodule("kOSProcessor"):doevent("Open Terminal").
// runpath("0:/FlantierIV-Mk2.ks").

CLEARSCREEN.
PRINT "Flantier IV Mk. II
Copyright 2019, 2020
Flantier IV Mk. II kOS autopilot
Copyright 2020, 2020
Exo Corp.
Tous droits réservés.
Elon Musk me voilà.".
PRINT " ".
PRINT "FlantierIV-Mk2-Boot.ks Build 201".
PRINT " ".
PRINT "CPU : KAL-9000 Scriptable Control System
Disk 0 : kOS Hard Disk ???? Bytes".
PRINT " ".
PRINT "BOOT OPTIONS :
10 : LAUNCH SEQUENCE
9 : Node Autopilot
8 : Hohmann Orbit Transfer Autopilot".
PRINT " ".

ON AG10 {
	PRINT "Initiating launch sequence.".
	WAIT 1.
	runpath("0:/FlantierIV-Mk2.ks").
	PRESERVE.
}

ON AG9 {
	PRINT "Initiating Node Burning autopilot".
	WAIT 1.
	runpath("0:/FlantierIV-Mk2-NodeAP-Unfucked.ks").
	PRESERVE.
}

ON AG8 {
	PRINT "Initiating Hohmann Orbit Transfer Autopilot".
	WAIT 1.
	runpath("0:/FlantierIV-Mk2-HohmannAP.ks").
	PRESERVE.
}

WAIT UNTIL False.
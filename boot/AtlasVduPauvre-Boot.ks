core:part:getmodule("kOSProcessor"):doevent("Open Terminal").
// runpath("0:/FlantierIV-Mk2.ks").

CLEARSCREEN.
PRINT "Atlas V du pauvre
Atlas V du pauvre kOS script
Copyright 2020, 2020
Exo Corp.
Tous droits réservés.
Si vous plagiez je vous nique.".
PRINT " ".
PRINT "AtlasVduPauvre-Boot.ks Build 101".
PRINT " ".
PRINT "CPU : KAL-9000 Scriptable Control System
Disk 0 : kOS Hard Disk ????? Bytes".
PRINT " ".
PRINT "BOOT OPTIONS :
10 : LAUNCH SEQUENCE
9 : Node Autopilot
".

ON AG10 {
	PRINT "INITIATING LAUNCH SEQUENCE".
	WAIT 1.
	runpath("0:/AtlasVduPauvre.ks").
	PRESERVE.
}

ON AG9 {
	PRINT "LAUNCHING NODE AUTOPILOT SCRIPT".
	WAIT 1.
	runpath("0:/FlantierIV-Mk2-NodeAP-Unfucked.ks").
	PRESERVE.
}

WAIT UNTIL False.
core:part:getmodule("kOSProcessor"):doevent("Open Terminal").
// runpath("0:/FlantierIV-Mk2.ks").

WAIT 1.
CLEARSCREEN.
PRINT "
   _________    _   ______________
  / ____/   |  / | / / ____/ ____/
 / / __/ /| | /  |/ / / __/ __/   
/ /_/ / ___ |/ /|  / /_/ / /___   
\____/_/  |_/_/ |_/\____/_____/".

ON AG10 {
	PRINT "LE GANGE TE PURIFIE !".
	WAIT 1.
	runpath("0:/FlantierIV-Mk2-Gange.ks").
	PRESERVE.
}

ON AG9 {
	PRINT "LAUNCHING NODE AUTOPILOT SCRIPT".
	WAIT 1.
	runpath("0:/FlantierIV-Mk2-NodeAP-Unfucked.ks").
	PRESERVE.
}

WAIT UNTIL False.
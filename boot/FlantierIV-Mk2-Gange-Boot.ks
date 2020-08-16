core:part:getmodule("kOSProcessor"):doevent("Open Terminal").
// runpath("0:/FlantierIV-Mk2.ks").

function bootscreen {
	CLEARSCREEN.
	PRINT "
	   _________    _   ______________
	  / ____/   |  / | / / ____/ ____/
	 / / __/ /| | /  |/ / / __/ __/   
	/ /_/ / ___ |/ /|  / /_/ / /___   
	\____/_/  |_/_/ |_/\____/_____/".
	PRINT " ".
}

bootscreen().

ON AG10 {
	PRINT "LE GANGE TE PURIFIE !".
	WAIT 1.
	runpath("0:/FlantierIV-Mk2-Gange.ks").
	WAIT 2.
	bootscreen().
	PRESERVE.
}

ON AG9 {
	PRINT "LAUNCHING NODE AUTOPILOT SCRIPT".
	WAIT 1.
	runpath("0:/FlantierIV-Mk2-NodeAP-Unfucked.ks").
	executeBurnNodev2().
	APOFF().
	WAIT 2.
	bootscreen().
	PRESERVE.
}

ON AG8 {
	PRINT "Initiating Hohmann Orbit Transfer Autopilot".
	WAIT 1.
	runpath("0:/FlantierIV-Mk2-HohmannAP.ks").
	hohmannTransfer().
	APOFF().
	WAIT 2.
	bootscreen().
	PRESERVE.
}

WAIT UNTIL False.
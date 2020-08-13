core:part:getmodule("kOSProcessor"):doevent("Open Terminal").
// runpath("0:/FlantierIV-Mk2.ks").

PRINT "Waiting for user input...".

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

WAIT UNTIL False.
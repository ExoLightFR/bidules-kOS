core:part:getmodule("kOSProcessor"):doevent("Open Terminal").
// runpath("0:/FlantierIV-Mk2.ks").

PRINT "Waiting for user input...".

ON AG10 {
	PRINT "Initiating launch sequence.".
	WAIT 1.
	runpath("0:/ArianneMerdique.ks").
	PRESERVE.
}

WAIT UNTIL False.
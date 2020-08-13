core:part:getmodule("kOSProcessor"):doevent("Open Terminal").

PRINT "Waiting for user input...".

ON AG10 {
	PRINT "Initiating launch sequence.".
	WAIT 1.
	runpath("0:/FlantierIV-Mk2.ks").
	PRESERVE.
}

WAIT UNTIL False.
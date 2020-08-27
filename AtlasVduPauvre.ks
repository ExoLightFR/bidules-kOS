function doSafeStage {
	parameter mute is False.
	parameter str is "default".
	IF NOT (defined stageCount) {
		global stageCount is 0.
	}
	kuniverse:timewarp:cancelwarp().
	WAIT UNTIL stage:ready.

	IF mute = False { // En faisant doSafeStage(True), on n'affiche pas de texte de stage.

		IF str = "default" {
			pushMasterStatus("STAGING !").
		}
		ELSE {
			pushMasterStatus(str).
		}
	}
	STAGE.
	SET stageCount to stageCount +1.
}

function jettisonCoiffev2 {
    pushMasterStatus("Fairing jettison sequence initiated.").
    pushMessage("STBY for atmo exit " + body:atm:height/1000 + " Km").
    WAIT UNTIL altitude > body:atm:height.
    doSafeStage(False, "Fairing staged."). // TODO : au lieu d'un stage un ID de ship part ?
}

function timeToGoodApoapsis { // On pourrait prendre en compte l'accélération pour avoir une bonne estimation ?...
	local t is 0.
	local d is targetAp - ship:apoapsis. // à changer pour la valeur globale de ll'alt donnée par l'user
	local v is ship:velocity:orbit:mag.
	SET t TO ROUND (d / v).

	pushMasterStatus("Good Apoapsis in " + t + "s.").
}

function orbitNode {
	local currentApVel is (body:mu * ((2 / (apoapsis + body:radius)) - (1 / ((apoapsis + body:radius*2 + periapsis) / 2))))^0.5.

	local neededVel is ((body:mu * (1 / (body:radius + apoapsis))) ^ 0.5) - currentApVel.
	local node is NODE(time:seconds+ETA:apoapsis, 0, 0, neededVel).
	ADD node.
}

// ==========================================================================================================================================
// ==========================================================================================================================================
// ==========================================================================================================================================
// ==========================================================================================================================================
// ==========================================================================================================================================

runpath("0:/FlantierIV-Mk2-UI.ks").

// Variables pour le guidage
SET AltTo0 TO 65000. //THE ALTITUDE YOU WANT THE ROCKET TO BE FULLY HORIZONTAL
SET targetAp TO 100000. //THE FINAL APOAPSIS YOU WANT TO REACH
// Équation de guidage
LOCK targetPitch TO (90-((90/100)*((SHIP:APOAPSIS/AltTo0)*100))).
SET targetDirection to 90.

LOCK steering TO heading(0, 90). // Droit vers le haut sans roulis
LOCK throttle TO 1.

pushMasterStatus("LAUNCH SEQUENCE INITIATED").
WAIT 1.
FROM {local countdown is 5.} UNTIL countdown = 0 STEP {SET countdown to countdown - 1.} DO {
	pushMasterStatus(countdown + "...").
	WAIT 1.
}

doSafeStage(False, "And we have liftoff !").

WAIT UNTIL ship:verticalspeed > 40.
pushMasterStatus("Commencing roll sequence.").
LOCK steering to heading(targetDirection, targetPitch).

SET oldThrust to ship:availableThrust.
UNTIL SHIP:APOAPSIS > targetAp { // TODO : En faire un paramètre réglable par l'utilisateur

	IF ship:availablethrust < (oldThrust - 10) {
        WAIT 1.
        doSafeStage().
        SET oldThrust TO ship:availablethrust.
  	}

  	IF ship:apoapsis > AltTo0 {
  		SET targetPitch TO 0.
  	}

	IF ship:apoapsis > 50000 {
		timeToGoodApoapsis().
	}
}
LOCK throttle TO 0.
pushMasterStatus("Apoapsis of " + targetAp + " Km reached").

LOCK steering to prograde.
WAIT UNTIL vang(ship:facing:vector, prograde) < 0.5.

IF stageCount < 3 {
    WAIT 1.
	doSafeStage().
}
ELSE {
	pushMessage("First stage already separated."). // Ne sert à rien pour le moment, cause coiffe
	pushMessage("Will not stage.").
}

jettisonCoiffev2().
doSafeStage().

runpath("0:/FlantierIV-Mk2-NodeAP-Unfucked.ks").
executeBurnNodev2().

runpath("0:/FlantierIV-Mk2-HohmannAP.ks").
hohmannTransfer(110000).

APOFF().
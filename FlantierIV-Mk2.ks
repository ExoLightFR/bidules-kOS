function timeToGoodApoapsis { // On pourrait prendre en compte l'accélération pour avoir une bonne estimation ?...
	local t is 0.
	local d is 105000 - ship:apoapsis. // à changer pour la valeur globale de ll'alt donnée par l'user
	local v is ship:velocity:orbit:mag.
	SET t TO ROUND (d / v).

	pushMasterStatus("Good Apoapsis in " + t + "s.").
}

function doSafeStage {
	parameter mute is False.
	parameter str is "default".
	IF NOT (defined stageCount) {
		global stageCount is 0.
	}
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

function jettisonCoiffe {
	pushMasterStatus("Fairing jettison sequence initiated.").
	pushMessage("Waiting for atmosphere exit.").
	pushMessage("Atmosphere limit is " + body:atm:height / 1000 + "Km.").
	WAIT UNTIL ship:altitude > body:atm:height.
	doSafeStage(False, "Staging fairing !").
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

LOCK throttle to 1.

pushMasterStatus("LAUNCH SEQUENCE INITIATED").
WAIT 1.
FROM {local countdown is 5.} UNTIL countdown = 0 STEP {SET countdown to countdown - 1.} DO {
	pushMasterStatus(countdown + "...").
	WAIT 1.
}

doSafeStage(False, "And we have liftoff !").

// GUIDAGE : Exemple donné avec le code
// LOCK targetPitch to 88.963 - 1.03287 * alt:radar^0.409511.

// GUIDAGE : Fonction log
// LOCK targetPitch to -13.3233 * LN(6.03662e-6 * alt:radar).

// GUIDAGE : Fuck it, plagiat time. Merci Reddit.
LOCK targetPitch to 90 * (1 - (altitude / body:atm:height) ^ 0.5).
SET targetDirection to 90.

WAIT UNTIL alt:radar > 50.
pushMessage("Tower cleared.").

LOCK steering to heading(0,90). // Fusée pointe droit vers le haut sans roulis
WAIT UNTIL ship:verticalspeed > 50.
pushMasterStatus("Beginning roll sequence").
LOCK steering to heading(targetDirection, targetPitch).

UNTIL SHIP:APOAPSIS > 100000 { // TODO : En faire un paramètre réglable par l'utilisateur
	IF maxThrust = 0 {
		LOCK throttle to 0.
		pushMasterStatus("maxThrust is 0 !").
		WAIT 1.
		doSafeStage().
		WAIT 1.
		LOCK throttle to 1.
	}
	IF ship:apoapsis > 50000 {
		timeToGoodApoapsis().
	}
}

pushMasterStatus("Apoapsis > 105 Km").

// TODO : en faire une fonction
kuniverse:timewarp:cancelwarp().

LOCK throttle to 0.
// waitAngle("PROGRADE").
LOCK steering to PROGRADE.
WAIT 5.
IF stageCount < 2 {
	doSafeStage().
	LOCK throttle to 0.05.
	WAIT 1.
	LOCK throttle to 0.
}
ELSE {
	pushMessage("First stage already separated.").
	pushMessage("Will not stage.").
}

jettisonCoiffe().

orbitNode().

runpath("0:/FlantierIV-Mk2-NodeAP-Unfucked.ks").
executeBurnNodev2().

TOGGLE AG1.
WAIT 1.

runpath("0:/FlantierIV-Mk2-HohmannAP.ks").
hohmannTransfer(110000).

APOFF().

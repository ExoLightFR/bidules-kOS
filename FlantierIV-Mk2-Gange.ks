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

// ==========================================================================================================================================================
// ==========================================================================================================================================================
// ==========================================================================================================================================================
// ==========================================================================================================================================================
// ==========================================================================================================================================================

runpath("0:/FlantierIV-Mk2-UI.ks").

LOCK throttle to 1.

SET northPole TO latlng(90,0).
LOCK hdg TO mod(360 - northPole:bearing,360).

global capLancement is hdg - 90.

//This is our countdown loop, which cycles from 10 to 0
pushMasterStatus("GANGIFICATION ENGAGÉE").
WAIT 1.
FROM {local countdown is 5.} UNTIL countdown = 0 STEP {SET countdown to countdown - 1.} DO {
    pushMasterStatus(countdown + "...").
    WAIT 1. // pauses the script here for 1 second.
}

doSafeStage(False, "Lancement !").

// Fonction de guidage
LOCK targetPitch to 90 * (1 - (altitude / body:atm:height) ^ 0.5).
SET targetDirection to 90.

pushMessage("Cap de lancement : " + ROUND(hdg,1)).
LOCK steering to heading(capLancement,90). // Fusée pointe droit vers le haut sans roulis

// Code pour ICBM plus classique ?
// local fuckyou is False.
// UNTIL fuckyou = True {
// 	LIST engines in myEngines.
// 	FOR en in myEngines {
// 
// 		IF ship:verticalspeed > 30 AND stageCount < 2 {
// 			doSafeStage(False, "Main engine ignition").
// 		}
// 
// 		IF en:flameout {
// 			WAIT 0.2.
// 			SET fuckyou to True.
// 			BREAK.
// 		}
// 	}
// }

local fuckyou is False.
UNTIL fuckyou = True {

	IF NOT (defined initialFuel) {
		global initialFuel IS stage:liquidfuel.
	}

	LIST engines in myEngines.
	FOR en in myEngines {

		//IF ship:verticalspeed > 30 AND stageCount < 2 {
		//	doSafeStage(False, "Main engine ignition").
		//}

		IF stage:liquidfuel <= 5 * initialFuel / 100 AND stageCount < 2 {
			doSafeStage(False, "Main engine ignition").
			pushMessage("Main engine ignition.").
		}

		IF en:flameout {
			WAIT 0.2.
			pushMessage("Booster separation.").
			SET fuckyou to True.
			BREAK.
		}

		IF ship:verticalspeed > 50 {
			pushMasterStatus("Beginning roll sequence").
			LOCK steering to heading(targetDirection, targetPitch).
		}
	}
}

doSafeStage().


UNTIL SHIP:APOAPSIS > 105000 { // TODO : En faire un paramètre réglable par l'utilisateur
	IF maxThrust = 0 {
		LOCK throttle to 0.
		pushMasterStatus("maxThrust is 0 !").
		pushMessage("Staged because of flameout.").
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
IF stageCount < 4 {
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

TOGGLE 1.
WAIT 1.

runPath("0:/FlantierIV-Mk2-HohmannAP.ks").
hohmannTransfer(110000).

APOFF().

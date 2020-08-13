function createTUIMessageBox {
	CLEARSCREEN.
	PRINT "+========================================+".
	PRINT "|                                        |".
	PRINT "+========================================+".
	PRINT "|                                        |".
	PRINT "|                                        |".
	PRINT "|                                        |".
	PRINT "|                                        |".
	PRINT "+----------------------------------------+".
}

// Affiche quelque chose dans la partie supérieure de la TextUserInterface. À utiliser pour infos importantes/statut du vaisseau/manoeuvre en cours.
function pushMasterStatus {
	parameter str.
	parameter line is 1.
	parameter start is 2.

	PRINT "                                       " AT(start, line).
	PRINT str:TOUPPER() AT(start, line). // vérifier que ça marche le TOUPPER quand même
}

// Affiche un message dans la partie inférieur de la TextUserInterface. Et ne marche pas non plus.
function pushMessage {
	parameter str.
	parameter line is 3.
	parameter start is 2.

	IF NOT (defined pushMessageIncr) {
		SET pushMessageIncr to 0. // Est set en global
	}

	IF pushMessageIncr > 3 { // Si la fenêtre Message est pleine, l'effacer et remettre le compteur à zéro
		PRINT "                                       " AT(start, line + 0).
		PRINT "                                       " AT(start, line + 1).
		PRINT "                                       " AT(start, line + 2).
		PRINT "                                       " AT(start, line + 3).
		SET pushMessageIncr to 0.
		}

	SET line to pushMessageIncr + 3. // la ligne à utiliser, incrémente avec le compteur
	SET pushMessageIncr to pushMessageIncr+1. // Incrémentation du compteur

	PRINT str AT(start, line).
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

function APOFF {
	parameter sasM is "PROGRADE".
	UNLOCK steering.
	UNLOCK throttle.
	SAS ON.
	WAIT 0.1. // Obligé d'attendre au moins une frame pour que ça passe en SAS PROGRADE, limitation du jeu
	SET SASMODE to sasM.
	pushMasterStatus("Autopilot OFF. SAS set to " + sasM + ".").
}

// ==========================================================================================================================================
// ==========================================================================================================================================

createTUIMessageBox().

LOCK throttle to 1.

pushMasterStatus("LAUNCH SEQUENCE INITIATED").
WAIT 1.
doSafeStage(False, "And we have liftoff !").

// LOCK targetPitch to 90 * (1 - (altitude / body:atm:height) ^ 0.5).
// SET targetDirection to 90.

WAIT UNTIL alt:radar > 50.
pushMessage("Tower cleared.").

LOCK steering to heading(0,90). // Fusée pointe droit vers le haut sans roulis
WAIT UNTIL ship:verticalspeed > 50.
pushMasterStatus("Beginning roll sequence").
LOCK steering to heading(targetDirection, targetPitch).

UNTIL SHIP:APOAPSIS > 105000 { // TODO : En faire un paramètre réglable par l'utilisateur
	ON eng:Flameout {
		pushMasterStatus("Engine Flameout !").
		pushMessage("Boosters are empty !").
		WAIT 1.
		doSafeStage().
		WAIT 1.
	}
}

pushMasterStatus("Apoapsis > 105 Km").

// TODO : en faire une fonction
kuniverse:timewarp:cancelwarp().

LOCK throttle to 0.
LOCK steering to PROGRADE.

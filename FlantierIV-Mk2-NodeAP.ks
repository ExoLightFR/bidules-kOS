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

function nodeBurnDuration { // Honteusement plagié. Sera peut être utile plus tard.
	parameter mnv.
	local dV is mnv:deltaV:mag.
	local isp is 0.
	local g0 is constant:g0.

	LIST engines in myEngines.
	FOR en in myEngines {
		IF en:ignition and not en:flameout {
			SET isp to isp + (en:isp * (en:availableThrust / ship:availableThrust)).
		}
	}

	local mf is ship:mass / constant:e^(dV / (isp * g0)).
	local fuelFlow is ship:availableThrust / (isp * g0).
	local burnDuration is (ship:mass - mf) / fuelFlow.

	RETURN burnDuration.
}

// function executeBurnNode {
// 	pushMasterStatus("Node execution mode engaged.").
// 	local node is nextnode.
// 	local burnDuration is nodeBurnDuration(node).
// 	local endBurnTime is time:seconds + node:eta + burnDuration/2.
// 	PRINT "EndBurnTime : " + endBurnTime.
// 	PRINT "Time:seconds : " + time:seconds.
// 	PRINT "Node:eta : " + node:eta.
// 	PRINT "burnDuration : " + burnDuration.
// 	WAIT UNTIL node:eta <= (burnDuration/2 + 60).
// 	SET nosePoint to node:burnvector.
// 	LOCK steering to nosePoint.
// 	WAIT UNTIL vang(ship:facing:vector, nosePoint) < 0.25. // TODO : Faire un truc qui abort tout seul la manoeuvre si t'es pas aligné avant le moment de burn
// 	WAIT UNTIL node:eta <= (burnDuration/2).
// 	LOCK throttle to 1.
// 	WAIT UNTIL time:seconds >= endBurnTime.
// 	LOCK throttle to 0.
// }

function executeBurnNodev2 {
	pushMasterStatus("Node execution mode v2 engaged. Prout.").
	local node is nextnode.
	local ThrottSet is 0.
	LOCK throttle to ThrottSet.
	local burnDuration is nodeBurnDuration(node).

	WAIT UNTIL node:eta <= (burnDuration / 2) + 25.
	PRINT ("waited until").
	WAIT 3.
	SAS OFF.
	PRINT ("SAS OFF once").
	WAIT 1.
	SAS OFF.
	PRINT ("SAS OFF twice").
	WAIT 1.
	LOCK steering to node:burnvector.
	WAIT UNTIL vang(ship:facing:vector, node:burnvector) < 0.25. // Attendre d'être aligné avec le burnvector
	WAIT 5.
	local initialBurnVector is node:burnvector. // Pour comparer le vecteur initial avec le vecteur mis à jour dans la boucle
	local startTime is time:seconds + node:eta - burnDuration / 2.
	WAIT UNTIL time:seconds >= startTime.
	PRINT time:seconds.
	PRINT startTime.
	
	local done is False.
	UNTIL done {

		SET burnDuration TO nodeBurnDuration(node). // 
		SET ThrottSet TO min(burnDuration, 1).

			IF vdot(initialBurnVector, node:burnvector) < 0 {
				LOCK throttle to 0.
				BREAK.
			}

			IF node:burnvector:mag < 0.1 {
				WAIT UNTIL vdot(initialBurnVector, node:burnvector) < 0.5.
				LOCK throttle to 0.
				SET done to True.
			}
	}

	LOCK steering to PROGRADE.
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

function APOFF {
	parameter sasM is "PROGRADE".
	UNLOCK steering.
	SET ship:control:pilotmainthrottle to 0.
	UNLOCK throttle.
	SAS ON.
	WAIT 0.1. // Obligé d'attendre au moins une frame pour que ça passe en SAS PROGRADE, limitation du jeu
	SET SASMODE to sasM.
	pushMasterStatus("Autopilot OFF. SAS set to " + sasM + ".").
}

// ==========================================================================================================================================
// ==========================================================================================================================================
// ==========================================================================================================================================
// ==========================================================================================================================================
// ==========================================================================================================================================

createTUIMessageBox().

pushMasterStatus("Node Autopilot Armed").

WAIT UNTIL RCS.
WAIT 0.1.
RCS OFF.

executeBurnNodev2().

// Compte à rebours déco autopilote
FROM {local countdown is 5.} UNTIL countdown = 0 STEP {SET countdown to countdown - 1.} DO {
    pushMasterStatus("Autopilot disconnect in " + countdown).
    WAIT 1. 
}

APOFF().
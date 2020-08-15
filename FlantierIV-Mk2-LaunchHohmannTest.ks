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

function pushMessagev2 {
	parameter str.
	parameter line is 3. // La ligne sur laquelle print, 3 par défaut
	parameter start is 2. // La colonne sur laquelle print, toujours 2 sauf si on veut centrer un message

	IF NOT (defined line1) OR (defined line2) OR (defined line3) OR (defined line4) OR (defined line5) {
		SET line1 to " ".
		SET line2 to " ".
		SET line3 to " ".
		SET line4 to " ".
		SET line5 to False.
	}

	local lineList is LIST(line1, line2, line3, line4, line5).
	


	IF line5 <> False {
		SET line2 to line1.
		SET line3 to line2.
		SET line4 to line3.
		SET line5 to line4.
		SET line5 to False.
	}

	PRINT line1 AT(start, 3).
	PRINT line2 AT(start, 4).
	PRINT line3 AT(start, 5).
	PRINT line4 AT(start, 6).
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

function timeToGoodApoapsis { // On pourrait prendre en compte l'accélération pour avoir une bonne estimation ?...
	local t is 0.
	local d is 105000 - ship:apoapsis. // à changer pour la valeur globale de ll'alt donnée par l'user
	local v is ship:velocity:orbit:mag.
	SET t TO ROUND (d / v).

	pushMasterStatus("Good Apoapsis in " + t + "s.").
}

// Met le vaisseau vers le vecteur demandé. Accessoirement, ne marche pas.
function waitAngle {
	parameter vector.
	LOCK steering to vector.
	WAIT UNTIL vang(ship:facing:forevector, vector) <2.
}

function executeBurnNode {
	pushMasterStatus("Node execution mode engaged.").
	local node is nextnode.
	local burnDuration is nodeBurnDuration(node).
	local endBurnTime is time:seconds + node:eta + burnDuration/2.
	PRINT "EndBurnTime : " + endBurnTime.
	PRINT "Time:seconds : " + time:seconds.
	PRINT "Node:eta : " + node:eta.
	PRINT "burnDuration : " + burnDuration.
	WAIT UNTIL node:eta <= (burnDuration/2 + 60).
	SET nosePoint to node:burnvector.
	LOCK steering to nosePoint.
	WAIT UNTIL vang(ship:facing:vector, nosePoint) < 0.25. // TODO : Faire un truc qui abort tout seul la manoeuvre si t'es pas aligné avant le moment de burn
	WAIT UNTIL node:eta <= (burnDuration/2).
	LOCK throttle to 1.
	WAIT UNTIL time:seconds >= endBurnTime.
	LOCK throttle to 0.
}

function executeBurnNodev2 {
	pushMasterStatus("Node execution mode v2 engaged.").
	local node is nextnode.
	local ThrottSet is 0.
	LOCK throttle to ThrottSet.
	local max_acc is ship:maxthrust/ship:mass.
	local burnDuration is nodeBurnDuration(node).
	// local burnDuration is node:deltav:mag/max_acc.

	WAIT UNTIL node:eta <= (burnDuration / 2 + 20). // 20s avant le début du burn
	kuniverse:timewarp:cancelwarp(). // Stop le timewarp
	LOCK steering to node:burnvector.
	WAIT UNTIL vang(ship:facing:vector, node:burnvector) < 0.25. // Attendre d'être aligné avec le burnvector
	
	local startTime is time:seconds + node:eta - burnDuration / 2.
	WAIT UNTIL time:seconds >= startTime.
	local initialBurnVector is node:burnvector. // Pour comparer le vecteur initial avec le vecteur mis à jour dans la boucle
	PRINT time:seconds.
	PRINT startTime.
	
	local done is False.
	UNTIL done {

		SET max_acc to ship:maxthrust/ship:mass.
		SET burnDuration TO node:deltav:mag/max_acc. // 
		SET ThrottSet TO min(burnDuration, 1).

			IF node:burnvector:mag < 0.1 {
				PRINT "IF burnvector < 0.1 (2)".
				WAIT UNTIL vdot(initialBurnVector, node:burnvector) < 0.
				LOCK throttle to 0.
				SET done to True.
				PRINT "Done True".
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

function orbitNode {
	local currentApVel is (body:mu * ((2 / (apoapsis + body:radius)) - (1 / ((apoapsis + body:radius*2 + periapsis) / 2))))^0.5.

	local neededVel is ((body:mu * (1 / (body:radius + apoapsis))) ^ 0.5) - currentApVel.
	local node is NODE(time:seconds+ETA:apoapsis, 0, 0, neededVel).
	ADD node.
}

function comparaisonPourcent {
	parameter valeurInit.
	parameter valeurFinale.
	local diffPourcent is (valeurFinale - valeurInit) / valeurInit * 100.
	RETURN diffPourcent.
}

function orbitTransfer {
	parameter wantedAlt. // TODO : user input function pour wantedAlt

	local currentA is (body:radius * 2 + apoapsis + periapsis) / 2.
	local currentApVel is (body:mu * ((2 / (body:radius + apoapsis)) - (1 / currentA)))^0.5.
	local currentPeVel is (body:mu * ((2 / (body:radius + periapsis)) - (1 / currentA)))^0.5.
	
	local velOrbitB is ((body:mu * (1 / (body:radius + wantedAlt))) ^ 0.5).

	local transferAp is body:radius + wantedAlt.
	local transferPe is body:radius + periapsis.
	local transferA is (body:radius * 2 + transferAp + transferPe) / 2.

	local transferApVel is (body:mu * ((2 / transferAp) - (1 / transferA)))^0.5.
	local transferPeVel is (body:mu * ((2 / transferPe) - (1 / transferA)))^0.5.

	local deltaV1 is transferPeVel - currentPeVel.

	IF ETA:periapsis < 20 { // Sécurité si la périapse est trop proche
		pushMessage("Periapsis too close, waiting for next orbit").
		local periapsisTime is time:seconds + ETA:periapsis.
		WAIT UNTIL time:seconds > periapsisTime + 2.
		PRINT("Waited until periapis passed").
	}

	local node1 is NODE(time:seconds+ETA:periapsis, 0, 0, deltaV1).
	ADD node1.
	// Idée, mettre les deux nodes en même temps, à la suite ?
	// Faudrait un AP plus précis pour la pratique mais ça permettrait de vérifier la théorie

	executeBurnNodev2().
	WAIT 5.
	REMOVE node1.

	// Actualisation des variables, calcul de l'écart en %
	SET currentA TO (body:radius * 2 + apoapsis + periapsis) / 2.
	SET currentApVel TO (body:mu * ((2 / (body:radius + apoapsis)) - (1 / currentA)))^0.5.
	PRINT("Ecart de vélocité : " + comparaisonPourcent(transferApVel, currentApVel) + "%").
	PRINT("Ecart d'altitude : " + comparaisonPourcent(wantedAlt, apoapsis) + "%").

	local correctedVelOrbitB is (body:mu * (1 / (body:radius + apoapsis))) ^ 0.5.
	local deltaV2 is correctedVelOrbitB - currentApVel.

	local node2 is NODE(time:seconds+ETA:apoapsis, 0, 0, deltaV2).
	ADD node2.

	executeBurnNodev2().
	WAIT 5.
	REMOVE node2.

	// Actualisation des variables, calcul de l'écart en %
	SET currentA TO (body:radius * 2 + apoapsis + periapsis) / 2.
	SET currentPeVel TO (body:mu * ((2 / (body:radius + periapsis)) - (1 / currentA)))^0.5.
	PRINT("Ecart de vélocité : " + comparaisonPourcent(velOrbitB, currentPeVel) + "%").
	PRINT("Ecart d'altitude : " + comparaisonPourcent(wantedAlt, periapsis) + "%").
}

// ==========================================================================================================================================
// ==========================================================================================================================================
// ==========================================================================================================================================
// ==========================================================================================================================================
// ==========================================================================================================================================

createTUIMessageBox().

LOCK throttle to 1.

//This is our countdown loop, which cycles from 10 to 0
pushMasterStatus("LAUNCH SEQUENCE INITIATED").
WAIT 1.
//FROM {local countdown is 5.} UNTIL countdown = 0 STEP {SET countdown to countdown - 1.} DO {
  //  pushMasterStatus(countdown + "...").
   // WAIT 1. // pauses the script here for 1 second.
//}

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


UNTIL SHIP:APOAPSIS > 105000 { // TODO : En faire un paramètre réglable par l'utilisateur
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
	WAIT 2.
	LOCK throttle to 0.
}
ELSE {
	pushMessage("First stage already separated.").
	pushMessage("Will not stage.").
}

jettisonCoiffe().

orbitNode().

executeBurnNodev2().

orbitTransfer(250000).

// Compte à rebours déco autopilote
FROM {local countdown is 5.} UNTIL countdown = 0 STEP {SET countdown to countdown - 1.} DO {
    pushMasterStatus("Autopilot disconnect in " + countdown).
    WAIT 1. 
}

APOFF().

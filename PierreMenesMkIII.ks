// vnjriez bghyire bhgyier hgiuoef hvicxq byuigfb reuy

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

function timeToGoodApoapsis { // On pourrait prendre en compte l'accélération pour avoir une bonne estimation ?...
	local t is 0.
	local d is 105000 - ship:apoapsis. // à changer pour la valeur globale de ll'alt donnée par l'user
	local v is ship:velocity:orbit:mag.
	SET t TO ROUND (d / v).

	pushMasterStatus("Good Apoapsis in " + t + "s.").
}

function executeBurnNodev2 {
	pushMasterStatus("Node execution mode v2 engaged.").
	local node is nextnode.
	local ThrottSet is 0.
	LOCK throttle to ThrottSet.
	local burnDuration is nodeBurnDuration(node).

	APOFF("Maneuver").

	WAIT UNTIL node:eta <= (burnDuration / 2) + 25.
	WAIT 3.
	SAS OFF.
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

		SET oldThrust to ship:availableThrust.
		SET burnDuration TO nodeBurnDuration(node). // 
		SET ThrottSet TO min(burnDuration, 1).

			IF ship:availablethrust < (oldThrust - 10) {
   			doSafeStage().
  			SET oldThrust TO ship:availablethrust.
  			}

			IF node:burnvector:mag < 0.1 {
				WAIT UNTIL vdot(initialBurnVector, node:burnvector) < 0.
				// WAIT UNTIL vang(initialBurnVector, node:burnvector) > 5.
				pushMessage("Pls work vang").
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

function APOFF {
	parameter sasM is "PROGRADE".
	UNLOCK steering.
	UNLOCK throttle.
	SAS ON.
	WAIT 1. // Obligé d'attendre au moins une frame pour que ça passe en SAS PROGRADE, limitation du jeu
	SET SASMODE to sasM.
	pushMasterStatus("Autopilot OFF. SAS set to " + sasM + ".").
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
// ==========================================================================================================================================================
// ==========================================================================================================================================================

createTUIMessageBox().

// Equation pour gravity turn
// LOCK targetPitch to 90 * (1 - (altitude / body:atm:height) ^ 0.5).
LOCK targetPitch TO (90-((90/100)*((SHIP:APOAPSIS/AltTo0)*100))).
SET targetDirection to 90.

LOCK throttle to 1.

WAIT 1.
FROM {local countdown is 3.} UNTIL countdown = 0 STEP {SET countdown to countdown - 1.} DO {
    pushMasterStatus(countdown + "...").
    WAIT 1. // pauses the script here for 1 second.
}

doSafeStage(False, "Allumage !").

WAIT UNTIL ship:verticalspeed > 50.
pushMasterStatus("Beginning roll sequence").
LOCK steering to heading(targetDirection, targetPitch).

SET oldThrust to ship:availableThrust.

SET AltTo0 TO 65000. //THE ALTITUDE YOU WANT THE ROCKET TO BE FULLY HORIZONTAL
SET targetAp TO 100000. //THE FINAL APOAPSIS YOU WANT TO REACH

UNTIL SHIP:APOAPSIS > 105000 { // TODO : En faire un paramètre réglable par l'utilisateur

	IF ship:availablethrust < (oldThrust - 10) {
    doSafeStage().
    SET oldThrust TO ship:availablethrust.
  	}

  	IF ship:apoapsis > 65000 {
  		SET targetPitch TO 0.
  	}

	IF ship:apoapsis > 50000 {
		timeToGoodApoapsis().
	}
}

pushMasterStatus("Apoapsis reached").

orbitNode().

executeBurnNodev2().

APOFF().
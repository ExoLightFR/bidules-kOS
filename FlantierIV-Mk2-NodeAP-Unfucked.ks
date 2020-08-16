// Piqué sur le net. Met le vaisseau vers le vecteur demandé. Accessoirement, ne marche pas. À garder pour plus tard.
function waitAngle {
	parameter vector.
	LOCK steering to vector.
	WAIT UNTIL vang(ship:facing:forevector, vector) <2.
}

function nodeBurnDuration { // Honteusement plagié. Sera peut être utile plus tard.
	parameter mnv.
	local dV is mnv:deltaV:mag.
	local isp is 0.
	local g0 is constant:g0.

	// TODO : meilleur calcul de l'ISP :
	// sum the mass flow and thrust for all engines
	// then calculate the ISP from the total thrust and mass flow
	LIST engines in myEngines.
	FOR en in myEngines {
		IF en:ignition and not en:flameout {
			SET isp to en:isp.
		}
	}

	local mf is ship:mass / constant:e^(dV / (isp * g0)).
	local fuelFlow is ship:availableThrust / (isp * g0).
	local burnDuration is (ship:mass - mf) / fuelFlow.

	RETURN burnDuration.
}

function executeBurnNodev2 {
	pushMasterStatus("Node execution mode v2.3 engaged.").
	local node is nextnode.
	local ThrottSet is 0.
	LOCK throttle to ThrottSet.
	local burnDuration is nodeBurnDuration(node).

	WAIT UNTIL node:eta <= (burnDuration / 2) + 30.
	WAIT 1.
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

		SET burnDuration TO nodeBurnDuration(node). // 
		SET ThrottSet TO min(burnDuration, 1).

			// TODO : autre moyen de finir le burn pour éviter des délais causés par une boucle ??
			IF node:burnvector:mag < 0.1 {
				WAIT UNTIL vdot(initialBurnVector, node:burnvector) < 0.
				// WAIT UNTIL vang(initialBurnVector, node:burnvector) > 5.
				LOCK throttle to 0.
				SET done to True.
			}
	}

	LOCK steering to PROGRADE.
	WAIT 5.
	REMOVE node.
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
	parameter countdown is 5.

	IF countdown > 0 {
		FROM {local i is countdown.} UNTIL i = 0 STEP {SET i to i-1.} DO {
			pushMasterStatus("Autopilot disconnect in " + i).
			WAIT 1.
		}
	}

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

runpath("0:/FlantierIV-Mk2-UI.ks").
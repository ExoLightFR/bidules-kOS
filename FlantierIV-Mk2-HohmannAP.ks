function comparaisonPourcent {
	parameter valeurInit.
	parameter valeurFinale.
	local diffPourcent is (valeurFinale - valeurInit) / valeurInit * 100.
	RETURN diffPourcent.
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

function hohmannTransfer {
	parameter wantedAlt is 250000. // TODO : user input function pour wantedAlt

	pushMasterStatus("Hohmann orbit transfer AP v0.2").

	local currentA is (body:radius * 2 + apoapsis + periapsis) / 2.
	local currentApVel is (body:mu * ((2 / (body:radius + apoapsis)) - (1 / currentA)))^0.5.
	local currentPeVel is (body:mu * ((2 / (body:radius + periapsis)) - (1 / currentA)))^0.5.
	
	local velOrbitB is ((body:mu * (1 / (body:radius + wantedAlt))) ^ 0.5).

	local transferAp is body:radius + wantedAlt.
	local transferPe is body:radius + periapsis.
	local transferA is (transferAp + transferPe) / 2.

	local transferApVel is (body:mu * ((2 / transferAp) - (1 / transferA)))^0.5.
	local transferPeVel is (body:mu * ((2 / transferPe) - (1 / transferA)))^0.5.

	local deltaV1 is transferPeVel - currentPeVel.

	IF ETA:periapsis < 20 { // Sécurité si la périapse est trop proche
		pushMessage("Periapsis too close, waiting for next orbit").
		local periapsisTime is time:seconds + ETA:periapsis.
		WAIT UNTIL time:seconds > periapsisTime + 2.
		pushMessage("Waited until periapis passed").
	}

	local node1 is NODE(time:seconds+ETA:periapsis, 0, 0, deltaV1).
	ADD node1.

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

runpath("0:/FlantierIV-Mk2-UI.ks").
runpath("0:/FlantierIV-Mk2-NodeAP-Unfucked.ks").
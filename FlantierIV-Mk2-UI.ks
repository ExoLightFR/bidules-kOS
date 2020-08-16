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

// function pushMessagev2 {
// 	parameter str.
// 	parameter line is 3. // La ligne sur laquelle print, 3 par défaut
// 	parameter start is 2. // La colonne sur laquelle print, toujours 2 sauf si on veut centrer un message

// 	IF NOT (defined line1) OR (defined line2) OR (defined line3) OR (defined line4) OR (defined line5) {
// 		SET line1 to " ".
// 		SET line2 to " ".
// 		SET line3 to " ".
// 		SET line4 to " ".
// 		SET line5 to False.
// 	}

// 	local lineList is LIST(line1, line2, line3, line4, line5).
	


// 	IF line5 <> False {
// 		SET line2 to line1.
// 		SET line3 to line2.
// 		SET line4 to line3.
// 		SET line5 to line4.
// 		SET line5 to False.
// 	}

// 	PRINT line1 AT(start, 3).
// 	PRINT line2 AT(start, 4).
// 	PRINT line3 AT(start, 5).
// 	PRINT line4 AT(start, 6).
// }

// ==========================================================================================================================================
// ==========================================================================================================================================
// ==========================================================================================================================================
// ==========================================================================================================================================
// ==========================================================================================================================================

createTUIMessageBox().
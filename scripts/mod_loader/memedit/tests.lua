
modApi.events.onTestsuitesCreated:subscribe(function()
	Testsuites.memedit_board = require("scripts/mod_loader/tests/memedit_board")
	Testsuites.memedit_pawn = require("scripts/mod_loader/tests/memedit_pawn")
end)

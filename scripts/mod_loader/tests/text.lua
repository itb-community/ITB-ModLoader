local testsuite = Tests.Testsuite()
testsuite.name = "Texts and localization"

-- ///////////////////////////////////////////////////////////////
testsuite.testsuite_GlobalTexts = Tests.Testsuite()
testsuite.testsuite_GlobalTexts.name = "GlobalTexts"

function testsuite.testsuite_GlobalTexts.test_NonExistingKey()
	-- Prepare
	local key = "TEST_ENTRY"

	-- Execute
	Global_Texts[key] = "Test text"
	local result = GetText(key)

	-- Cleanup
	Global_Texts[key] = nil
	modApi:setText(key, nil)

	-- Check
	Assert.Equals("Test text", result)

	return true
end

function testsuite.testsuite_GlobalTexts.test_ExistingKey()
	-- Prepare
	local key = "TEST_ENTRY"
	local key2 = "TEST_ENTRY_2"
	modApi:setText(key2, "Test text")

	-- Execute
	Global_Texts[key] = key2
	local result = GetText(key)

	-- Cleanup
	Global_Texts[key] = nil
	modApi:setText(key, nil)
	modApi:setText(key2, nil)

	-- Check
	Assert.Equals("Test text", result)

	return true
end

-- ///////////////////////////////////////////////////////////////
testsuite.testsuite_modApiTexts = Tests.Testsuite()
testsuite.testsuite_modApiTexts.name = "modApi.texts"

function testsuite.testsuite_modApiTexts.test_NonExistingKey()
	-- Prepare
	local key = "TEST_ENTRY"

	-- Execute
	modApi.texts[key] = "Test text"
	local result = GetText(key)

	-- Cleanup
	modApi:setText(key, nil)

	-- Check
	Assert.Equals("Test text", result)

	return true
end

function testsuite.testsuite_modApiTexts.test_ExistingKey()
	-- Prepare
	local key = "TEST_ENTRY"
	local key2 = "TEST_ENTRY_2"
	modApi:setText(key2, "Test text")

	-- Execute
	modApi.texts[key] = key2
	local result = GetText(key)

	-- Cleanup
	modApi:setText(key, nil)

	-- Check
	Assert.Equals("Test text", result)

	return true
end

-- ///////////////////////////////////////////////////////////////
testsuite.testsuite_TileTooltips = Tests.Testsuite()
testsuite.testsuite_TileTooltips.name = "Tile tooltips"

function testsuite.testsuite_TileTooltips.test_Legacy_NonExistingKey()
	-- Prepare
	local key = "TEST_ENTRY"
	local tileTooltip = {
		"Test title",
		"Test text"
	}

	-- Execute
	TILE_TOOLTIPS[key] = tileTooltip
	local result = GetTileTooltip(key)

	-- Cleanup
	TILE_TOOLTIPS[key] = nil

	-- Check
	Assert.True(result ~= nil)
	Assert.Equals(tileTooltip[1], result[1])
	Assert.Equals(tileTooltip[2], result[2])

	return true
end

function testsuite.testsuite_TileTooltips.test_Legacy_ExistingKey()
	-- Prepare
	local key = "TEST_ENTRY"
	local keyTitle = "TEST_ENTRY_TITLE"
	local keyText = "TEST_ENTRY_KEY"

	local tileTooltip = {
		keyTitle,
		keyText
	}

	modApi:setText(keyTitle, "Test title")
	modApi:setText(keyText, "Test text")

	-- Execute
	TILE_TOOLTIPS[key] = tileTooltip
	local result = GetTileTooltip(key)

	-- Cleanup
	modApi:setText(keyTitle, nil)
	modApi:setText(keyText, nil)
	TILE_TOOLTIPS[key] = nil

	-- Check
	Assert.True(result ~= nil)
	Assert.Equals(tileTooltip[1], result[1])
	Assert.Equals(tileTooltip[2], result[2])

	return true
end

function testsuite.testsuite_TileTooltips.test_Current_NonExistingKey()
	local key = "TEST_ENTRY"

	local result = GetTileTooltip(key)

	Assert.True(result ~= nil)
	Assert.Equals(key, result[1])
	Assert.Equals("NOT FOUND", result[2])

	return true
end

function testsuite.testsuite_TileTooltips.test_Current_ExistingKey()
	-- Prepare
	local key = "TEST_ENTRY"
	local keyTitle = "Tile_"..key.."_Title"
	local keyText = "Tile_"..key.."_Text"

	modApi:setText(keyTitle, "Test title")
	modApi:setText(keyText, "Test text")

	-- Execute
	local result = GetTileTooltip(key)
	local resultTitle = GetText(result[1])
	local resultText = GetText(result[2])

	-- Cleanup
	modApi:setText(keyTitle, nil)
	modApi:setText(keyText, nil)

	-- Check
	Assert.True(result ~= nil)
	Assert.Equals(keyTitle, result[1])
	Assert.Equals(keyText, result[2])
	Assert.Equals("Test title", resultTitle)
	Assert.Equals("Test text", resultText)

	return true
end

-- ///////////////////////////////////////////////////////////////
testsuite.testsuite_StatusTooltips = Tests.Testsuite()
testsuite.testsuite_StatusTooltips.name = "Status tooltips"

function testsuite.testsuite_StatusTooltips.test_Legacy_NonExistingKey()
	-- Prepare
	local key = "TEST_ENTRY"
	local tileTooltip = {
		"Test title",
		"Test text"
	}

	-- Execute
	STATUS_TOOLTIPS[key] = tileTooltip
	local result = GetStatusTooltip(key)

	-- Cleanup
	STATUS_TOOLTIPS[key] = nil

	-- Check
	Assert.True(result ~= nil)
	Assert.Equals(tileTooltip[1], result[1])
	Assert.Equals(tileTooltip[2], result[2])

	return true
end

function testsuite.testsuite_StatusTooltips.test_Legacy_ExistingKey()
	-- Prepare
	local key = "TEST_ENTRY"
	local keyTitle = "TEST_ENTRY_TITLE"
	local keyText = "TEST_ENTRY_KEY"

	local tileTooltip = {
		keyTitle,
		keyText
	}

	modApi:setText(keyTitle, "Test title")
	modApi:setText(keyText, "Test text")

	-- Execute
	STATUS_TOOLTIPS[key] = tileTooltip
	local result = GetStatusTooltip(key)

	-- Cleanup
	modApi:setText(keyTitle, nil)
	modApi:setText(keyText, nil)
	STATUS_TOOLTIPS[key] = nil

	-- Check
	Assert.True(result ~= nil)
	Assert.Equals(tileTooltip[1], result[1])
	Assert.Equals(tileTooltip[2], result[2])

	return true
end

function testsuite.testsuite_StatusTooltips.test_Current_NonExistingKey()
	local key = "TEST_ENTRY"

	local result = GetStatusTooltip(key)

	Assert.True(result ~= nil)
	Assert.Equals(key, result[1])
	Assert.Equals("no text found", result[2])

	return true
end

function testsuite.testsuite_StatusTooltips.test_Current_ExistingKey()
	-- Prepare
	local key = "TEST_ENTRY"
	local keyTitle = "Status_"..key.."_Title"
	local keyText = "Status_"..key.."_Text"

	modApi:setText(keyTitle, "Test title")
	modApi:setText(keyText, "Test text")

	-- Execute
	local result = GetStatusTooltip(key)
	local resultTitle = GetText(result[1])
	local resultText = GetText(result[2])

	-- Cleanup
	modApi:setText(keyTitle, nil)
	modApi:setText(keyText, nil)

	-- Check
	Assert.True(result ~= nil)
	Assert.Equals(keyTitle, result[1])
	Assert.Equals(keyText, result[2])
	Assert.Equals("Test title", resultTitle)
	Assert.Equals("Test text", resultText)

	return true
end

return testsuite

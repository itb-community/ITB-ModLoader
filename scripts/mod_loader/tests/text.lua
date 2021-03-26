local testsuite = Tests.Testsuite()

local assertTrue = Tests.AssertTrue
local assertEquals = Tests.AssertEquals

function testsuite.test_GlobalTexts_NonExistingKey()
	-- Prepare
	local key = "TEST_ENTRY"

	-- Execute
	Global_Texts[key] = "Test text"
	local result = GetText(key)

	-- Cleanup
	Global_Texts[key] = nil
	modApi:setText(key, nil)

	-- Check
	assertEquals("Test text", result)

	return true
end

function testsuite.test_GlobalTexts_ExistingKey()
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
	assertEquals("Test text", result)

	return true
end

function testsuite.test_modApiTexts_NonExistingKey()
	-- Prepare
	local key = "TEST_ENTRY"

	-- Execute
	modApi.texts[key] = "Test text"
	local result = GetText(key)

	-- Cleanup
	modApi:setText(key, nil)

	-- Check
	assertEquals("Test text", result)

	return true
end

function testsuite.test_modApiTexts_ExistingKey()
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
	assertEquals("Test text", result)

	return true
end

function testsuite.test_TileTooltips_Old_NonExistingKey()
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
	assertTrue(result ~= nil)
	assertEquals(tileTooltip[1], result[1])
	assertEquals(tileTooltip[2], result[2])

	return true
end

function testsuite.test_TileTooltips_Old_ExistingKey()
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
	assertTrue(result ~= nil)
	assertEquals(tileTooltip[1], result[1])
	assertEquals(tileTooltip[2], result[2])

	return true
end

function testsuite.test_StatusTooltips_Old_NonExistingKey()
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
	assertTrue(result ~= nil)
	assertEquals(tileTooltip[1], result[1])
	assertEquals(tileTooltip[2], result[2])

	return true
end

function testsuite.test_StatusTooltips_Old_ExistingKey()
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
	assertTrue(result ~= nil)
	assertEquals(tileTooltip[1], result[1])
	assertEquals(tileTooltip[2], result[2])

	return true
end

function testsuite.test_TileTooltip_New_NonExistingKey()
	local key = "TEST_ENTRY"

	local result = GetTileTooltip(key)

	assertTrue(result ~= nil)
	assertEquals(key, result[1])
	assertEquals("NOT FOUND", result[2])

	return true
end

function testsuite.test_TileTooltip_New_ExistingKey()
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
	assertTrue(result ~= nil)
	assertEquals(keyTitle, result[1])
	assertEquals(keyText, result[2])
	assertEquals("Test title", resultTitle)
	assertEquals("Test text", resultText)

	return true
end

function testsuite.test_StatusTooltip_New_NonExistingKey()
	local key = "TEST_ENTRY"

	local result = GetStatusTooltip(key)

	assertTrue(result ~= nil)
	assertEquals(key, result[1])
	assertEquals("NOT FOUND", result[2])

	return true
end

function testsuite.test_StatusTooltip_New_ExistingKey()
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
	assertTrue(result ~= nil)
	assertEquals(keyTitle, result[1])
	assertEquals(keyText, result[2])
	assertEquals("Test title", resultTitle)
	assertEquals("Test text", resultText)

	return true
end

return testsuite

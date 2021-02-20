-- Translate attempts to use old signatures of these functions

local newBuildSimpleDialog = sdlext.buildSimpleDialog
function sdlext.buildSimpleDialog(title, options, compatArg1)
	if type(options) == "number" or type(compatArg1) == "number" then
		local w = options
		local h = compatArg1
		options = {
			maxW = w,
			maxH = h
		}
	end

	return newBuildSimpleDialog(title, options)
end

local newBuildTextDialog = sdlext.buildTextDialog
function sdlext.buildTextDialog(title, text, options, compatArg1)
	if type(options) == "number" or type(compatArg1) == "number" then
		local w = options
		local h = compatArg1
		options = {
			maxW = w,
			maxH = h
		}
	end

	return newBuildTextDialog(title, text, options)
end

local newBuildButtonDialog = sdlext.buildButtonDialog
function sdlext.buildButtonDialog(title, contentBuilderFn, buttonsBuilderFn, options, compatArg)
	if type(contentBuilderFn) == "number" or type(buttonsBuilderFn) == "number" then
		local w = contentBuilderFn
		local h = buttonsBuilderFn
		contentBuilderFn = options
		buttonsBuilderFn = compatArg
		options = {
			maxW = w,
			maxH = h,
			compactH = false
		}
		compatArg = nil
	end

	return newBuildButtonDialog(title, contentBuilderFn, buttonsBuilderFn, options)
end

local newShowTextDialog = sdlext.showTextDialog
function sdlext.showTextDialog(title, text, options, compatArg1)
	if type(options) == "number" or type(compatArg1) == "number" then
		local w = options
		local h = compatArg1
		options = {
			maxW = w,
			maxH = h
		}
	end

	return newShowTextDialog(title, text, options)
end

local newShowButtonDialog = sdlext.showButtonDialog
function sdlext.showButtonDialog(title, text, responseFn, buttons, tooltips, compatArg1, compatArg2, options)
	if buttons == nil or type(buttons) == "number" or type(tooltips) == "number" then
		local w = buttons
		local h = tooltips
		buttons = compatArg1
		tooltips = compatArg2
		options = {
			maxW = w,
			maxH = h
		}
	end

	return newShowButtonDialog(title, text, responseFn, buttons, tooltips, options)
end

local newShowAlertDialog = sdlext.showAlertDialog
function sdlext.showAlertDialog(title, text, responseFn, options, compatArg1, ...)
	local buttons = {...}
	if type(options) == "number" or type(compatArg1) == "number" or compatArg1 == nil then
		local w = options
		local h = compatArg1
		options = {
			maxW = w,
			maxH = h
		}
	else
		buttons = {compatArg1, ...}
	end

	return newShowAlertDialog(title, text, responseFn, options, buttons)
end

local newShowInfoDialog = sdlext.showInfoDialog
function sdlext.showInfoDialog(title, text, responseFn, options, compatArg1)
	if type(options) == "number" or type(compatArg1) == "number" then
		local w = options
		local h = compatArg1
		options = {
			maxW = w,
			maxH = h
		}
	end

	return newShowInfoDialog(title, text, responseFn, options)
end

local newShowConfirmDialog = sdlext.showConfirmDialog
function sdlext.showConfirmDialog(title, text, responseFn, options, compatArg1)
	if type(options) == "number" or type(compatArg1) == "number" then
		local w = options
		local h = compatArg1
		options = {
			maxW = w,
			maxH = h
		}
	end

	return newShowConfirmDialog(title, text, responseFn, options)
end

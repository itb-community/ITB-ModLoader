
GameState = GameState or {}

function GameState.IsMainMenu()
	return CUtils.IsMainMenu()
end

function GameState.IsHangar()
	return CUtils.IsHangar()
end

function GameState.IsRegion()
	return CUtils.IsRegion()
end

function GameState.IsMission()
	return CUtils.IsMission()
end

function GameState.IsTransition()
	return CUtils.IsTransition()
end

function GameState.IsEnteringHangar()
	return CUtils.IsHangar() and CUtils.IsTransition() and not CUtils.IsLeavingHangar()
end

function GameState.IsLeavingHangar()
	return CUtils.IsLeavingHangar()
end

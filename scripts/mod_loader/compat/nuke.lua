
-- nuke libraries that have been migrated to the mod loader

mt_redirect = {
	__index = function(self, key)
		local redirect = self.redirects[key]

		if redirect then
			return redirect()
		end
	end
}

SquadEvents = { version = tostring(INT_MAX) }
DifficultyEvents = { version = tostring(INT_MAX) }

modApi.events.onRealDifficultyChanged = modApi.events.onDifficultyChanged

DetectDeployment = { version = tostring(INT_MAX),
	events = {
		redirects = {
			onDeploymentPhaseStart = function() return modApi.events.onDeploymentPhaseStart end,
			onLandingPhaseStart = function() return modApi.events.onLandingPhaseStart end,
			onDeploymentPhaseEnd = function() return modApi.events.onDeploymentPhaseEnd end,
			onPawnUnselected = function() return modApi.events.onPawnUnselectedForDeployment end,
			onPawnSelected = function() return modApi.events.onPawnSelectedForDeployment end,
			onPawnDeployed = function() return modApi.events.onPawnDeployed end,
			onPawnUndeployed = function() return modApi.events.onPawnUndeployed end,
			onPawnLanding = function() return modApi.events.onPawnLanding end,
			onPawnLanded = function() return modApi.events.onPawnLanded end,
		}
	},
	redirects = {
		isDeploymentPhase = function() return modApi.deployment.isDeploymentPhase end,
		isLandingPhase = function() return modApi.deployment.isLandingPhase end,
		getSelected = function() return modApi.deployment.getSelected end,
		getDeployed = function() return modApi.deployment.getDeployed end,
		getRemaining = function() return modApi.deployment.getRemaining end,
	}
}
setmetatable(DetectDeployment, mt_redirect)
setmetatable(DetectDeployment.events, mt_redirect)

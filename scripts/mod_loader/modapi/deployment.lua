
local STATE_SELECTED = 0
local STATE_REMAINING = 1
local STATE_DEPLOYED = 2
local STATE_LANDING = 3
local STATE_LANDED = 4
local PHASE_DEPLOYMENT = 0
local PHASE_LANDING = 1
local PHASE_LANDED = 2
local OUT_OF_BOUNDS = Point(-1,-1)

-- reusable tables
local prev = {
	[0] = {},
	[1] = {},
	[2] = {},
}
local mechs = {
	[0] = {},
	[1] = {},
	[2] = {},
}

local function getDeploymentData(mission)
	return mission.deployment or {}
end


modApi.deployment = {}

local function isValidDeployment(p)
	local terrain = Board:GetTerrain(p)

	return true
		and terrain ~= TERRAIN_MOUNTAIN
		and terrain ~= TERRAIN_BUILDING
		and not Board:IsPod(p)
		and not Board:IsDangerous(p)
		and not Board:IsDangerousItem(p)
		and not Board:IsSpawning(p)
		and not Board:IsAcid(p)
		-- should check if tile has been spawn blocked,
		-- but the information is not readily available
end

-- returns the deployment zone.
function modApi.deployment.getDeploymentZone()
	Assert.True(Board ~= nil, "Board does not exist")

	local deploymentZone = extract_table(Board:GetZone("deployment"))

	if #deploymentZone == 0 then
		for x = 1, 3 do
			for y = 1, 6 do
				local curr = Point(x, y)

				if isValidDeployment(curr) then
					table.insert(deploymentZone, curr)
				end
			end
		end
	end

	return deploymentZone
end

function modApi.deployment.isDeploymentPhase(self)
	local mission = GetCurrentMission()
	if mission == nil then return false end

	return getDeploymentData(mission).in_progress == true
end

function modApi.deployment.isLandingPhase(self)
	local mission = GetCurrentMission()
	if mission == nil then return false end

	return getDeploymentData(mission).phase == PHASE_LANDING
end

function modApi.deployment.getSelected(self)
	local mission = GetCurrentMission()
	if mission == nil then return nil end

	local deployment = getDeploymentData(mission)

	if deployment.in_progress then
		for pawnId = 0, 2 do
			local mech = deployment[pawnId]
			if mech.state == STATE_SELECTED then
				return pawnId
			end
		end
	end

	return nil
end

function modApi.deployment.getDeployed(self)
	local mission = GetCurrentMission()
	if mission == nil then return {} end

	local deployment = getDeploymentData(mission)
	local deployed = {}

	if deployment.in_progress then
		for pawnId = 0, 2 do
			if deployment[pawnId].state == STATE_DEPLOYED then
				table.insert(deployed, pawnId)
			end
		end
	end

	return deployed
end

function modApi.deployment.getRemaining(self)
	local mission = GetCurrentMission()
	if mission == nil then return {} end

	local deployment = getDeploymentData(mission)
	local remaining = {}

	if deployment.in_progress then
		for pawnId = 0, 2 do
			if deployment[pawnId].state == STATE_REMAINING then
				table.insert(remaining, pawnId)
			end
		end
	end

	return remaining
end


local function updateDeploymentListener(mission)
	local deployment = getDeploymentData(mission)

	if not deployment.in_progress then
		return
	end

	if deployment.phase == PHASE_DEPLOYMENT then
		local pwn0 = Board:GetPawn(0)
		local pwn1 = Board:GetPawn(1)
		local pwn2 = Board:GetPawn(2)

		local prev = prev
		prev[0].state = deployment[0].state
		prev[1].state = deployment[1].state
		prev[2].state = deployment[2].state

		local mechs = mechs
		mechs[0].loc = pwn0:GetSpace()
		mechs[1].loc = pwn1:GetSpace()
		mechs[2].loc = pwn2:GetSpace()
		mechs[0].isSelected = pwn0:IsSelected()
		mechs[1].isSelected = pwn1:IsSelected()
		mechs[2].isSelected = pwn2:IsSelected()

		for pawnId = 0, 2 do
			local mech = mechs[pawnId]
			if mech.isSelected then
				mech.state = STATE_SELECTED
			elseif mech.loc == OUT_OF_BOUNDS then
				mech.state = STATE_REMAINING
			else
				mech.state = STATE_DEPLOYED
			end
		end

		local isNoneSelected = true
			and mechs[0].state ~= STATE_SELECTED
			and mechs[1].state ~= STATE_SELECTED
			and mechs[2].state ~= STATE_SELECTED

		if isNoneSelected then
			for pawnId = 0, 2 do
				local mech = mechs[pawnId]
				if mech.state == STATE_REMAINING then
					mech.state = STATE_SELECTED
					break
				end
			end
		end

		for pawnId = 0, 2 do
			local mech = mechs[pawnId]
			local saved = deployment[pawnId]
			saved.state = mech.state
		end

		for pawnId = 0, 2 do
			local mech = mechs[pawnId]
			local prev = prev[pawnId]
			if mech.state ~= prev.state then
				if prev.state == STATE_DEPLOYED then
					modApi.events.onPawnUndeployed:dispatch(pawnId)
				elseif prev.state == STATE_SELECTED then
					modApi.events.onPawnUnselectedForDeployment:dispatch(pawnId)
				end

				if mech.state == STATE_DEPLOYED then
					modApi.events.onPawnDeployed:dispatch(pawnId)
				elseif mech.state == STATE_SELECTED then
					modApi.events.onPawnSelectedForDeployment:dispatch(pawnId)
				end
			end
		end

		local isAllDeployed = true
			and mechs[0].state == STATE_DEPLOYED
			and mechs[1].state == STATE_DEPLOYED
			and mechs[2].state == STATE_DEPLOYED
			and (pwn0:IsBusy() or pwn1:IsBusy() or pwn2:IsBusy())

		if isAllDeployed then
			deployment.phase = PHASE_LANDING
			modApi.events.onLandingPhaseStart:dispatch()
		end
	end

	if deployment.phase == PHASE_LANDING then
		for pawnId = 0, 2 do
			local mech = deployment[pawnId]
			local pawn = Board:GetPawn(pawnId)

			if mech.state == STATE_DEPLOYED then
				if pawn:IsBusy() then
					mech.state = STATE_LANDING
					modApi.events.onPawnLanding:dispatch(pawnId)
				end

			elseif mech.state == STATE_LANDING then
				if not pawn:IsBusy() then
					mech.state = STATE_LANDED
					modApi.events.onPawnLanded:dispatch(pawnId)
				end
			end
		end

		local isAllLanded = true
			and deployment[0].state == STATE_LANDED
			and deployment[1].state == STATE_LANDED
			and deployment[2].state == STATE_LANDED

		if isAllLanded then
			deployment.in_progress = false
			deployment.phase = PHASE_LANDED
			modApi.events.onDeploymentPhaseEnd:dispatch()
		end
	end
end

local function startDeploymentListener(mission)
	mission.deployment = {
		in_progress = true,
		phase = PHASE_DEPLOYMENT,
		[0] = { state = STATE_REMAINING },
		[1] = { state = STATE_REMAINING },
		[2] = { state = STATE_REMAINING },
	}

	modApi.events.onDeploymentPhaseStart:dispatch()
end

modApi.events.onPawnLanded:subscribe(function(pawnId)
	local pawn = Board:GetPawn(pawnId)
	local pawnType = pawn:GetType()
	local deploySkill = _G[pawnType].DeploySkill

	local isValidDeploySkill = true
		and type(deploySkill) == 'string'
		and type(_G[deploySkill]) == 'table'
		and type(_G[deploySkill].GetSkillEffect) == 'function'

	if isValidDeploySkill then
		local Pawn_bak = Pawn; Pawn = pawn
		local p2 = pawn:GetSpace()
		local fx = _G[deploySkill]:GetSkillEffect(p2, p2)

		for eventIndex = 1, fx.effect:size() do
			local event = fx.effect:index(eventIndex)
			Board:DamageSpace(event)
		end

		Pawn = Pawn_bak
	end
end)

modApi.events.onMissionStart:subscribe(startDeploymentListener)
modApi.events.onMissionUpdate:subscribe(updateDeploymentListener)

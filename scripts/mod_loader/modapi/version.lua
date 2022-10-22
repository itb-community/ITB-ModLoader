
function modApi:isVersion(version,comparedTo)
	assert(type(version) == "string")
	if not comparedTo then
		comparedTo = self.version
	end
	assert(type(comparedTo) == "string")

	local v1 = self:splitString(version,"%D")
	local v2 = self:splitString(comparedTo,"%D")

	for i = 1, math.min(#v1,#v2) do
		local n1 = tonumber(v1[i])
		local n2 = tonumber(v2[i])
		if n1 > n2 then
			return false
		elseif n1 < n2 then
			return true
		end
	end

	return #v1 <= #v2
end

function modApi:isVersionBelowOrEqual(version, targetVersion)
	return self:isVersion(version, targetVersion)
end

function modApi:isVersionAboveOrEqual(version, targetVersion)
	return self:isVersion(targetVersion, version)
end

function modApi:isVersionAbove(version, targetVersion)
	return not self:isVersion(version, targetVersion)
end

function modApi:isVersionBelow(version, targetVersion)
	return not self:isVersion(targetVersion, version)
end

function modApi:isValidVersion(version)
	-- modApi.isVersion only requires "version" to be a string.
	-- if more strict definition is required in the future,
	-- this function can be updated.
	return type(version) == "string"
end

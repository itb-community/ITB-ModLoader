local testsuite = Tests.Testsuite()
testsuite.name = "Script sandbox tests"

function testsuite.test_GlobalTablesChanges_ShouldNotLeak()
	-- Changes to fields of global tables should not leak out to the real environment
	test = {}
	test.a = 5
	test.t = function(self)
		self.a = 7
		_G.test.a = 7
		Assert.Equals(7, test.a)
		Assert.Equals(7, _G.test.a)
	end

	local env, ok, result = modApi:runInEnv("test:t()")

	local _test = test
	test = nil

	Assert.Equals(5, _test.a)
	Assert.Equals(7, env.test.a)

	if ok then
		return true
	end
end

function testsuite.test_GlobalChanges_ShouldNotLeak()
	-- Changes to globals should not leak out to the real environment
	a = 5
	test = function()
		a = 7
		_G.a = 7
	end

	local env, ok, result = modApi:runInEnv("test()")

	local _a = a
	test = nil
	a = nil

	Assert.Equals(5, _a)
	Assert.Equals(7, env.a)

	if ok then
		return true
	end
end

function testsuite.test_UpvalueChanges_ShouldNotLeak()
	-- Changes to upvalues should not leak out into the real environment
	local a = 5

	test = function()
		a = 7
		Assert.Equals(7, a)
	end

	local env, ok, result = modApi:runInEnv("test()")
	
	test = nil

	Assert.Equals(5, a)

	if ok then
		return true
	end
end

function testsuite.test_ShouldReturnMultipleValues()
	-- Functions returning multiple values should have those values properly passed to the caller
	test1 = function()
		return 1, 2, 3
	end

	test = function()
		local a1, a2, a3 = test1()

		Assert.Equals(1, a1)
		Assert.Equals(2, a2)
		Assert.Equals(3, a3)
	end

	local env, ok, result = modApi:runInEnv("test()")

	test1 = nil
	test = nil

	if ok then
		return true
	end
end

function testsuite.test_ShouldRestoreNilUpvalues()
	-- nil upvalues should be restored to nil
	local a = 5
	local b = nil
	test = function()
		a = 7
		b = 8
		Assert.Equals(7, a)
		Assert.Equals(8, b)
	end

	local env, ok, result = modApi:runInEnv("test()")

	test = nil

	Assert.Equals(5, a)
	Assert.Equals(nil, b)

	if ok then
		return true
	end
end

function testsuite.test_ShouldPersistUpvalues_ThroughSameFunctionCalls()
	-- Upvalues should persist through multiple calls to the same function
	local a = 5
	test = function()
		_G.counter = _G.counter + 1
		a = a + 1
		Assert.Equals(_G.counter, a - 5)
	end

	local env = {}
	env.counter = 0
	env, ok, result = modApi:runInEnv("test(); test();", env)

	test = nil

	Assert.Equals(5, a)
	Assert.Equals(2, env.counter)

	if ok then
		return true
	end
end

function testsuite.test_ShouldPersistUpvalues_ThroughDifferentFunctionCalls()
	-- Upvalues should persist through calls to different functions that use them
	local a = 1
	test = function()
		a = a + 1
		Assert.Equals(2, a)
	end
	test2 = function()
		a = a + 1
		Assert.Equals(3, a)
	end

	local env, ok, result = modApi:runInEnv("test(); test2();")

	test = nil
	test2 = nil

	Assert.Equals(1, a)

	if ok then
		return true
	end
end

function testsuite.test_ShouldPersistUpvalues_ThroughDifferentNestedFunctionCalls()
	-- Upvalues should persist through nested calls to different functions
	-- Local variables should not leak out
	local a = 1
	test = function()
		a = a + 1
		local b = 2
		test2()
	end
	test2 = function()
		a = a + 1
		local c = 3
		test3()
	end
	test3 = function()
		Assert.Equals(3, a)
		Assert.Equals(nil, b)
		Assert.Equals(nil, c)
	end

	local env, ok, result = modApi:runInEnv("test()")

	test = nil
	test2 = nil
	test3 = nil

	Assert.Equals(1, a)
	Assert.Equals(nil, b)
	Assert.Equals(nil, c)

	if ok then
		return true
	end
end

function testsuite.test_RunInEnv_ShouldWorkWithFunctionReferences()
	-- modApi:runInEnv() should also work with function references
	local a = 1
	local test = function()
		a = a + 1
		Assert.Equals(2, a)
	end

	local env, ok, result = modApi:runInEnv(test)

	Assert.Equals(1, a)

	if ok then
		return true
	end
end

function testsuite.test_ScriptErrors_ShouldNotBreakSandbox()
	-- Scripts that error out should not break the sandbox
	local a = 1
	test = function()
		b = 10
		a = a + 1
		Assert.Equals(1, a, "This assertion is supposed to fail.")
	end

	local env, ok, result = modApi:runInEnv("test()")

	test = nil

	Assert.Equals(1, a)
	Assert.Equals(nil, b)

	-- Expected failure
	if not ok then
		return true
	end
end

function testsuite.test_ShouldPersistUpvalues_ThroughNestedScopes()
	-- Nested upvalues should persist through calls to nested functions defined within the upvalues' scope.
	local test = function()
		local a = 1
		local test2 = function()
			local b = 1
			local test3 = function()
				a = a + 1
				b = b + 1
				Assert.Equals(3, a)
				Assert.Equals(3, b)
			end

			a = a + 1
			b = b + 1

			Assert.Equals(2, a)
			Assert.Equals(2, b)

			test3()
		end

		test2()

		Assert.Equals(3, a)
		Assert.Equals(nil, b)
	end

	local env, ok, result = modApi:runInEnv(test)

	Assert.Equals(nil, a)
	Assert.Equals(nil, b)

	if ok then
		return true
	end
end

return testsuite

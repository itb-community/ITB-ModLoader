local testsuite = Tests.Testsuite()

local assertEquals = Tests.AssertEquals

function testsuite.test_1()
	-- Changes to fields of global tables should not leak out to the real environment
	test = {}
	test.a = 5
	test.t = function(self)
		self.a = 7
		_G.test.a = 7
		assertEquals(7, test.a)
		assertEquals(7, _G.test.a)
	end

	local env, ok, result = modApi:runInEnv("test:t()")

	local _test = test
	test = nil

	assertEquals(5, _test.a)
	assertEquals(7, env.test.a)

	if ok then
		LOG("SUCCESS")
		return true
	else
		LOG("FAILURE:", result)
	end
end

function testsuite.test_2()
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

	assertEquals(5, _a)
	assertEquals(7, env.a)

	if ok then
		LOG("SUCCESS")
		return true
	else
		LOG("FAILURE:", result)
	end
end

function testsuite.test_3()
	-- Changes to upvalues should not leak out into the real environment
	local a = 5

	test = function()
		a = 7
		assertEquals(7, a)
	end

	local env, ok, result = modApi:runInEnv("test()")
	
	test = nil

	assertEquals(5, a)

	if ok then
		LOG("SUCCESS")
		return true
	else
		LOG("FAILURE:", result)
	end
end

function testsuite.test_4()
	-- Functions returning multiple values should have those values properly passed to the caller
	test1 = function()
		return 1, 2, 3
	end

	test = function()
		local a1, a2, a3 = test1()

		assertEquals(1, a1)
		assertEquals(2, a2)
		assertEquals(3, a3)
	end

	local env, ok, result = modApi:runInEnv("test()")

	test1 = nil
	test = nil

	if ok then
		LOG("SUCCESS")
		return true
	else
		LOG("FAILURE:", result)
	end
end

function testsuite.test_5()
	-- nil upvalues should be restored to nil
	local a = 5
	local b = nil
	test = function()
		a = 7
		b = 8
		assertEquals(7, a)
		assertEquals(8, b)
	end

	local env, ok, result = modApi:runInEnv("test()")

	test = nil

	assertEquals(5, a)
	assertEquals(nil, b)

	if ok then
		LOG("SUCCESS")
		return true
	else
		LOG("FAILURE:", result)
	end
end

function testsuite.test_6()
	-- Upvalues should persist through multiple calls to the same function
	local a = 5
	test = function()
		_G.counter = _G.counter + 1
		a = a + 1
		assertEquals(_G.counter, a - 5)
	end

	local env = {}
	env.counter = 0
	env, ok, result = modApi:runInEnv("test(); test();", env)

	test = nil

	assertEquals(5, a)
	assertEquals(2, env.counter)

	if ok then
		LOG("SUCCESS")
		return true
	else
		LOG("FAILURE:", result)
	end
end

function testsuite.test_7()
	-- Upvalues should persist through calls to different functions that use them
	local a = 1
	test = function()
		a = a + 1
		assertEquals(2, a)
	end
	test2 = function()
		a = a + 1
		assertEquals(3, a)
	end

	local env, ok, result = modApi:runInEnv("test(); test2();")

	test = nil
	test2 = nil

	assertEquals(1, a)

	if ok then
		LOG("SUCCESS")
		return true
	else
		LOG("FAILURE:", result)
	end
end

function testsuite.test_8()
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
		assertEquals(3, a)
		assertEquals(nil, b)
		assertEquals(nil, c)
	end

	local env, ok, result = modApi:runInEnv("test()")

	test = nil
	test2 = nil
	test3 = nil

	assertEquals(1, a)
	assertEquals(nil, b)
	assertEquals(nil, c)

	if ok then
		LOG("SUCCESS")
		return true
	else
		LOG("FAILURE:", result)
	end
end

function testsuite.test_9()
	-- modApi:runInEnv() should also work with function references
	local a = 1
	local test = function()
		a = a + 1
		assertEquals(2, a)
	end

	local env, ok, result = modApi:runInEnv(test)

	assertEquals(1, a)

	if ok then
		LOG("SUCCESS")
		return true
	else
		LOG("FAILURE:", result)
	end
end

function testsuite.test_10()
	-- Scripts that error out should not break the sandbox
	local a = 1
	test = function()
		b = 10
		a = a + 1
		assertEquals(1, a, "This assertion is supposed to fail.")
	end

	local env, ok, result = modApi:runInEnv("test()")

	test = nil

	assertEquals(1, a)
	assertEquals(nil, b)

	-- Expected failure
	if not ok then
		LOG("SUCCESS")
		return true
	else
		LOG("FAILURE")
	end
end

function testsuite.test_11()
	-- Nested upvalues should persist through calls to nested functions defined within the upvalues' scope.
	local test = function()
		local a = 1
		local test2 = function()
			local b = 1
			local test3 = function()
				a = a + 1
				b = b + 1
				assertEquals(3, a)
				assertEquals(3, b)
			end

			a = a + 1
			b = b + 1

			assertEquals(2, a)
			assertEquals(2, b)

			test3()
		end

		test2()

		assertEquals(3, a)
		assertEquals(nil, b)
	end

	local env, ok, result = modApi:runInEnv(test)

	assertEquals(nil, a)
	assertEquals(nil, b)

	if ok then
		LOG("SUCCESS")
		return true
	else
		LOG("FAILURE:", result)
	end
end

return testsuite

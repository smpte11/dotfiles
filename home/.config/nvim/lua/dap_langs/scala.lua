local dap = require("dap")

dap.configurations.scala = {
	{
		type = "scala",
		request = "launch",
		name = "Run or test file",
		metals = { runType = "runOrTestFile" },
	},
	{
		type = "scala",
		request = "launch",
		name = "Test target",
		metals = { runType = "testTarget" },
	},
	{
		type = "scala",
		request = "attach",
		name = "Attach to JVM",
		buildTarget = function()
			return vim.fn.input("Build target: ")
		end,
		hostName = function()
			return vim.fn.input("Host: ", "localhost")
		end,
		port = function()
			return tonumber(vim.fn.input("Port: ", "5005"))
		end,
	},
}

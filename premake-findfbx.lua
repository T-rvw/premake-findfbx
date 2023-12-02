premake.modules.findfbxsdk = {}

local ffs = premake.modules.findfbxsdk
---------------------------------------------------------
-- Module options
--  custom_sdk_directory
--  dump_information
---------------------------------------------------------
ffs.custom_sdk_directory = nil
ffs.dump_information = false

local dumpInfo = function(msg)
	if ffs.dump_information then
		print("[Info][find-fbxsdk] : "..msg)
	end
end

local dumpWarning = function(msg)
	print("[Warning][find-fbxsdk] : "..msg)
end

local dumpError = function(msg)
	print("[Error][find-fbxsdk] : "..msg)
end

ffs.get_sdk_location = function()
	local mapAllSearchPaths = {}
	local tabAllSearchPaths = {}
	local custom_sdk_directory = ffs.custom_sdk_directory
	if custom_sdk_directory ~= nil and os.isdir(custom_sdk_directory) then
		table.insert(tabAllSearchPaths, custom_sdk_directory)
	end
	
	local fbxSDKChildPaths = "/Autodesk/FBX/FBX SDK/*"
	local addToSDKSearchPaths = function(parentDirectory)
		parentDirectory = path.normalize(parentDirectory)
		local versionDirectoryPaths = os.matchdirs(parentDirectory)
		for _, versionDirectory in pairs(versionDirectoryPaths) do
			mapAllSearchPaths[versionDirectory] = versionDirectory
		end
	end
	
	local addEnvPathToSDKSearchPaths = function(env)
		local envPath = os.getenv(env)
		if envPath ~= nil then
			addToSDKSearchPaths(path.normalize(envPath)..fbxSDKChildPaths)
		end
	end
	
	addEnvPathToSDKSearchPaths("ProgramW6432")
	addEnvPathToSDKSearchPaths("PROGRAMFILES")
	addToSDKSearchPaths("/Applications"..fbxSDKChildPaths)
	
	-- filter duplicated path.
	for _, v in pairs(mapAllSearchPaths) do
		if os.isdir(v) then
			table.insert(tabAllSearchPaths, v)
		end
	end
	
	local searchPathCount = #tabAllSearchPaths
	if searchPathCount == 0 then
		dumpWarning("Cannot find a possible fbxsdk path so fbx features will be skiped. Try to use custom_sdk_directory option or install fbxsdk from https://aps.autodesk.com/developer/overview/fbx-sdk .")
		return
	end
	
	local finalSDKPath = nil
	if searchPathCount == 1 then
		finalSDKPath = tabAllSearchPaths[1]
	else
		dumpError("There are multiple fbxsdk directories in different locations or versions.")
		local function sortByYearVersion(a, b)
			local function containsActionName(sdkPath)
				local actionDirectoryPaths = os.matchdirs(sdkPath.."/lib/*")
				for _, actionDirectoryPath in pairs(actionDirectoryPaths) do
					if path.getbasename(actionDirectoryPath) == _ACTION then
						return true
					end
				end
				
				return false
			end
		
			local aContainsAction = containsActionName(a)
			local bContainsAction = containsActionName(b)
			if aContainsAction and bContainsAction then
				-- all contains, select year
				local versionA = path.getbasename(a)
				local versionB = path.getbasename(b)
				return versionA > versionB
			end
			
			local function boolToNumber(value)
			  return value and 1 or 0
			end
			
			return boolToNumber(aContainsAction) > boolToNumber(bContainsAction)
		end
		
		table.sort(tabAllSearchPaths, sortByYearVersion)
		for _, searchPath in ipairs(tabAllSearchPaths) do
			dumpInfo("SearchSDKPath = "..searchPath)
		end
		finalSDKPath = tabAllSearchPaths[1]
	end
	
	dumpInfo("FinalSDKPath = "..finalSDKPath)
	
	return finalSDKPath
end

---------------------------------------------------------
-- Project options
-- 	copy_shared_libs
-- 	static_runtime
---------------------------------------------------------
ffs.project_config = function(options)
	-- Default options
	local copy_shared_libs = true
	local static_runtime = true
	
	if options ~= nil then
		if type(options) ~= "table" then
			dumpError("Input options variable type is not table.")
			return
		end
		
		-- Override default options
		if options.copy_shared_libs ~= nil then
			copy_shared_libs = options.copy_shared_libs
		end
		
		if options.static_runtime ~= nil then
			static_runtime = options.static_runtime
		end
	end

	local finalSDKPath = ffs.get_sdk_location()
	if finalSDKPath == nil then
		dumpError("Cannot find a suitable fbxsdk location.")
		return
	end
	
	local libDiretory = nil
	local actionDirectoryPaths = os.matchdirs(finalSDKPath.."/lib/*")
	for _, actionDirectoryPath in pairs(actionDirectoryPaths) do
		if path.getbasename(actionDirectoryPath) == _ACTION then
			libDiretory = actionDirectoryPath
			break
		end
	end
	
	if libDiretory == nil then
		-- Cannot find a best match path. Get a random one.
		-- TODO : maybe better to limit vs2022 should find vs** series, not to find other build targets.
		for _, actionDirectoryPath in pairs(actionDirectoryPaths) do
			libDiretory = actionDirectoryPath
			break
		end		
	end
	
	-- Include directory
	local finalIncludePath = finalSDKPath.."/include"
	includedirs { finalIncludePath }		
	dumpInfo("FinalIncludePath = "..finalIncludePath)
	
	local finalLibPath = libDiretory.."/%{cfg.architecture}/%{cfg.buildcfg}"
	filter { "architecture:x64" }
		-- Actually cfg.architecture is x86_64 here.
		-- Need to map "x86_64" to "x64". Any suggestions?
		finalLibPath = libDiretory.."/x64/%{cfg.buildcfg}"
	
	libdirs { finalLibPath }
	dumpInfo("FinalLibPath = "..finalLibPath)
	
	local tabLinkLibNames = {}
	if static_runtime then
		table.insert(tabLinkLibNames, "libfbxsdk-mt")
		table.insert(tabLinkLibNames, "libxml2-mt")
		table.insert(tabLinkLibNames, "zlib-mt")
	else
		table.insert(tabLinkLibNames, "libfbxsdk-md")
		table.insert(tabLinkLibNames, "libxml2-md")
		table.insert(tabLinkLibNames, "zlib-md")
	end
	
	links { table.unpack(tabLinkLibNames) }
	for _, linkLibName in ipairs(tabLinkLibNames) do
		dumpInfo("FianlLinkLibName = "..linkLibName)
	end
	
	if copy_shared_libs then
		local finalDllPath = finalLibPath.."/libfbxsdk.*"
		dumpInfo("FinalDllPath = "..finalDllPath)
		
		postbuildmessage("Copying fbxsdk shared lib...")
		local copyCommand = "{COPYFILE} \""..finalDllPath.."\" \"%{cfg.buildtarget.directory}".."libfbxsdk.*\""
		postbuildcommands { copyCommand }
		dumpInfo("FinalPostCommand = "..copyCommand)
	end
end

return ffs
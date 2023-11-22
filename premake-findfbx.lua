premake.modules.findfbxsdk = {}

local ffs = premake.modules.findfbxsdk

-- options
-- copy_shared_libs
-- custom_sdk_directory
-- dump_information
-- static_runtime
ffs.run = function(options)
	-- Default options
	local copy_shared_libs = true
	local custom_sdk_directory = nil
	local dump_information = true
	local static_runtime = true
	
	local dumpInfo = function(msg)
		if dump_information then
			print("[Info][find-fbxsdk] : "..msg)
		end
	end
	
	local dumpError = function(msg)
		print("[Error][find-fbxsdk] : "..msg)
	end		
	
	if options ~= nil then
		if type(options) ~= "table" then
			dumpError("Input options variable type is not table.")
			return
		end
		
		-- Override default options
		if options.copy_shared_libs ~= nil then
			copy_shared_libs = options.copy_shared_libs
		end
		
		if options.custom_sdk_directory ~= nil then
			custom_sdk_directory = options.custom_sdk_directory
		end
		
		if options.dump_information ~= nil then
			dump_information = options.dump_information
		end
		
		if options.static_runtime ~= nil then
			static_runtime = options.static_runtime
		end
	end

	local mapAllSearchPaths = {}
	local tabAllSearchPaths = {}
	if custom_sdk_directory ~= nil then
		table.insert(tabAllSearchPaths, custom_sdk_directory)
	end
	
	local fbxSDKChildPaths = "/Autodesk/FBX/FBX SDK/*"
	local addToSDKSearchPaths = function(parentDirectory)
		parentDirectory = string.gsub(parentDirectory, "\\", "/")
		local versionDirectoryPaths = os.matchdirs(parentDirectory)
		for _, versionDirectory in pairs(versionDirectoryPaths) do
			mapAllSearchPaths[versionDirectory] = versionDirectory
		end
	end
	
	addToSDKSearchPaths(string.gsub(os.getenv("ProgramW6432"), "\\", "/")..fbxSDKChildPaths)
	addToSDKSearchPaths(string.gsub(os.getenv("PROGRAMFILES"), "\\", "/")..fbxSDKChildPaths)
	addToSDKSearchPaths("/Applications"..fbxSDKChildPaths)
	
	-- filter duplicated path.
	for _, v in pairs(mapAllSearchPaths) do
		table.insert(tabAllSearchPaths, v)
	end
	
	local searchPathCount = #tabAllSearchPaths
	if searchPathCount == 0 then
		dumpError("Cannot find a possible fbxsdk path. Try to use custom_sdk_directory option or install fbxsdk from https://aps.autodesk.com/developer/overview/fbx-sdk .")
		return
	end
	
	local function getLastDirectoryName(sdkPath)
		return path.getbasename(sdkPath)
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
					if getLastDirectoryName(actionDirectoryPath) == _ACTION then
						return true
					end
				end
				
				return false
			end
		
			local aContainsAction = containsActionName(a)
			local bContainsAction = containsActionName(b)
			if aContainsAction and bContainsAction then
				-- all contains, select year
				local versionA = getLastDirectoryName(a)
				local versionB = getLastDirectoryName(b)
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
	
	local libDiretory = nil
	local actionDirectoryPaths = os.matchdirs(finalSDKPath.."/lib/*")
	for _, actionDirectoryPath in pairs(actionDirectoryPaths) do
		if getLastDirectoryName(actionDirectoryPath) == _ACTION then
			libDiretory = actionDirectoryPath
			break
		end
	end
	
	if libDiretory == nil then
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
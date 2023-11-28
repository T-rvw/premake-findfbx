## Premake - Find FBX SDK

A premake add-on module helps to find the most suitable fbx sdk location to use.



#### Tested Platforms

* Windows

Other platforms such as Mac, Linux is WIP.



#### Motivation

[Autodesk FBX](https://en.wikipedia.org/wiki/FBX) is an industry standard 3D model file format but [FBX SDK](https://aps.autodesk.com/developer/overview/fbx-sdk) is under a commericial license. Maybe not friendly to integrate sdk  to your project directly.

Parse FBX ASCII file is also a solution to avoid sdk integration, such as [Godot FBX importer](https://godotengine.org/article/fbx-importer-rewritten-for-godot-3-2-4/) and [nem0/OpenFBX](https://github.com/nem0/OpenFBX). But it costs much time and efforts.



#### How to use

* Put this module under [Premake Search Paths](https://premake.github.io/docs/Locating-Scripts/)

* Integrate it in your premake script
  
  ```lua
  find_fbxsdk = require("premake-findfbx")
  ```

* In module scope
  
  ```lua
  -- [Optional] config module options
  find_fbxsdk.custom_sdk_directory = "D:/fbx"
  find_fbxsdk.dump_information = true
  
  -- Check if module can find a valid sdk locatiion
  local sdkLocation = find_fbxsdk.get_sdk_location()
  local isValid = sdkLocation ~= nil and os.isdir(sdkLocation)
  ```

* In project scope
  
  ```lua
  -- Default options
  find_fbxsdk.project_config()
  
  -- With options
  -- find_fbxsdk.config_project({ static_runtime = false })
  ```

Then it will generate includedirs, libdirs, links, postbuildcommands which copy fbxsdk shared libs to your project build target's output directory. 



#### Module Options

* custom_sdk_directory
  * type : string
    * A valid abosulte directory path
  * default : nil
    * Search this path at first if not nil. Fallback to search system installed directories.
* dump_information
  * type : boolean
  * default : true
    * true : Dump useful information such as include directories, link library paths for debug purpose.
    * false : No Dump



#### Project Options

* copy_shared_libs
  * type : boolean
  * default : true
    * true : Copy shared libararies to your project build target's output directory.
    * false : No Copy
* static_runtime
  * type : boolean
  * default : true
    * true : /MT
    * false : /MD

## Premake - Find FBX SDK

A premake add-on module helps to find the most suitable fbx sdk location to use.



#### Tested Platforms

* Windows



#### Motivation

[Autodesk FBX](https://en.wikipedia.org/wiki/FBX) is an industry standard 3D model file format but [FBX SDK](https://aps.autodesk.com/developer/overview/fbx-sdk) is under a commericial license. Maybe not friendly to integrate sdk  to your project directly.

Parse FBX ASCII file is a solution to avoid sdk integration, such as [FBX importer rewritten for Godot 3.2.4 and later (godotengine.org)](https://godotengine.org/article/fbx-importer-rewritten-for-godot-3-2-4/) and [nem0/OpenFBX: Lightweight open source FBX importer (github.com)](https://github.com/nem0/OpenFBX).



#### How to use

* Put this module under [Premake Search Paths](https://premake.github.io/docs/Locating-Scripts/)

* Integrate it in your premake script
  
  ```lua
  find_fbxsdk = require("premake-findfbx")
  ```

* Usages in one line
  
  ```lua
  -- In project scope
  find_fbxsdk.run()
  ```

* Usages with options
  
  ```lua
  -- In project scope
  find_fbxsdk.run({ copy_shared_libs = true, dump_information = true, static_runtime = false })
  ```

Then it will generate includedirs, libdirs, links, postbuildcommands which copy fbxsdk shared libs to your project build target's output directory. 



#### Options

* copy_shared_libs 
  * type : boolean
  * default : true
    * true : Copy shared libararies to your project's location directory
    * false : No Copy
* custom_sdk_directory
  * type : string
  * default : ""
    * Search this path at first. Fallback to search system installed directory.
* dump_information
  * type : boolean
  * default : true
    * true : Dump useful information such as include directories, link library paths for debug purpose
    * false : No Dump
* static_runtime
  * type : boolean
  * default : true
    * true : /MT
    * false : /MD

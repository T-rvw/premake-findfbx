# Premake_FindFBX

A premake plugin helps to find the most suitable fbx sdk location to use.

#### Motivation

FBX is an industry standard 3D model file format but not friendly to integrate to an open source project. So some developers choose to parse FBX ASCII file to get data which is not an easy job, such as [FBX importer rewritten for Godot 3.2.4 and later (godotengine.org)](https://godotengine.org/article/fbx-importer-rewritten-for-godot-3-2-4/) and [nem0/OpenFBX: Lightweight open source FBX importer (github.com)](https://github.com/nem0/OpenFBX).

For people who don't have enough time and efforts to maintain ASCII paring tool, fbx sdk is the best choice. To avoid commercial license issue, we need to have a fbxsdk helper such as vswhere.exe to address msbuild.exe location.

For example, [guillaumeblanc/ozz-animation: Open source c++ skeletal animation library and toolset (github.com)](https://github.com/guillaumeblanc/ozz-animation) has a FindFBX cmake module : [ozz-animation/build-utils/cmake/modules/FindFbx.cmake at master · guillaumeblanc/ozz-animation (github.com)](https://github.com/guillaumeblanc/ozz-animation/blob/master/build-utils/cmake/modules/FindFbx.cmake). It inspires me to write a similar module in premake.

# 



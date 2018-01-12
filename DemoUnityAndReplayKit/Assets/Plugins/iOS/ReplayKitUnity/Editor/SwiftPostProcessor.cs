using UnityEngine;
using UnityEditor;
using UnityEditor.Callbacks;
using UnityEditor.iOS.Xcode;
using System.Collections;
using System.Collections.Generic;
using System.Diagnostics;
using System.IO;
using System.Linq;

/// <summary> 
/// This class is responsible for directing Unity's Xcode build to the bridging-header and Swift exposed Objective-C files that are part of this plugin 
/// Please take special note to the file path created for the SWIFT_OBJC_BRIDGING_HEADER . It must match the path that exists in your Unity project
/// </summary> 

public static class SwiftPostProcessor {
        [PostProcessBuild]
        public static void OnPostProcessBuild(BuildTarget buildTarget, string buildPath) {
            if(buildTarget == BuildTarget.iOS) {

                // We need to tell the Unity build to look at the write build file path and specifically reference the exposed Swift header file for it to work 
                var projPath = buildPath + "/Unity-iPhone.xcodeproj/project.pbxproj";
                var proj = new PBXProject();
                proj.ReadFromFile(projPath);

                var targetGuid = proj.TargetGuidByName(PBXProject.GetUnityTargetName());

                proj.SetBuildProperty(targetGuid, "ENABLE_BITCODE", "NO");

                // This must match the file path of where the bridging header lives in your Unity project 
                proj.SetBuildProperty(targetGuid, "SWIFT_OBJC_BRIDGING_HEADER", "Libraries/Plugins/iOS/ReplayKitUnity/Source/ReplayKitUnityBridge-Bridging-Header.h");

                // We specifically reference the generated Swift to Objective-C header 
                proj.SetBuildProperty(targetGuid, "SWIFT_OBJC_INTERFACE_HEADER_NAME", "ReplayKitUnityBridge-Swift.h");
                proj.AddBuildProperty(targetGuid, "LD_RUNPATH_SEARCH_PATHS", "@executable_path/Frameworks");

                proj.WriteToFile(projPath);
            }
        }
    }


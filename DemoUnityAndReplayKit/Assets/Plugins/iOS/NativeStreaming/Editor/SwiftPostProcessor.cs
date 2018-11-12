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

        // Name of folder (iOS/<folder>) and the file name prefix
        private static string pluginName = "NativeStreaming";

        [PostProcessBuild]
        public static void OnPostProcessBuild(BuildTarget buildTarget, string buildPath) {
            if(buildTarget == BuildTarget.iOS) {

                // We need to tell the Unity build to look at the write build file path and specifically reference the exposed Swift header file for it to work
                var projPath = buildPath + "/Unity-iPhone.xcodeproj/project.pbxproj";
                var proj = new PBXProject();
                proj.ReadFromFile(projPath);

                var targetGuid = proj.TargetGuidByName(PBXProject.GetUnityTargetName());

                proj.SetBuildProperty(targetGuid, "IPHONEOS_DEPLOYMENT_TARGET", "10.3");

                proj.AddBuildProperty(targetGuid, "SWIFT_VERSION", "4.0");

                proj.SetBuildProperty(targetGuid, "ENABLE_BITCODE", "NO");

                // This must match the file path of where the bridging header lives in your Unity project
                proj.SetBuildProperty(targetGuid, "SWIFT_OBJC_BRIDGING_HEADER", "Libraries/Plugins/iOS/"+pluginName+"/Source/"+pluginName+"Bridge-Bridging-Header.h");

                // We specifically reference the generated Swift to Objective-C header
                proj.SetBuildProperty(targetGuid, "SWIFT_OBJC_INTERFACE_HEADER_NAME", pluginName+"Bridge-Swift.h");
                proj.SetBuildProperty(targetGuid, "SWT_OBJC_INTERFACE_HEADER_NAME", pluginName+"Bridge-Swift.h");

                proj.AddBuildProperty(targetGuid, "LD_RUNPATH_SEARCH_PATHS", "@executable_path/Frameworks");


                // Use below code if external frameworks are needed
                // proj.SetBuildProperty(targetGuid, "FRAMEWORK_SEARCH_PATHS", "$(inherited)");
                proj.AddBuildProperty(targetGuid, "FRAMEWORK_SEARCH_PATHS", "$(PROJECT_DIR)/Frameworks");

                proj.WriteToFile(projPath);
            }
        }
    }


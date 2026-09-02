#if UNITY_EDITOR
using System.IO;
using UnityEditor;
using UnityEditor.SceneManagement;
using UnityEngine;

namespace LahnInfection.Editor
{
    [InitializeOnLoad]
    public static class AndroidPrototypeSetup
    {
        private const string ScenePath = "Assets/LahnInfection/Scenes/LahnInfectionPrototype.unity";
        static AndroidPrototypeSetup() => EditorApplication.delayCall += Setup;

        private static void Setup()
        {
            if (!File.Exists(ScenePath))
            {
                Directory.CreateDirectory("Assets/LahnInfection/Scenes");
                var scene = EditorSceneManager.NewScene(NewSceneSetup.EmptyScene, NewSceneMode.Single);
                EditorSceneManager.SaveScene(scene, ScenePath);
            }
            EditorBuildSettings.scenes = new[] { new EditorBuildSettingsScene(ScenePath, true) };
            PlayerSettings.productName = "Lahn-Infection";
            PlayerSettings.companyName = "MatzeOfPlayer Games";
            PlayerSettings.SetApplicationIdentifier(BuildTargetGroup.Android, "de.matzeofplayer.lahninfection");
            PlayerSettings.defaultInterfaceOrientation = UIOrientation.LandscapeLeft;
            PlayerSettings.Android.minSdkVersion = AndroidSdkVersions.AndroidApiLevel26;
            AssetDatabase.SaveAssets();
        }
    }
}
#endif

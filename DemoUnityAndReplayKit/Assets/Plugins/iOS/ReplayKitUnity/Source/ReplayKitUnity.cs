using UnityEngine;
using System.Runtime.InteropServices;


/// <summary>
/// Responsible for communicating with iOS Bridge .mm file
/// </summary>
public class ReplayKitUnity : MonoBehaviour {

    #region Declare external C interface
    #if UNITY_IOS && !UNITY_EDITOR

    [DllImport("__Internal")]
    private static extern void _startStreaming(string key);

    [DllImport("__Internal")]
    private static extern void _stopStreaming();

    [DllImport("__Internal")]
    private static extern bool _isStreaming();

    #endif
    #endregion

    #region Public methods to be used in your Unity project

    public static void StartStreaming(string key) {
        #if UNITY_IOS && !UNITY_EDITOR
        _startStreaming(key);
        #endif
    }

    public static void StopStreaming() {
        #if UNITY_IOS && !UNITY_EDITOR
        _stopStreaming();
        #endif
    }

    ////////////////////////////////////////////////

    public static bool IsStreaming {
        get {
        #if UNITY_IOS && !UNITY_EDITOR
            return _isStreaming();
        #else
            return false;
        #endif
        }
    }

    #endregion

    #region Singleton implementation
    private static ReplayKitUnity _instance;
    public static ReplayKitUnity Instance {
        get {
            if (_instance == null) {
                var obj = new GameObject("ReplayKitUnity");
                Debug.Log("Adding iOS streaming plugin to the scene: " + obj);
                _instance = obj.AddComponent<ReplayKitUnity>();
            }
            return _instance;
        }
    }

    void Awake() {
        if (_instance != null) {
            Destroy(gameObject);
            return;
        }

        DontDestroyOnLoad(gameObject);
    }
    #endregion

    #region Delegates
    // TODO: fix these

    // Subrscribe to this action and return a call back of when the recording starts
    public System.Action onStartStreaming;

    // Subscribe to this action and return a video file path when the recording stops
    public System.Action onStopStreaming;

    public void OnStartStreaming() {
        if (onStartStreaming != null) {
            onStartStreaming.Invoke();
        }
    }

    public void OnStopStreaming() {
        if (onStopStreaming != null) {
            onStopStreaming.Invoke();
        }
    }

    #endregion
}

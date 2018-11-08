using UnityEngine;
using System.Runtime.InteropServices;


/// <summary>
/// Responsible for communicating with iOS Bridge .mm file
/// </summary>
public class ReplayKitUnity : MonoBehaviour {

    #region Declare external C interface
    #if UNITY_IOS && !UNITY_EDITOR

    [DllImport("__Internal")]
    private static extern bool _isStreaming();
    [DllImport("__Internal")]
    private static extern void _startStreaming(string key);
    [DllImport("__Internal")]
    private static extern void _stopStreaming();

    [DllImport("__Internal")]
    private static extern void _switchCamera(bool useFrontCamera);
    [DllImport("__Internal")]
    private static extern bool _isUsingFrontCamera();

    [DllImport("__Internal")]
    private static extern bool _isMicActive();
    [DllImport("__Internal")]
    private static extern void _setMicActive(bool active);

    [DllImport("__Internal")]
    private static extern bool _isCameraActive();
    [DllImport("__Internal")]
    private static extern void _setCameraActive(bool active);

    #endif
    #endregion

    #region Public methods to be used in your Unity project

    public static bool IsStreaming {
        get {
        #if UNITY_IOS && !UNITY_EDITOR
            return _isStreaming();
        #else
            return false;
        #endif
        }
    }
    public static void StartStreaming(string options) {
        #if UNITY_IOS && !UNITY_EDITOR
        _startStreaming(options);
        #endif
    }
    public static void StopStreaming() {
        #if UNITY_IOS && !UNITY_EDITOR
        _stopStreaming();
        #endif
    }

    public static bool IsMicActive {
        get {
        #if UNITY_IOS && !UNITY_EDITOR
            return _isMicActive();
        #else
            return false;
        #endif
        }
    }
    public static void SetMicActive(bool active) {
        #if UNITY_IOS && !UNITY_EDITOR
        _setMicActive(active);
        #endif
    }

    public static bool IsCameraActive {
        get {
        #if UNITY_IOS && !UNITY_EDITOR
            return _isCameraActive();
        #else
            return false;
        #endif
        }
    }
    public static void SetCameraActive(bool active) {
        #if UNITY_IOS && !UNITY_EDITOR
        _setCameraActive(active);
        #endif
    }

    public static bool IsUsingFrontCamera {
        get {
        #if UNITY_IOS && !UNITY_EDITOR
            return _isUsingFrontCamera();
        #else
            return false;
        #endif
        }
    }
    public static void SwitchCamera(bool useFrontCamera) {
        #if UNITY_IOS && !UNITY_EDITOR
        _switchCamera(useFrontCamera);
        #endif
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

    public System.Action onStartStreaming;
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

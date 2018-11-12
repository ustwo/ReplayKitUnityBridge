using UnityEngine;
using System.Runtime.InteropServices;


/// <summary>
/// Responsible for communicating with iOS Bridge .mm file
/// </summary>
public class NativeStreaming : MonoBehaviour {

    private const string GAME_OBJECT_NAME = "NativeStreamingGameObject";

    #if UNITY_IOS && !UNITY_EDITOR

    [DllImport("__Internal")]
    private static extern bool _initialize();

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
    private static extern bool _isFullscreenCamera();
    [DllImport("__Internal")]
    private static extern void _setFullscreenCamera(bool isFullscreen);

    [DllImport("__Internal")]
    private static extern bool _isMicActive();
    [DllImport("__Internal")]
    private static extern void _setMicActive(bool active);

    [DllImport("__Internal")]
    private static extern bool _isCameraActive();
    [DllImport("__Internal")]
    private static extern void _setCameraActive(bool active);


    #endif

    #region Public methods to be used in your Unity project

    public static void Initialize() {
        #if UNITY_IOS && !UNITY_EDITOR
        _initialize();
        #endif
    }

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


    public static bool IsFullscreenCamera {
        get {
        #if UNITY_IOS && !UNITY_EDITOR
            return _isFullscreenCamera();
        #else
            return false;
        #endif
        }
    }
    public static void SetFullscreenCamera(bool isFullscreen) {
        #if UNITY_IOS && !UNITY_EDITOR
        _setFullscreenCamera(isFullscreen);
        #endif
    }

    #endregion

    #region Singleton implementation
    private static NativeStreaming _instance;
    public static NativeStreaming Instance {
        get {
            if (_instance == null) {
                var obj = new GameObject(GAME_OBJECT_NAME);

                Debug.Log("Adding native streaming plugin to new GameObject: " + obj);
                _instance = obj.AddComponent<NativeStreaming>();
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


    // TODO: Move these into a new file

    public System.Action onInitialized;
    public System.Action onStartStreaming;
    public System.Action onStopStreaming;
    public System.Action onTapCameraBubble;
    public System.Action onCameraSwitched;
    public System.Action<bool> onCameraFullscreenToggle;

    public void OnInitialized() {
        Debug.Log(">> Initialized native streaming plugin");
        if (onInitialized != null) {
            onInitialized.Invoke();
        }
    }

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

    public void OnTapCameraBubble() {
        Debug.Log(">> Tapped bubble");
        if (onTapCameraBubble != null) {
            onTapCameraBubble.Invoke();
        }
    }

    public void OnCameraSwitched() {
        Debug.Log(">> OnCameraSwitched");
        if (onCameraSwitched != null) {
            onCameraSwitched.Invoke();
        }
    }

    private void OnCameraFullscreenToggle(string fullscreen) {
        bool isFullscreen = fullscreen == "true";
        Debug.Log($">> native camera is now rendering {(isFullscreen ? "fullscreen" : "in bubble")}");
        if (onCameraFullscreenToggle != null) {
            onCameraFullscreenToggle.Invoke(isFullscreen);
        }
    }
}

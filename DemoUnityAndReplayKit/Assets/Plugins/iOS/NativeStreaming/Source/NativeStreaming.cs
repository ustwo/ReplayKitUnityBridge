using System;
using UnityEngine;
using System.Runtime.InteropServices;


/// <summary>
/// Responsible for communicating with iOS Bridge .mm file
/// </summary>
public class NativeStreaming : MonoBehaviour {

    private const string GAME_OBJECT_NAME = "NativeStreamingGameObject";

    #if UNITY_IOS && !UNITY_EDITOR

    [DllImport("__Internal")]
    private static extern void _initialize();
    [DllImport("__Internal")]
    private static extern void _requestAccessToCameraAndMic();
    [DllImport("__Internal")]
    private static extern void _setupCaptureSession();

    [DllImport("__Internal")]
    private static extern bool _isStreaming();
    [DllImport("__Internal")]
    private static extern bool _startStreaming(string options);
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
    public static void RequestAccessToCameraAndMic() {
        #if UNITY_IOS && !UNITY_EDITOR
        _requestAccessToCameraAndMic();
        #endif
    }
    public static void SetupCaptureSession() {
        #if UNITY_IOS && !UNITY_EDITOR
        _setupCaptureSession();
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
    public static bool StartStreaming(string options) {
        #if UNITY_IOS && !UNITY_EDITOR
            return _startStreaming(options);
        #else
            return false;
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

    public Action<string, bool> onAccessChecked;
    public Action<bool> onCaptureSessionSetup;
    public Action onStartStreaming;
    public Action onStopStreaming;
    public Action onTapCameraBubble;
    public Action onCameraSwitched;
    public Action<bool> onCameraActiveToggle;
    public Action<bool> onCameraFullscreenToggle;
    public Action<Vector2, Vector2> onCameraBubbleMoved;

    // message receivers

    /// message: camera=true
    public void OnAccessChecked(string message) {
        var msgArgs = message.Split('=');

        if (onAccessChecked != null) {
            onAccessChecked.Invoke(msgArgs[0], msgArgs[1] == "true");
        }
        Debug.Log($">> Permission check result: " + message);
    }

    public void OnCaptureDevicesSetup(string boolString) {
        bool devicesSetupSuccessfully = boolString == "true";
        Debug.Log(">> OnCaptureDevicesSetup, camera and mic setup succeeded? " + devicesSetupSuccessfully);
        if (onCaptureSessionSetup != null) {
            onCaptureSessionSetup.Invoke(devicesSetupSuccessfully);
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

    public void OnCameraActiveToggle(string active) {
        bool isActive = active == "true";

        if (onCameraActiveToggle != null) {
            onCameraActiveToggle.Invoke(isActive);
        }
    }

    public void OnCameraFullscreenToggle(string fullscreen) {
        bool isFullscreen = fullscreen == "true";
        if (onCameraFullscreenToggle != null) {
            onCameraFullscreenToggle.Invoke(isFullscreen);
        }
    }

    public void OnCameraBubbleMoved(string newScreenPositions) {
        Debug.Log("bubble moved to origin,topright: " + newScreenPositions);
        var coords = newScreenPositions.Split(',');

        var newPosition = new Vector2(float.Parse(coords[0]), float.Parse(coords[1]));
        var newTopRightPosition = new Vector2(float.Parse(coords[2]), float.Parse(coords[3]));

        if (onCameraBubbleMoved != null) {
            onCameraBubbleMoved.Invoke(newPosition, newTopRightPosition);
        }
    }
}

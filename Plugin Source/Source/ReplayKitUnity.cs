using UnityEngine;
using System.Runtime.InteropServices;


/// <summary>
/// Responsible for communicating with iOS Bridge file "ReplayKitBridge.mm". 
/// </summary> 
public class ReplayKitUnity : MonoBehaviour {

    #region Declare external C interface	
    #if UNITY_IOS && !UNITY_EDITOR

    //Functions 
    [DllImport("__Internal")]
    private static extern void _rp_startRecording();

    [DllImport("__Internal")]
    private static extern void _rp_stopRecording();

    [DllImport("__Internal")]
    private static extern void _rp_addDefaultButtonWindow();

    [DllImport("__Internal")]
    private static extern void _rp_showEmailShareSheet();

    //Properties 
    [DllImport("__Internal")]
    private static extern bool _rp_screenRecordingIsAvail();

    [DllImport("__Internal")]
    private static extern bool _rp_isRecording();

    [DllImport("__Internal")]
    private static extern string _rp_mailSubjectText(); 

    [DllImport("__Internal")]
    private static extern float _rp_allowedRecordTime();

    // ** Setters ** 
    [DllImport("__Internal")]
    private static extern void _rp_setCameraEnabled(bool cameraEnabled);

    [DllImport("__Internal")]
    private static extern void _rp_setMailSubject(string mailSubject);

    [DllImport("__Internal")]
    private static extern void _rp_setAllowedTimeToRecord(float seconds);

    
    #endif
    #endregion

    #region Public methods that you can use in your Unity project 

    public static void StartRecording() {
        #if UNITY_IOS && !UNITY_EDITOR
        _rp_startRecording();
        #endif
    }

   // Displays a recording button and recording progress view on the UI if there's a contsrained recording time set. These UI elements are excluded from the actual playback 
    public static void ShowDefaultButtonUI() {
        #if UNITY_IOS && !UNITY_EDITOR 
        _rp_addDefaultButtonWindow();
        #endif
    }

    public static void StopRecording() {
        #if UNITY_IOS && !UNITY_EDITOR
        _rp_stopRecording();
        #endif
    }

    // Show the standard iOS share sheet with email and default system options (message, facebook, twitter)
    public static void ShowEmailShareSheet() {
        #if UNITY_IOS && !UNITY_EDITOR
        _rp_showEmailShareSheet();
        #endif
    }

    // Check to see if the OS you are running allows for screen recording 
    public static bool IsScreenRecorderAvailable {
        get {
            #if UNITY_IOS && !UNITY_EDITOR
            return _rp_screenRecordingIsAvail();
            #else
            return false;
            #endif
        }
    }

    // Check to see if the screen is currently being recorded 
    public static bool IsRecording {
        get {
            #if UNITY_IOS && !UNITY_EDITOR
            return _rp_isRecording();
            #else
            return false;
            #endif
        }
    }

    // Set the subject line for sharing the recorded file via email 
    public static string MailSubjectText {
        get {
            #if UNITY_IOS && !UNITY_EDITOR 
            return _rp_mailSubjectText();
            #else
            return ""; 
            #endif 
        } set {
            #if UNITY_IOS && !UNITY_EDITOR
            _rp_setMailSubject(value);
            #endif 
        }
    }

    public static float AllowedTimeToRecord {
        get {
            #if UNITY_IOS && !UNITY_EDITOR
            return _rp_allowedRecordTime();
            #else 
            return 0; 
            #endif
        } set {
            #if UNITY_IOS && !UNITY_EDITOR
            _rp_setAllowedTimeToRecord(value);
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
                Debug.Log("ADDING REPLAYKIT SCRIPT" + obj);
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

    // Subrscribe to this action and return a call back of when the recording starts
    public System.Action onStartScreenCapture;

    // Subscribe to this action and return a video file path when the recording stops 
    public System.Action<string> onStopScreenCaptureWithFile;
    
    public void OnStartRecording() {
        if (onStartScreenCapture != null) {
			Debug.Log ("Callback calling callback");
            onStartScreenCapture.Invoke();
        }
    }

    public void OnStopRecording(string file) {
        if (onStopScreenCaptureWithFile != null) {
            onStopScreenCaptureWithFile.Invoke(file);
        }
    }

    #endregion
}

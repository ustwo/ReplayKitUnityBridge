using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;

public class NativeStreamingController : MonoBehaviour {

    public Text toggleMicButtonText;
    public Text toggleCameraActiveButtonText;
    public Text switchCameraButtonText;
    public GameObject stopStreamingButton;
    public GameObject startStreamingButton;
    public GameObject[] topBarButtons;
    public Button switchCameraButton;
    public Button toggleFullscreenButton;

    private bool showTopBarMenu = false;

    private HashSet<MediaType> accessGranted = new HashSet<MediaType>();
    private bool isCameraAndMicAccessGranted {
        get {
            return accessGranted.Contains(MediaType.Audio)
                && accessGranted.Contains(MediaType.Video);
        }
    }
    private bool cameraAndMicConfigured = false;

    private Action onNativeReadyToStream;

    void Start() {
        #if DEBUG
        // NativeStreaming.Instance.onInitialized += () => StartStreamingDebug();
        #endif

        NativeStreaming.Instance.onAccessChecked += OnAccessChecked;
        NativeStreaming.Instance.onCaptureSessionSetup += OnCaptureSessionSetup;
        NativeStreaming.Instance.onStartStreaming += UpdateButtons;
        NativeStreaming.Instance.onStopStreaming += UpdateButtons;
        NativeStreaming.Instance.onCameraFullscreenToggle += OnCameraFullscreenToggle;
        NativeStreaming.Instance.onCameraActiveToggle += (active) => {
            this.switchCameraButton.interactable = active;
            this.toggleFullscreenButton.interactable = active;
        };
        NativeStreaming.Instance.onTapCameraBubble += OnTapCameraBubble;

        NativeStreaming.Initialize();

        UpdateButtons();
    }

    /// Start streaming if access alreay granted
    /// Otherwise, request access to camera and mic
    /// and setup the audio capture session
    private void StartStreaming(string options) {
        if (!isCameraAndMicAccessGranted) {

            onNativeReadyToStream = () => StartStreaming(options);
            NativeStreaming.RequestAccessToCameraAndMic();
            return;
        } else if (!cameraAndMicConfigured) {

            onNativeReadyToStream = () => StartStreaming(options);
            NativeStreaming.SetupCaptureSession();
            return;
        }

        NativeStreaming.StartStreaming(options);
    }
    public void StartStreamingDebug() {
        #if DEBUG
        StartStreaming("address=rtmp://192.168.1.203:1935/stream streamName=hello width=1280 height=720 videoBitrate=5000000");
        #endif
    }
    public void StartStreaming(StreamOptions streamOptions) {
        StartStreaming(streamOptions.ToOptionsString());
    }

    public void StopStreaming() {
        NativeStreaming.StopStreaming();
    }

    // Disable / Enable streaming microphone audio
    public void ToggleMicActive() {
        NativeStreaming.SetMicActive(!NativeStreaming.IsMicActive);
        UpdateTexts();
    }

    // Disable / Enable streaming camera
    public void ToggleCameraActive() {
        NativeStreaming.SetCameraActive(!NativeStreaming.IsCameraActive);
        UpdateTexts();
    }


    // Switch to front / back camera
    public void SwitchCamera(bool useFrontCamera) {
        NativeStreaming.SwitchCamera(useFrontCamera);
        UpdateTexts();
    }
    public void SwitchCamera() {
        SwitchCamera(!NativeStreaming.IsUsingFrontCamera);
    }

    public void SetFullscreenCamera(bool fullscreen) {
        NativeStreaming.SetFullscreenCamera(fullscreen);
        showTopBarMenu = fullscreen;
    }
    public void ToggleFullscreenCamera() {
        SetFullscreenCamera(!NativeStreaming.IsFullscreenCamera);
    }


    // handle native messages

    public void OnAccessChecked(string typeString, bool accessWasGranted) {
        var type = AccessPermissionHelper.StringToType(typeString);
        if (accessWasGranted) {
            this.accessGranted.Add(type);
        } else {
            this.accessGranted.Remove(type);
        }

        // setup capture session if both access granted

        if (isCameraAndMicAccessGranted) {
            NativeStreaming.SetupCaptureSession();
        }
        UpdateStartStopButtons(NativeStreaming.IsStreaming);

        if (!accessWasGranted) {
            Debug.LogError("Getting Access to use camera or mic failed! The user probably denied Access.");
            return;
        }
    }

    public void OnCaptureSessionSetup(bool cameraAndMicConfigured) {
        this.cameraAndMicConfigured = cameraAndMicConfigured;
        UpdateStartStopButtons(NativeStreaming.IsStreaming);

        if (onNativeReadyToStream != null) {
            onNativeReadyToStream.Invoke();
            onNativeReadyToStream = null;
        }

        if (!cameraAndMicConfigured) {
            Debug.LogError("Initialize and configure camera/mic failed!");
            return;
        }
    }

    private void OnCameraFullscreenToggle(bool fullscreen) {
        Debug.Log($"camera {(fullscreen ? "fullscreen" : "in bubble")} - unity should update display accordingly");
        // update display for new camera size

    }

    private void OnTapCameraBubble() {
        // show topbar menu
        showTopBarMenu = !showTopBarMenu;
        UpdateButtonVisibility(showTopBarMenu);
        UpdateTexts();
    }

    // update buttons etc

    private void UpdateButtons() {
        UpdateButtonVisibility(NativeStreaming.IsStreaming && showTopBarMenu);
        UpdateStartStopButtons(NativeStreaming.IsStreaming);
        UpdateTexts();
    }

    private void UpdateButtonVisibility(bool show) {
        foreach (var go in topBarButtons) {
            go.SetActive(show);
        }
    }
    private void UpdateStartStopButtons(bool isLive) {
        startStreamingButton.SetActive(!isLive);
        stopStreamingButton.SetActive(isLive);
    }
    private void UpdateTexts() {
        toggleMicButtonText.text = $"{(NativeStreaming.IsMicActive ? "M" : "Unm")}ute mic";
        toggleCameraActiveButtonText.text = (NativeStreaming.IsCameraActive ? "Dis" : "En")+"able camera";
        switchCameraButtonText.text = NativeStreaming.IsUsingFrontCamera ? "Switch to Back" : "Switch to Front";
    }
}

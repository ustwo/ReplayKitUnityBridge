using System.Collections;
using UnityEngine;
using UnityEngine.UI;

public class NativeStreaming : MonoBehaviour {

    public GameObject[] visibleWhenLive;
    public GameObject[] visibleWhenOffline;
    public Text toggleMicButtonText;
    public Text toggleCameraActiveButtonText;
    public Text switchCameraButtonText;
    public Button switchCameraButton;

    // TODO: use real options
    private const string defaultOptions = "address=rtmp://192.168.1.203:1935/stream streamName=hello width=1280 height=720 videoBitrate=6500000"; // 6.5 Mbps for 720p

    void Start() {
        gameObject.name = "NativeStreaming";

        NativeStreamingBridge.Instance.onInitialized += () => StartStreamingDebug();

        NativeStreamingBridge.Instance.onStartStreaming += UpdateLiveIndicators;
        NativeStreamingBridge.Instance.onStopStreaming += UpdateLiveIndicators;
        NativeStreamingBridge.Instance.onCameraFullscreenToggle += OnCameraGrowToFullscreen;
        NativeStreamingBridge.Instance.onCameraSwitched += () => {
            this.switchCameraButton.interactable = true;
        };

        NativeStreamingBridge.Initialize(defaultOptions);

        // TODO: check device has camera & mic and are available for use by ios app

        UpdateTexts();
    }

    #if DEBUG
    public void StartStreamingDebug() {
        StartStreaming(defaultOptions);
    }
    #endif

    public void StartStreaming(string options) {
        // native stream consumes the camera feed
        // so let native show the camera feed
        NativeStreamingBridge.StartStreaming(options);
    }
    public void StopStreaming() {
        NativeStreamingBridge.StopStreaming();
    }

    // Disable / Enable streaming microphone audio
    public void ToggleMicActive() {
        NativeStreamingBridge.SetMicActive(!NativeStreamingBridge.IsMicActive);
        UpdateTexts();
    }

    // Disable / Enable streaming camera
    public void ToggleCameraActive() {
        NativeStreamingBridge.SetCameraActive(!NativeStreamingBridge.IsCameraActive);
        UpdateTexts();
    }
    public void SwitchCamera() {
        SwitchCamera(!NativeStreamingBridge.IsUsingFrontCamera);
    }

    // Switch to front / back camera
    public void SwitchCamera(bool useFrontCamera) {
        switchCameraButton.interactable = false;

        NativeStreamingBridge.SwitchCamera(useFrontCamera);
        UpdateTexts();
    }

    private void OnCameraGrowToFullscreen(bool fullscreen) {
        Debug.Log($"camera {(fullscreen ? "fullscreen" : "in bubble")} - unity should update display accordingly");
        // update display for new camera size
    }


    // update buttons etc

    private void UpdateLiveIndicators() {
        UpdateLiveIndicators(NativeStreamingBridge.IsStreaming);
    }
    private void UpdateLiveIndicators(bool liveStreaming) {
        foreach (var go in visibleWhenLive) {
            go.SetActive(liveStreaming);
        }
        foreach (var go in visibleWhenOffline) {
            go.SetActive(!liveStreaming);
        }
    }
    private void UpdateTexts() {
        toggleMicButtonText.text = $"{(NativeStreamingBridge.IsMicActive ? "M" : "Unm")}ute mic";
        toggleCameraActiveButtonText.text = (NativeStreamingBridge.IsCameraActive ? "Dis" : "En")+"able camera";
        switchCameraButtonText.text = NativeStreamingBridge.IsUsingFrontCamera ? "Switch to Back" : "Switch to Front";
    }
}

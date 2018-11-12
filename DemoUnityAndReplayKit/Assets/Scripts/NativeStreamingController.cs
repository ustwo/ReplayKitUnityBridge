using System.Collections;
using UnityEngine;
using UnityEngine.UI;

public class NativeStreamingController : MonoBehaviour {

    public GameObject[] visibleWhenLive;
    public GameObject[] visibleWhenOffline;
    public Text toggleMicButtonText;
    public Text toggleCameraActiveButtonText;
    public Text switchCameraButtonText;
    public Button switchCameraButton;

    void Start() {
        UpdateLiveIndicators();

        NativeStreaming.Instance.onInitialized += () => StartStreamingDebug();

        NativeStreaming.Instance.onStartStreaming += UpdateLiveIndicators;
        NativeStreaming.Instance.onStopStreaming += UpdateLiveIndicators;
        NativeStreaming.Instance.onCameraFullscreenToggle += OnCameraFullscreenToggle;
        NativeStreaming.Instance.onCameraSwitched += () => {
            this.switchCameraButton.interactable = true;
        };

        NativeStreaming.Initialize();

        // TODO: check device has camera & mic and are available for use by ios app

        UpdateTexts();
    }

    #if DEBUG
    public void StartStreamingDebug() {
        StartStreaming("address=rtmp://192.168.1.203:1935/stream streamName=hello width=1280 height=720 videoBitrate=5000000");
    }
    #endif

    public void StartStreaming(StreamOptions streamOptions) {
        StartStreaming(streamOptions.ToOptionsString());
    }

    private void StartStreaming(string options) {
        NativeStreaming.StartStreaming(options);
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
        switchCameraButton.interactable = false;

        NativeStreaming.SwitchCamera(useFrontCamera);
        UpdateTexts();
    }
    public void SwitchCamera() {
        SwitchCamera(!NativeStreaming.IsUsingFrontCamera);
    }

    public void SetFullscreenCamera(bool fullscreen) {
        NativeStreaming.SetFullscreenCamera(fullscreen);
        UpdateTexts();
    }
    public void ToggleFullscreenCamera() {
        SetFullscreenCamera(!NativeStreaming.IsFullscreenCamera);
        UpdateTexts();
    }

    private void OnCameraFullscreenToggle(bool fullscreen) {
        Debug.Log($"camera {(fullscreen ? "fullscreen" : "in bubble")} - unity should update display accordingly");
        // update display for new camera size
    }


    // update buttons etc

    private void UpdateLiveIndicators() {
        UpdateLiveIndicators(NativeStreaming.IsStreaming);
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
        toggleMicButtonText.text = $"{(NativeStreaming.IsMicActive ? "M" : "Unm")}ute mic";
        toggleCameraActiveButtonText.text = (NativeStreaming.IsCameraActive ? "Dis" : "En")+"able camera";
        switchCameraButtonText.text = NativeStreaming.IsUsingFrontCamera ? "Switch to Back" : "Switch to Front";
    }
}

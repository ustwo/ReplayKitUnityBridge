using System.Collections;
using UnityEngine;
using UnityEngine.UI;

public class NativeStreaming : MonoBehaviour {

    public CameraLiveDisplay cameraDisplay;
    public GameObject[] visibleWhileLive;
    public Text toggleMicButtonText;
    public Text toggleCameraActiveButtonText;
    public Text switchCameraButtonText;
    public Button switchCameraButton;

    void Start() {
        // TODO: check device has camera & mic and are available for use by ios app
        // if (ReplayKitUnity.IsScreenRecorderAvailable) {
        // } // end if
        UpdateTexts();
    }

    public void StartStreaming() {
        foreach (var go in visibleWhileLive) {
            go.SetActive(true);
        }
        ReplayKitUnity.StartStreaming("address=rtmp://192.168.1.203:1935/stream streamName=hello width=1280 height=720 videoBitrate="+(160 * 1280));
        // native stream consumes the camera feed
        // so let native show the camera feed
        cameraDisplay.HideDisplay();
        UpdateLiveIndicators(true);
    }
    public void StopStreaming() {
        ReplayKitUnity.StopStreaming();
        Debug.Log("native streaming stopped.");
        // cameraDisplay.ShowDisplay();
        UpdateLiveIndicators(false);
    }

    // Disable / Enable streaming microphone audio
    public void ToggleMicActive() {
        ReplayKitUnity.SetMicActive(!ReplayKitUnity.IsMicActive);
        UpdateTexts();
    }

    // Disable / Enable streaming camera
    public void ToggleCameraActive() {
        ReplayKitUnity.SetCameraActive(!ReplayKitUnity.IsCameraActive);

        if (ReplayKitUnity.IsCameraActive) {
            cameraDisplay.ShowDisplay();
        } else {
            cameraDisplay.HideDisplay();
        }
        UpdateTexts();
    }

    public void ToggleCameraPreview() {
        if (cameraDisplay.isActiveAndEnabled) {
            cameraDisplay.HideDisplay();
        } else {
            cameraDisplay.ShowDisplay();
        }
        UpdateTexts();
    }

    public void ToggleCamera() {
        SwitchCamera(!ReplayKitUnity.IsUsingFrontCamera);
    }

    // Disable / Enable streaming camera
    public void SwitchCamera(bool useFrontCamera) {
        switchCameraButton.interactable = false;

        ReplayKitUnity.SwitchCamera(useFrontCamera);
        cameraDisplay.SwapCamera(useFrontCamera);
        UpdateTexts();

        switchCameraButton.interactable = true;
    }

    private void UpdateLiveIndicators(bool liveStreaming) {
        foreach (var go in visibleWhileLive) {
            go.SetActive(liveStreaming);
        }
    }
    private void UpdateTexts() {
        toggleMicButtonText.text = $"{(ReplayKitUnity.IsMicActive ? "M" : "Unm")}ute mic";
        toggleCameraActiveButtonText.text = (ReplayKitUnity.IsCameraActive ? "Dis" : "En")+"able camera";
        switchCameraButtonText.text = ReplayKitUnity.IsUsingFrontCamera ? "Switch to Back" : "Switch to Front";
    }
}

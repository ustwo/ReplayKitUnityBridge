using System.Collections;
using UnityEngine;
using UnityEngine.UI;

public class NativeStreaming : MonoBehaviour {

    // public CameraLiveDisplay cameraDisplay;
    public GameObject[] visibleWhileLive;
    public Text toggleMicButtonText;
    public Text toggleCameraActiveButtonText;
    public Text switchCameraButtonText;
    public Button switchCameraButton;


    void Start() {
        // should probs check that camera and mic are avail for use by ios app
        // if (ReplayKitUnity.IsScreenRecorderAvailable) {
        // } // end if
        UpdateTexts();
    }

    public void StartStreaming() {
        foreach (var go in visibleWhileLive) {
            go.SetActive(true);
        }
        ReplayKitUnity.StartStreaming("address=rtmp://192.168.1.203:1935/stream streamName=hello width=1280 height=720 videoBitrate="+(160 * 1280));
        // cameraDisplay.ShowDisplay();
        UpdateLiveIndicators();
    }
    public void StopStreaming() {
        ReplayKitUnity.StopStreaming();
        UpdateLiveIndicators();
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
            // cameraDisplay.ShowDisplay();
        } else {
            // cameraDisplay.HideDisplay();
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
        // cameraDisplay.SwapCamera(useFrontCamera);
        UpdateTexts();

        switchCameraButton.interactable = true;
    }

    private void UpdateLiveIndicators() {
        foreach (var go in visibleWhileLive) {
            go.SetActive(ReplayKitUnity.IsStreaming);
        }
    }
    private void UpdateTexts() {
        toggleMicButtonText.text = $"{(ReplayKitUnity.IsMicActive ? "M" : "Unm")}ute mic";
        toggleCameraActiveButtonText.text = (ReplayKitUnity.IsCameraActive ? "Dis" : "En")+"able camera";
        switchCameraButtonText.text = ReplayKitUnity.IsUsingFrontCamera ? "Switch to Back" : "Switch to Front";
    }
}

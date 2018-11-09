using UnityEngine;
using UnityEngine.UI;

// displays the camera when streaming is inactive
public class CameraLiveDisplay : MonoBehaviour {
    WebCamTexture webcamBack = null; // higher quality camera, on back of mobile OR webcam of the desktop/laptop
    #if (UNITY_IOS || UNITY_ANDROID) && !UNITY_EDITOR
    WebCamTexture webcamFront = null; // the front facing camera on mobile
    #endif

    private Material material;

    void Start() {
        var renderer = GetComponent<Renderer>();
        this.material = renderer.material;

        if (WebCamTexture.devices.Length == 0) {
            Debug.LogError("This device has no cameras. Streaming will not work at all.");
            return;
        }
        webcamBack = new WebCamTexture(WebCamTexture.devices[0].name);
        Debug.Log(WebCamTexture.devices[0].name + " - primary camera device found");

        if (WebCamTexture.devices.Length > 1) {
            #if (UNITY_IOS || UNITY_ANDROID) && !UNITY_EDITOR
            webcamFront = new WebCamTexture(WebCamTexture.devices[1].name);
            Debug.Log(WebCamTexture.devices[1].name + " - secondary camera device found");
            #endif
        }

        #if (UNITY_IOS || UNITY_ANDROID) && !UNITY_EDITOR
        // front camera is default in native ios code
        material.mainTexture = webcamFront;
        #else
        material.mainTexture = webcamBack;
        #endif

        ShowDisplay();
    }

    // swap between front and back cameras on mobile
    public void SwapCamera(bool useFrontCamera) {
        #if (UNITY_IOS || UNITY_ANDROID) && !UNITY_EDITOR
        if (webcamFront == null) return; // only one camera available

        StopLiveDisplay();
        if (useFrontCamera) {
            Debug.Log("Swapping camera to webcamFront");
            // now use front face camera
            material.mainTexture = webcamFront;

        } else {
            // now use main camera on back
            Debug.Log("Swapping camera to webcamBack");
            material.mainTexture = webcamBack;
        }

        if (!ReplayKitUnity.IsStreaming) {
            ShowDisplay();
        }
        #endif
    }

    public void ShowDisplay() {
        StartLiveDisplay((WebCamTexture) material.mainTexture);
        gameObject.SetActive(true);
    }
    public void HideDisplay() {
        StopLiveDisplay();
        gameObject.SetActive(false);
    }

    public void StartLiveDisplay(WebCamTexture texture) {
        material.mainTexture = texture;
        texture.Play();
    }
    public void StopLiveDisplay() {
        if (material.mainTexture == null) return;
        ((WebCamTexture)material.mainTexture).Stop();
    }
}
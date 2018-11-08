using UnityEngine;
using UnityEngine.UI;

public class CameraLiveDisplay : MonoBehaviour {
    WebCamTexture webcamBack = null; // higher quality camera, on back of mobile OR webcam of the desktop/laptop
    #if (UNITY_IOS || UNITY_ANDROID) && !UNITY_EDITOR
    WebCamTexture webcamFront = null; // the front facing camera on mobile
    #endif

    private new Renderer renderer;

    void Start() {
        renderer = GetComponent<Renderer>();

        if (WebCamTexture.devices.Length == 0) {
            Debug.LogError("This device has no cameras. Streaming will not work at all.");
            return;
        }
        webcamBack = new WebCamTexture(WebCamTexture.devices[0].name);
        Debug.Log(WebCamTexture.devices[0].name + " - default camera device found");

        if (WebCamTexture.devices.Length > 1) {
            #if (UNITY_IOS || UNITY_ANDROID) && !UNITY_EDITOR
            webcamFront = new WebCamTexture(WebCamTexture.devices[1].name);
            Debug.Log(WebCamTexture.devices[1].name + " - secondary camera device found");
            #endif
        }

        #if (UNITY_IOS || UNITY_ANDROID) && !UNITY_EDITOR
        // front camera is default in native ios code
        renderer.material.mainTexture = webcamFront;
        #else
        renderer.material.mainTexture = webcamBack;
        #endif

        ShowDisplay();
    }

    private short frame = 0;
    void Update() {
        // periodically play the webcam input
        // because it sometimes freezes when starting the stream
        frame++;
        if (frame % 20 == 0) {
            // ((WebCamTexture) renderer.material.mainTexture).Play();
            // frame = 0;
        }
    }
    
    // swap between front and back cameras on mobile
    public void SwapCamera(bool useFrontCamera) {
        #if (UNITY_IOS || UNITY_ANDROID) && !UNITY_EDITOR
        if (webcamFront == null) return; // only one camera available

        Debug.Log("Swapping cameras");
        PauseLiveDisplay();
        if (useFrontCamera) {
            // now use front face camera
            StartLiveDisplay(webcamFront);
        } else {
            // now use main camera on back
            StartLiveDisplay(webcamBack);
        }
        #endif
    }

    public void ShowDisplay() {
        StartLiveDisplay((WebCamTexture) renderer.material.mainTexture);
        gameObject.SetActive(true);
    }
    public void HideDisplay() {
        PauseLiveDisplay();
        gameObject.SetActive(false);
    }

    public void StartLiveDisplay(WebCamTexture texture) {
        renderer.material.mainTexture = texture;
        float ratio = (float)texture.height / (float)texture.width;
        float height = transform.localScale.x * ratio;

        transform.localScale.Set(transform.localScale.x, height, 1);

        // flip horizontally
        Vector3 scale = renderer.transform.localScale;
        if (scale.x > 0) {
            scale.x = -scale.x;
            renderer.transform.localScale = scale;
        }

        ((WebCamTexture)renderer.material.mainTexture).Pause();
        ((WebCamTexture)renderer.material.mainTexture).Play();
    }
    public void PauseLiveDisplay() {
        if (renderer.material.mainTexture == null) return;
        ((WebCamTexture)renderer.material.mainTexture).Pause();
    }
}
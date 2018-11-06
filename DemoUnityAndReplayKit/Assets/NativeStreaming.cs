using System.Collections;
using UnityEngine;

public class NativeStreaming : MonoBehaviour {

    void Start() {

        // should probs check that camera and mic are avail for use by ios app
        // if (ReplayKitUnity.IsScreenRecorderAvailable) {
        ReplayKitUnity.Instance.onStopStreaming += OnStopStreaming;
        ReplayKitUnity.Instance.onStartStreaming += OnStartStreaming;
        // } // end if

        ReplayKitUnity.StartStreaming("keykey");
        // stop after delay
        StartCoroutine(StopStream(12));
    }

    IEnumerator StopStream(float time) {
        yield return new WaitForSeconds(time);

        Debug.Log("Calling StopSteaming...");
        ReplayKitUnity.StopStreaming();
    }

    // Call back that is triggered from iOS native
    public void OnStartStreaming() {
        Debug.Log("Callback On START Streaming");
    }
    public void OnStopStreaming() {
        Debug.Log("Callback On STOP Streaming");
    }

}

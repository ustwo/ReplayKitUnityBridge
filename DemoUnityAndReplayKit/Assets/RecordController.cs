using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Video;

public class RecordController : MonoBehaviour {

    public VideoPlayer videoPlayer; 
    private bool isRecording = false;
    public GameObject cube;
    public GameObject videoTexture; 
    public float TimeToRecord; 

    private static string MailSubjectLine = "Test Hello"; 
    
    void Start () {

        // Set the time you are allowing the user to record gameplay
        ReplayKitUnity.AllowedTimeToRecord = TimeToRecord; 

        // Tells ReplayKit to use a default interface that is excluded in playback         
        ReplayKitUnity.ShowDefaultButtonUI();

        // Subscribe to the ReplayKit callbacks 
        if (ReplayKitUnity.IsScreenRecorderAvailable) {    
            ReplayKitUnity.Instance.onStopScreenCaptureWithFile += OnStopCallback;
            ReplayKitUnity.Instance.onStartScreenCapture += OnStartRecording;
        }
    }

    void Awake() {
        ReplayKitUnity.StartStreaming("keykey");
        ReplayKitUnity.StopStreaming();
    }


    // Call back that is triggered from iOS native 
    public void OnStartRecording() {
        if (!isRecording) {
            isRecording = true; 
            cube.SetActive(true);
        }
    }


    // You will recieve the file path to the recorded gameplay session here 
    public void OnStopCallback(string file) {
        isRecording = false;
        cube.SetActive(false);
        videoTexture.SetActive(true);

        // Play the recorded video 
        StartCoroutine(playVideo(file));
    }

    IEnumerator playVideo(string file) {

        videoPlayer.enabled = true;
        if (videoPlayer == null) {
            Debug.Log("video player is null");
            yield return null; 
        }

    //Disable Play on Awake for both Video and Audio
    videoPlayer.playOnAwake = false;

    //We want to play from video clip not from url
    videoPlayer.source = VideoSource.Url;
    videoPlayer.url = file;
    
    //Set Audio Output to AudioSource
    videoPlayer.audioOutputMode = VideoAudioOutputMode.AudioSource;

    //Assign the Audio from Video to AudioSource to be played
    videoPlayer.EnableAudioTrack(0, true);
    //videoPlayer.SetTargetAudioSource(0, audioSource);

    //Set video To Play then prepare Audio to prevent Buffering
       videoPlayer.Prepare();

    //Wait until video is prepared
    while (!videoPlayer.isPrepared) {
        Debug.Log("Preparing Video");
        yield return null;
    }

   Debug.Log("Done Preparing Video");

   // Play Video
    videoPlayer.Play();


    Debug.Log("Playing Video");
    while (videoPlayer.isPlaying) {
    // Debug.LogWarning("Video Time: " + Mathf.FloorToInt((float)videoPlayer.time));  
        yield return null;
    }
    
        Debug.Log("Done Playing Video");
    }

    public void ShowSendVideoButton() {

    }

    public void DidTapSend() {

        // Set the subject line for the email message
        ReplayKitUnity.MailSubjectText = MailSubjectLine; 

        // Show the email/iOS share sheet 
        ReplayKitUnity.ShowEmailShareSheet();
    }
}

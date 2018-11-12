public class VideoPreset {
    // based on https://stream.twitch.tv/encoding/
    // re resolution is camera resolution
    public static VideoPreset tenEightyP_30Fps = new VideoPreset(1980, 1080, 4250 * 1000);
    public static VideoPreset sevenTwentyP_30Fps = new VideoPreset(1280, 720, 3250 * 1000);
    public static VideoPreset fourEightyP_30Fps = new VideoPreset(858, 480, 1800 * 1000);
    public static VideoPreset threeSixtyP_30Fps = new VideoPreset(480, 360, 1200 * 1000);

    public int width, height;
    public long bitrate;

    public VideoPreset(int width, int height, int bitrate) {
        this.width = width;
        this.height = height;
        this.bitrate = bitrate;
    }
}

public struct StreamOptions {
    public string address; // e.g. rtmp://eu1.twitch.tv/live
    public string streamName; // e.g. atheneLive
    public string streamKey;
    public VideoPreset videoPreset;

    public StreamOptions(string address, string streamName, string streamKey, VideoPreset videoPreset) {
        this.address = address;
        this.streamName = streamName;
        this.streamKey = streamKey;
        this.videoPreset = videoPreset;
    }

    public string ToOptionsString() {
        return $"address={address}" +
                $" streamName={streamName}" +
                $" streamKey={streamKey}" +
                $" width={videoPreset.width}" +
                $" height={videoPreset.height}" +
                $" videoBitrate={videoPreset.bitrate}";
    }
}

public enum MediaType {
    Video,
    Audio,
    Unknown
}

public static class AccessPermissionHelper {
    public static MediaType StringToType(string type) {
        if (type.StartsWith("vid")) return MediaType.Video;
        if (type.StartsWith("soun")) return MediaType.Audio;
        return MediaType.Unknown;
    }
}
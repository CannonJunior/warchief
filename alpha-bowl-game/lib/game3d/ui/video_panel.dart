import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
// ignore: avoid_web_libraries_in_flutter, undefined_prefixed_name
import 'dart:ui_web' as ui_web;
import '../../ai/video_analysis_service.dart';

/// Video entry model
class VideoEntry {
  String name;
  String url;

  VideoEntry({
    required this.name,
    required this.url,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'url': url,
  };

  factory VideoEntry.fromJson(Map<String, dynamic> json) => VideoEntry(
    name: json['name'] as String,
    url: json['url'] as String,
  );
}

/// Video Panel - Play videos from web links
class VideoPanel extends StatefulWidget {
  final VoidCallback onClose;
  final Function(String formationName, String playName, String videoUrl)? onMakePlay;

  const VideoPanel({
    Key? key,
    required this.onClose,
    this.onMakePlay,
  }) : super(key: key);

  @override
  State<VideoPanel> createState() => _VideoPanelState();
}

class _VideoPanelState extends State<VideoPanel> {
  // Draggable position
  double _xPos = 100.0;
  double _yPos = 50.0;

  // Video list
  List<VideoEntry> videos = [];
  int? selectedVideoIndex;

  // Video player
  html.VideoElement? videoElement;
  html.IFrameElement? iframeElement;
  String? videoViewType;
  bool isPlaying = false;
  double currentTime = 0.0;
  double duration = 0.0;
  bool isYouTubeVideo = false;

  // Add video form
  bool showAddForm = false;
  final TextEditingController nameController = TextEditingController();
  final TextEditingController urlController = TextEditingController();

  // Make Play state
  bool isAnalyzingVideo = false;

  @override
  void initState() {
    super.initState();
    _loadVideos();
  }

  @override
  void dispose() {
    nameController.dispose();
    urlController.dispose();
    videoElement?.pause();
    videoElement?.remove();
    iframeElement?.remove();
    super.dispose();
  }

  /// Load videos from SharedPreferences
  Future<void> _loadVideos() async {
    final prefs = await SharedPreferences.getInstance();
    final videosJson = prefs.getString('video_list');

    if (videosJson != null) {
      final List<dynamic> decoded = jsonDecode(videosJson);
      setState(() {
        videos = decoded.map((v) => VideoEntry.fromJson(v)).toList();
      });
    }
  }

  /// Save videos to SharedPreferences
  Future<void> _saveVideos() async {
    final prefs = await SharedPreferences.getInstance();
    final videosJson = jsonEncode(videos.map((v) => v.toJson()).toList());
    await prefs.setString('video_list', videosJson);
  }

  /// Add a new video
  void _addVideo() {
    if (nameController.text.isEmpty || urlController.text.isEmpty) {
      return;
    }

    setState(() {
      videos.add(VideoEntry(
        name: nameController.text,
        url: urlController.text,
      ));
      nameController.clear();
      urlController.clear();
      showAddForm = false;
    });
    _saveVideos();
  }

  /// Remove a video
  void _removeVideo(int index) {
    setState(() {
      if (selectedVideoIndex == index) {
        selectedVideoIndex = null;
        videoElement?.pause();
        videoElement?.remove();
        videoElement = null;
      } else if (selectedVideoIndex != null && selectedVideoIndex! > index) {
        selectedVideoIndex = selectedVideoIndex! - 1;
      }
      videos.removeAt(index);
    });
    _saveVideos();
  }

  /// Select and load a video
  void _selectVideo(int index) {
    if (selectedVideoIndex == index) return;

    setState(() {
      selectedVideoIndex = index;
      isPlaying = false;
      currentTime = 0.0;
      duration = 0.0;
    });

    _loadVideoPlayer(videos[index].url);
  }

  /// Check if URL is a YouTube URL
  bool _isYouTubeUrl(String url) {
    return url.contains('youtube.com') || url.contains('youtu.be');
  }

  /// Convert YouTube URL to embed URL
  String _getYouTubeEmbedUrl(String url) {
    // Handle different YouTube URL formats
    String? videoId;

    // youtube.com/watch?v=VIDEO_ID
    if (url.contains('youtube.com/watch')) {
      final uri = Uri.parse(url);
      videoId = uri.queryParameters['v'];
    }
    // youtu.be/VIDEO_ID
    else if (url.contains('youtu.be/')) {
      videoId = url.split('youtu.be/').last.split('?').first;
    }
    // youtube.com/embed/VIDEO_ID (already embed format)
    else if (url.contains('youtube.com/embed/')) {
      return url;
    }

    if (videoId != null) {
      return 'https://www.youtube.com/embed/$videoId?enablejsapi=1';
    }

    return url; // Return original if can't parse
  }

  /// Load video player
  void _loadVideoPlayer(String url) {
    // Remove old elements
    videoElement?.pause();
    videoElement?.remove();
    iframeElement?.remove();

    final String viewType = 'video-player-${DateTime.now().millisecondsSinceEpoch}';

    // Check if this is a YouTube URL
    if (_isYouTubeUrl(url)) {
      // Use iframe for YouTube videos
      setState(() {
        isYouTubeVideo = true;
        isPlaying = false;
        currentTime = 0.0;
        duration = 0.0;
      });

      final embedUrl = _getYouTubeEmbedUrl(url);
      iframeElement = html.IFrameElement()
        ..src = embedUrl
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.border = 'none'
        ..allow = 'accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture';

      // Register view factory for iframe
      // ignore: undefined_prefixed_name
      ui_web.platformViewRegistry.registerViewFactory(
        viewType,
        (int viewId) => iframeElement!,
      );

      setState(() {
        videoViewType = viewType;
      });
    } else {
      // Use HTML5 video element for direct video URLs
      setState(() {
        isYouTubeVideo = false;
        isPlaying = false;
        currentTime = 0.0;
        duration = 0.0;
      });

      videoElement = html.VideoElement()
        ..src = url
        ..controls = false
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.backgroundColor = 'black';

      // Register view factory
      // ignore: undefined_prefixed_name
      ui_web.platformViewRegistry.registerViewFactory(
        viewType,
        (int viewId) => videoElement!,
      );

      setState(() {
        videoViewType = viewType;
      });

      // Set up event listeners for HTML5 video
      videoElement!.onLoadedMetadata.listen((_) {
        setState(() {
          duration = (videoElement!.duration ?? 0.0).toDouble();
        });
      });

      videoElement!.onTimeUpdate.listen((_) {
        setState(() {
          currentTime = (videoElement!.currentTime ?? 0.0).toDouble();
        });
      });

      videoElement!.onPlay.listen((_) {
        setState(() {
          isPlaying = true;
        });
      });

      videoElement!.onPause.listen((_) {
        setState(() {
          isPlaying = false;
        });
      });

      videoElement!.onEnded.listen((_) {
        setState(() {
          isPlaying = false;
          currentTime = 0.0;
        });
      });
    }
  }

  /// Play/pause video (only works for non-YouTube videos)
  void _togglePlayPause() {
    if (isYouTubeVideo) {
      // YouTube videos need to be controlled via their own player
      return;
    }

    if (videoElement == null) return;

    if (isPlaying) {
      videoElement!.pause();
    } else {
      videoElement!.play();
    }
  }

  /// Rewind video by 10 seconds (only works for non-YouTube videos)
  void _rewind() {
    if (isYouTubeVideo) return;
    if (videoElement == null) return;
    final current = (videoElement!.currentTime ?? 0.0).toDouble();
    videoElement!.currentTime = (current - 10.0).clamp(0.0, duration);
  }

  /// Fast forward video by 10 seconds (only works for non-YouTube videos)
  void _fastForward() {
    if (isYouTubeVideo) return;
    if (videoElement == null) return;
    final current = (videoElement!.currentTime ?? 0.0).toDouble();
    videoElement!.currentTime = (current + 10.0).clamp(0.0, duration);
  }

  /// Format time in MM:SS
  String _formatTime(double seconds) {
    final minutes = (seconds / 60).floor();
    final secs = (seconds % 60).floor();
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  /// Analyze video and create play in Playbook
  Future<void> _makePlayFromVideo() async {
    if (selectedVideoIndex == null || widget.onMakePlay == null) return;

    final video = videos[selectedVideoIndex!];

    setState(() {
      isAnalyzingVideo = true;
    });

    try {
      // Analyze video and create formation
      final formation = await VideoAnalysisService.analyzeVideoAndCreatePlay(
        videoUrl: video.url,
        formationName: video.name,
        playName: '001',
      );

      // Notify parent to add formation to Playbook
      widget.onMakePlay!(video.name, '001', video.url);

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Play created! Open Playbook (O) to view "${video.name}" formation'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      print('Error creating play from video: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating play: $e'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isAnalyzingVideo = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black54,
      child: Stack(
        children: [
          Positioned(
            left: _xPos,
            top: _yPos,
            child: Container(
              width: 1200,
              height: 800,
              decoration: BoxDecoration(
                color: Colors.grey.shade900,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.5),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Header (draggable)
                  GestureDetector(
                    onPanUpdate: (details) {
                      setState(() {
                        _xPos += details.delta.dx;
                        _yPos += details.delta.dy;
                        // Clamp position to screen bounds
                        _xPos = _xPos.clamp(0.0, MediaQuery.of(context).size.width - 1200);
                        _yPos = _yPos.clamp(0.0, MediaQuery.of(context).size.height - 800);
                      });
                    },
                    child: Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(10),
                    topRight: Radius.circular(10),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Video Player',
                      style: TextStyle(
                        color: Colors.green,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: Icon(Icons.add, color: Colors.green),
                          onPressed: () {
                            setState(() {
                              showAddForm = !showAddForm;
                            });
                          },
                          tooltip: 'Add Video',
                        ),
                        SizedBox(width: 8),
                        IconButton(
                          icon: Icon(Icons.close, color: Colors.red),
                          onPressed: widget.onClose,
                        ),
                      ],
                    ),
                  ],
                ),
                    ),
                  ),

                  // Main content
                  Expanded(
                    child: Row(
                      children: [
                        // Sidebar - Video list
                        Container(
                      width: 300,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade800,
                        border: Border(
                          right: BorderSide(color: Colors.green, width: 1),
                        ),
                      ),
                      child: Column(
                        children: [
                          // Add video form
                          if (showAddForm)
                            Container(
                              padding: EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade700,
                                border: Border(
                                  bottom: BorderSide(color: Colors.green, width: 1),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Text(
                                    'Add Video',
                                    style: TextStyle(
                                      color: Colors.green,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(height: 12),
                                  TextField(
                                    controller: nameController,
                                    autofocus: true,
                                    style: TextStyle(color: Colors.white),
                                    decoration: InputDecoration(
                                      labelText: 'Name',
                                      labelStyle: TextStyle(color: Colors.grey),
                                      filled: true,
                                      fillColor: Colors.grey.shade900,
                                      border: OutlineInputBorder(),
                                    ),
                                    onSubmitted: (_) => _addVideo(),
                                  ),
                                  SizedBox(height: 8),
                                  TextField(
                                    controller: urlController,
                                    style: TextStyle(color: Colors.white),
                                    decoration: InputDecoration(
                                      labelText: 'Video URL',
                                      labelStyle: TextStyle(color: Colors.grey),
                                      filled: true,
                                      fillColor: Colors.grey.shade900,
                                      border: OutlineInputBorder(),
                                    ),
                                    onSubmitted: (_) => _addVideo(),
                                  ),
                                  SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      TextButton(
                                        onPressed: () {
                                          setState(() {
                                            showAddForm = false;
                                            nameController.clear();
                                            urlController.clear();
                                          });
                                        },
                                        child: Text('Cancel'),
                                      ),
                                      SizedBox(width: 8),
                                      ElevatedButton(
                                        onPressed: _addVideo,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.green,
                                        ),
                                        child: Text('Add'),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                          // Video list
                          Expanded(
                            child: videos.isEmpty
                                ? Center(
                                    child: Text(
                                      'No videos yet.\nClick + to add one.',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: Colors.grey,
                                        fontSize: 14,
                                      ),
                                    ),
                                  )
                                : ListView.builder(
                                    itemCount: videos.length,
                                    itemBuilder: (context, index) {
                                      final video = videos[index];
                                      final isSelected = selectedVideoIndex == index;

                                      return ListTile(
                                        title: Text(
                                          video.name,
                                          style: TextStyle(
                                            color: isSelected ? Colors.green : Colors.white,
                                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                          ),
                                        ),
                                        subtitle: Text(
                                          video.url,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            color: Colors.grey,
                                            fontSize: 12,
                                          ),
                                        ),
                                        tileColor: isSelected ? Colors.green.withOpacity(0.2) : null,
                                        onTap: () => _selectVideo(index),
                                        trailing: IconButton(
                                          icon: Icon(Icons.delete, color: Colors.red, size: 20),
                                          onPressed: () => _removeVideo(index),
                                        ),
                                      );
                                    },
                                  ),
                          ),
                        ],
                      ),
                    ),

                    // Video player area
                    Expanded(
                      child: Container(
                        color: Colors.black,
                        child: Column(
                          children: [
                            // Video display
                            Expanded(
                              child: selectedVideoIndex == null
                                  ? Center(
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.video_library,
                                            size: 80,
                                            color: Colors.grey.shade600,
                                          ),
                                          SizedBox(height: 16),
                                          Text(
                                            'Select a video from the list',
                                            style: TextStyle(
                                              color: Colors.grey,
                                              fontSize: 18,
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                  : videoViewType != null
                                      ? HtmlElementView(viewType: videoViewType!)
                                      : Center(
                                          child: CircularProgressIndicator(
                                            color: Colors.green,
                                          ),
                                        ),
                            ),

                            // Video controls (only for non-YouTube videos)
                            if (selectedVideoIndex != null && !isYouTubeVideo)
                              Container(
                                padding: EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade900,
                                  border: Border(
                                    top: BorderSide(color: Colors.green, width: 1),
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    // Progress bar
                                    Row(
                                      children: [
                                        Text(
                                          _formatTime(currentTime),
                                          style: TextStyle(color: Colors.white, fontSize: 12),
                                        ),
                                        SizedBox(width: 8),
                                        Expanded(
                                          child: LinearProgressIndicator(
                                            value: duration > 0 ? currentTime / duration : 0.0,
                                            backgroundColor: Colors.grey.shade700,
                                            valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                                          ),
                                        ),
                                        SizedBox(width: 8),
                                        Text(
                                          _formatTime(duration),
                                          style: TextStyle(color: Colors.white, fontSize: 12),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 12),
                                    // Control buttons
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        IconButton(
                                          icon: Icon(Icons.replay_10, color: Colors.white, size: 32),
                                          onPressed: _rewind,
                                          tooltip: 'Rewind 10s',
                                        ),
                                        SizedBox(width: 24),
                                        IconButton(
                                          icon: Icon(
                                            isPlaying ? Icons.pause_circle : Icons.play_circle,
                                            color: Colors.green,
                                            size: 48,
                                          ),
                                          onPressed: _togglePlayPause,
                                          tooltip: isPlaying ? 'Pause' : 'Play',
                                        ),
                                        SizedBox(width: 24),
                                        IconButton(
                                          icon: Icon(Icons.forward_10, color: Colors.white, size: 32),
                                          onPressed: _fastForward,
                                          tooltip: 'Fast Forward 10s',
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),

                            // YouTube video note
                            if (selectedVideoIndex != null && isYouTubeVideo)
                              Container(
                                padding: EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade900,
                                  border: Border(
                                    top: BorderSide(color: Colors.green, width: 1),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.info_outline, color: Colors.cyan, size: 16),
                                    SizedBox(width: 8),
                                    Text(
                                      'YouTube video - Use the player controls in the video',
                                      style: TextStyle(color: Colors.cyan, fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),

                            // Make Play button
                            if (selectedVideoIndex != null)
                              Container(
                                padding: EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade900,
                                  border: Border(
                                    top: BorderSide(color: Colors.green, width: 1),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    ElevatedButton.icon(
                                      onPressed: isAnalyzingVideo ? null : _makePlayFromVideo,
                                      icon: isAnalyzingVideo
                                          ? SizedBox(
                                              width: 20,
                                              height: 20,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: Colors.white,
                                              ),
                                            )
                                          : Icon(Icons.auto_awesome, size: 24),
                                      label: Text(
                                        isAnalyzingVideo ? 'Analyzing...' : 'Make Play',
                                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.purple,
                                        foregroundColor: Colors.white,
                                        padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                                        disabledBackgroundColor: Colors.grey.shade700,
                                      ),
                                    ),
                                    SizedBox(width: 16),
                                    Expanded(
                                      child: Text(
                                        'Analyze this video and create a formation in Playbook',
                                        style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

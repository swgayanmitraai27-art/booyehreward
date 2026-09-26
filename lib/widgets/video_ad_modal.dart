import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class VideoAdModal extends StatefulWidget {
  final String title;
  final String rewardDescription;
  final VoidCallback onAdCompleted;

  const VideoAdModal({
    super.key,
    required this.title,
    required this.rewardDescription,
    required this.onAdCompleted,
  });

  @override
  State<VideoAdModal> createState() => _VideoAdModalState();
}

class _VideoAdModalState extends State<VideoAdModal> {
  int secondsRemaining = 8;
  Timer? timer;
  bool isCompleted = false;

  @override
  void initState() {
    super.initState();
    timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (secondsRemaining > 1) {
        setState(() {
          secondsRemaining--;
        });
      } else {
        t.cancel();
        setState(() {
          secondsRemaining = 0;
          isCompleted = true;
        });
      }
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: isCompleted,
      child: Dialog(
        backgroundColor: Colors.black,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 420, maxHeight: 600),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                color: const Color(0xFF1E293B),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.amber,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'Ad',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              color: Colors.black,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          widget.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    if (!isCompleted)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white24),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.timer_outlined, size: 12, color: Colors.amber),
                            const SizedBox(width: 4),
                            Text(
                              'Reward in ${secondsRemaining}s',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () {
                          Navigator.of(context).pop();
                          widget.onAdCompleted();
                        },
                      ),
                  ],
                ),
              ),

              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.asset(
                      'imgasest/brhomescreen .png',
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: const Color(0xFF0F172A),
                        child: const Center(
                          child: Icon(Icons.play_circle_fill, size: 64, color: Colors.amber),
                        ),
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withAlpha(80),
                            Colors.black.withAlpha(180),
                          ],
                        ),
                      ),
                    ),
                    Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (!isCompleted) ...[
                            const SizedBox(
                              width: 50,
                              height: 50,
                              child: CircularProgressIndicator(
                                strokeWidth: 4,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.amber),
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              '🎮 FREE FIRE REWARDED AD',
                              style: TextStyle(
                                color: Colors.amber,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.2,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Watch video to unlock room details',
                              style: TextStyle(color: Colors.white70, fontSize: 11),
                            ),
                          ] else ...[
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: const BoxDecoration(
                                color: AppTheme.winningGreen,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.check, color: Colors.white, size: 40),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              '🎉 AD COMPLETED!',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 18,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.rewardDescription,
                              style: const TextStyle(color: Colors.amber, fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              Container(
                padding: const EdgeInsets.all(14),
                color: const Color(0xFF1E293B),
                child: isCompleted
                    ? SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryAmber,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: () {
                            Navigator.of(context).pop();
                            widget.onAdCompleted();
                          },
                          child: const Text(
                            'CLAIM REWARD & VIEW ROOM',
                            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
                          ),
                        ),
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.lock, size: 14, color: Colors.white60),
                          SizedBox(width: 6),
                          Text(
                            'Reward will unlock when timer ends',
                            style: TextStyle(color: Colors.white60, fontSize: 11),
                          ),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

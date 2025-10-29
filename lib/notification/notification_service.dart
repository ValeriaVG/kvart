import 'package:just_audio/just_audio.dart';

class NotificationService {
  final AudioPlayer _audioPlayer = AudioPlayer();

  Future<void> timeIsUp() async {
    await loadAudio();
    await _audioPlayer.play();
  }

  Future<void> loadAudio() async {
    await _audioPlayer.setAsset(
      'assets/audio/game-ui-level-unlock-om-fx-1-1-00-05.mp3',
    );
  }
}

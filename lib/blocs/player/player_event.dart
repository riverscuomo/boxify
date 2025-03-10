part of 'player_bloc.dart';

abstract class PlayerEvent extends Equatable {
  const PlayerEvent();

  @override
  List<Object?> get props => [];
}

class PlayerReset extends PlayerEvent {
  const PlayerReset();
  @override
  List<Object?> get props => [];
}

class NotifyAutoAdvance extends PlayerEvent {
  @override
  List<Object?> get props => [];
}

class Play extends PlayerEvent {
  const Play();
  @override
  List<Object?> get props => [];
}

class StartPlayback extends PlayerEvent {
  final int? index;
  final List<Track> tracks;
  final String? source;

  const StartPlayback({required this.index, required this.tracks, this.source});

  @override
  List<Object?> get props => [tracks, index];
}

class LoadPlayer extends PlayerEvent {
  final List<Track> tracks;
  final bool play;
  final int? index;

  /// Adds the given tracks to the audio source and sets the audio source on the player.
  /// Emtits the state.queue
  const LoadPlayer(this.tracks, {this.index, this.play = false});

  @override
  List<Object?> get props => [index, tracks, play];
}

class SeekToIndex extends PlayerEvent {
  final int index;
  const SeekToIndex({required this.index});
  @override
  List<Object?> get props => [index];
}

class SeekToPrevious extends PlayerEvent {
  const SeekToPrevious();
  @override
  List<Object?> get props => [];
}

class SeekToNext extends PlayerEvent {
  const SeekToNext();
  @override
  List<Object?> get props => [];
}

class UpdateTrackBackgroundColor extends PlayerEvent {
  final HSLColor backgroundColor;
  const UpdateTrackBackgroundColor({required this.backgroundColor});
  @override
  List<Object?> get props => [backgroundColor];
}

// class LogListen extends PlayerEvent {
//   const LogListen();
//   @override
//   List<Object?> get props => [];
// }

/// This file is a part of Harmonoid (https://github.com/harmonoid/harmonoid).
///
/// Copyright © 2020-2022, Hitesh Kumar Saini <saini123hitesh@gmail.com>.
/// All rights reserved.
///
/// Use of this source code is governed by the End-User License Agreement for Harmonoid that can be found in the EULA.txt file.
///
import 'package:flutter/widgets.dart';
import 'package:libmpv/libmpv.dart';
import 'package:youtube_music/youtube_music.dart';

import 'package:harmonoid/models/media.dart' as media;
import 'package:harmonoid/core/playback.dart';
import 'package:harmonoid/core/configuration.dart';

class YouTube extends ChangeNotifier {
  static final instance = YouTube();

  String current = '';
  bool exception = false;
  List<Track>? recommendations;

  Future<void> next() async {
    if (Configuration.instance.discoverRecent.isEmpty) return;
    if (current == Configuration.instance.discoverRecent.first) return;
    exception = false;
    notifyListeners();
    if (Configuration.instance.discoverRecent.isNotEmpty) {
      try {
        recommendations = await YouTubeMusic.next(
          Configuration.instance.discoverRecent.first,
        );
        if (recommendations!.length == 1) {
          await next();
        }
        recommendations!.addAll(
          (await YouTubeMusic.next(Plugins.redirect(recommendations!.last.uri)
                  .queryParameters['id']!))
              .skip(1),
        );
        current = Configuration.instance.discoverRecent.first;
        notifyListeners();
      } catch (_) {
        recommendations = [];
        exception = true;
        notifyListeners();
      }
    }
  }

  /// Plays a [Track] or a [Video] automatically handling conversion to local model [media.Track].
  Future<void> open(
    value, {
    int index = 0,
  }) async {
    if (value is Track) {
      Playback.instance.open(
        [media.Track.fromYouTubeMusicTrack(value.toJson())],
      );
      await Configuration.instance.save(
        discoverRecent: [Plugins.redirect(value.uri).queryParameters['id']!],
      );
      await next();
      if (recommendations != null) {
        Playback.instance.add(
          recommendations!
              .sublist(1)
              .map((e) => media.Track.fromJson(e.toJson()))
              .toList(),
        );
      }
    } else if (value is Video) {
      Playback.instance.open(
        [media.Track.fromYouTubeMusicVideo(value.toJson())],
      );
      await Configuration.instance.save(
        discoverRecent: [Plugins.redirect(value.uri).queryParameters['id']!],
      );
      await next();
      if (recommendations != null) {
        Playback.instance.add(
          recommendations!
              .sublist(1)
              .map((e) => media.Track.fromJson(e.toJson()))
              .toList(),
        );
      }
    } else if (value is List<Track>) {
      Playback.instance.open(
        value
            .map((e) => media.Track.fromYouTubeMusicTrack(e.toJson()))
            .toList(),
        index: index,
      );
    }
  }

  @override
  // ignore: must_call_super
  void dispose() {}
}

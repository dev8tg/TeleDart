/**
 * TeleDart - Telegram Bot API for Dart
 * Copyright (C) 2019  Dino PH Leung
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

import 'dart:async';
import 'dart:convert';
import 'dart:io' as io;

import 'package:http/http.dart' as http;

import 'model.dart';
import '../util/http_client.dart';

class Telegram {
  final HttpClient _client = HttpClient();
  final String _baseUrl = 'https://api.telegram.org/bot';
  final String _token;

  Telegram(this._token);

  /// Use this method to receive incoming updates using long polling ([wiki]).
  /// An Array of [Update] objects is returned.
  ///
  /// **Notes**
  /// 1. This method will not work if an outgoing webhook is set up.
  /// 2. In order to avoid getting duplicate updates, recalculate offset after each server response.
  ///
  /// https://core.telegram.org/bots/api#getupdates
  ///
  /// [wiki]: http://en.wikipedia.org/wiki/Push_technology#Long_polling
  /// [Update]: https://core.telegram.org/bots/api#update
  Future<List<Update>> getUpdates(
      {int offset,
      int limit,
      int timeout,
      List<String> allowed_updates}) async {
    String requestUrl = '${_baseUrl}${_token}/getUpdates?' +
        (offset == null ? '' : 'offset=${offset}&') +
        (limit == null ? '' : 'limit=${limit}&') +
        (timeout == null ? '' : 'timeout=${timeout}') +
        (allowed_updates == null
            ? ''
            : 'allowed_updates=${jsonEncode(allowed_updates)}');
    return (await _client.httpGet(requestUrl))
        .map<Update>((update) => Update.fromJson(update))
        .toList();
  }

  /// Use this method to specify a url and receive incoming updates via an outgoing webhook.
  /// Whenever there is an update for the bot, we will send an HTTPS POST request to the
  /// specified url, containing a JSON-serialized [Update].
  /// In case of an unsuccessful request, we will give up after a reasonable amount of attempts.
  /// Returns True on success.
  /// If you'd like to make sure that the Webhook request comes from Telegram,
  /// we recommend using a secret path in the URL, e.g. `https://www.example.com/<token>`.
  /// Since nobody else knows your bot‘s token, you can be pretty sure it’s us.
  ///
  /// **Notes**
  /// 1. You will not be able to receive updates using [getUpdates] for as long as an outgoing webhook is set up.
  /// 2. To use a self-signed certificate, you need to upload your [public key certificate] using certificate parameter. Please upload as InputFile, sending a String will not work.
  /// 3. Ports currently supported for Webhooks: **443, 80, 88, 8443**.
  ///
  /// **NEW!** If you're having any trouble setting up webhooks, please check out this amazing guide to Webhooks.
  ///
  /// https://core.telegram.org/bots/api#setwebhook
  ///
  /// [update]: https://core.telegram.org/bots/api#update
  /// [getUpdates]: https://core.telegram.org/bots/api#getupdates
  /// [public key certificate]: https://core.telegram.org/bots/self-signed
  Future<bool> setWebhook(String url,
      {io.File certificate,
      int max_connections,
      List<String> allowed_updates}) async {
    String requestUrl = '${_baseUrl}${_token}/setWebhook';
    Map<String, dynamic> body = {
      'url': url,
      'max_connections': max_connections ?? '',
      'allowed_updates': allowed_updates ?? ''
    };
    if (certificate != null) {
      // filename cannot be empty to post to Telegram server
      List<http.MultipartFile> files = List();
      files.add(http.MultipartFile(
          'certificate', certificate.openRead(), certificate.lengthSync(),
          filename: '${certificate.lengthSync()}'));
      return await _client.httpMultipartPost(requestUrl, files, body: body);
    } else {
      return await _client.httpPost(requestUrl, body: body);
    }
  }

  /// Use this method to remove webhook integration if you decide to switch back to [getUpdates].
  /// Returns True on success. Requires no parameters.
  ///
  /// https://core.telegram.org/bots/api#deletewebhook
  ///
  /// [getUpdates]: https://core.telegram.org/bots/api#getupdates
  Future<bool> deleteWebhook() async {
    return await _client.httpGet('${_baseUrl}${_token}/deleteWebhook');
  }

  /// Use this method to get current webhook status. Requires no parameters.
  /// On success, returns a [WebhookInfo] object.
  /// If the bot is using [getUpdates], will return an object with the *url* field empty.
  ///
  /// https://core.telegram.org/bots/api#getwebhookinfo
  ///
  /// [WebhookInfo]: https://core.telegram.org/bots/api#webhookinfo
  /// [getUpdates]: https://core.telegram.org/bots/api#getupdates
  Future<WebhookInfo> getWebhookInfo() async {
    return WebhookInfo.fromJson(
        await _client.httpGet('${_baseUrl}${_token}/getWebhookInfo'));
  }

  /// A simple method for testing your bot's auth token. Requires no parameters.
  /// Returns basic information about the bot in form of a [User] object.
  ///
  /// https://core.telegram.org/bots/api#getme
  ///
  /// [User]: https://core.telegram.org/bots/api#user
  Future<User> getMe() async {
    return User.fromJson(await _client.httpGet('${_baseUrl}${_token}/getMe'));
  }

  /// Use this method to send text messages. On success, the sent [Message] is returned.
  ///
  /// [**Formatting options**](https://core.telegram.org/bots/api#formatting-options)
  ///
  /// https://core.telegram.org/bots/api#sendmessage
  ///
  /// [Message]: https://core.telegram.org/bots/api#message
  Future<Message> sendMessage(int chat_id, String text,
      {String parse_mode,
      bool disable_web_page_preview,
      bool disable_notification,
      int reply_to_message_id,
      ReplyMarkup reply_markup}) async {
    String requestUrl = '${_baseUrl}${_token}/sendMessage';
    Map<String, dynamic> body = {
      'chat_id': chat_id,
      'text': text,
      'parse_mode': parse_mode ?? '',
      'disable_web_page_preview': disable_web_page_preview ?? '',
      'disable_notification': disable_notification ?? '',
      'reply_to_message_id': reply_to_message_id ?? '',
      'reply_markup': reply_markup == null ? '' : jsonEncode(reply_markup)
    };
    return Message.fromJson(await _client.httpPost(requestUrl, body: body));
  }

  /// Use this method to forward messages of any kind. On success, the sent [Message] is returned.
  ///
  /// https://core.telegram.org/bots/api#forwardmessage
  ///
  /// [Message]: https://core.telegram.org/bots/api#message
  Future<Message> forwardMessage(int chat_id, int from_char_id, int message_id,
      {bool disable_notification}) async {
    String requestUrl = '${_baseUrl}${_token}/forwardMessage';
    Map<String, dynamic> body = {
      'chat_id': chat_id,
      'from_char_id': from_char_id,
      'message_id': message_id,
      'disable_notification': disable_notification ?? ''
    };
    return Message.fromJson(await _client.httpPost(requestUrl, body: body));
  }

  /// Use this method to send photos. On success, the sent [Message] is returned.
  ///
  /// https://core.telegram.org/bots/api#sendphoto
  ///
  /// [Message]: https://core.telegram.org/bots/api#message
  Future<Message> sendPhoto(int chat_id, dynamic photo,
      {String caption,
      String parse_mode,
      bool disable_notification,
      int reply_to_message_id,
      ReplyMarkup reply_markup}) async {
    String requestUrl = '${_baseUrl}${_token}/sendPhoto';
    Map<String, dynamic> body = {
      'chat_id': chat_id,
      'caption': caption ?? '',
      'parse_mode': parse_mode ?? '',
      'disable_notification': disable_notification ?? '',
      'reply_to_message_id': reply_to_message_id ?? '',
      'reply_markup': reply_markup == null ? '' : jsonEncode(reply_markup)
    };

    if (photo is io.File) {
      // filename cannot be empty to post to Telegram server
      List<http.MultipartFile> files = List();
      files.add(http.MultipartFile(
          'photo', photo.openRead(), photo.lengthSync(),
          filename: '${photo.lengthSync()}'));
      return Message.fromJson(
          await _client.httpMultipartPost(requestUrl, files, body: body));
    } else if (photo is String) {
      body.addAll({'photo': photo});
      return Message.fromJson(await _client.httpPost(requestUrl, body: body));
    } else {
      return Future.error(TelegramException(
          'Attribute \'photo\' can only be either io.File or String (Telegram file_id or image url)'));
    }
  }

  /// Use this method to send audio files,
  /// if you want Telegram clients to display them in the music player.
  /// Your audio must be in the .mp3 format. On success, the sent [Message] is returned.
  /// Bots can currently send audio files of up to 50 MB in size,
  /// this limit may be changed in the future.
  ///
  /// For sending voice messages, use the [sendVoice] method instead.
  ///
  /// https://core.telegram.org/bots/api#sendaudio
  ///
  /// [Message]: https://core.telegram.org/bots/api#message
  /// [sendVoice]: https://core.telegram.org/bots/api#sendvoice
  Future<Message> sendAudio(int chat_id, dynamic audio,
      {String caption,
      String parse_mode,
      int duration,
      String performer,
      String title,
      dynamic thumb,
      bool disable_notification,
      int reply_to_message_id,
      ReplyMarkup reply_markup}) async {
    String requestUrl = '${_baseUrl}${_token}/sendAudio';
    Map<String, dynamic> body = {
      'chat_id': chat_id,
      'caption': caption ?? '',
      'parse_mode': parse_mode ?? '',
      'duration': duration ?? '',
      'performer': performer ?? '',
      'title': title ?? '',
      'disable_notification': disable_notification ?? '',
      'reply_to_message_id': reply_to_message_id ?? '',
      'reply_markup': reply_markup == null ? '' : jsonEncode(reply_markup)
    };

    if (audio is io.File) {
      // filename cannot be empty to post to Telegram server
      List<http.MultipartFile> files = List.filled(
          1,
          http.MultipartFile('audio', audio.openRead(), audio.lengthSync(),
              filename: '${audio.lengthSync()}'));
      if (thumb != null) {
        if (thumb is io.File) {
          files.add(http.MultipartFile(
              'thumb', thumb.openRead(), thumb.lengthSync(),
              filename: '${thumb.lengthSync()}'));
        } else if (thumb is String) {
          body.addAll({'thumb': thumb});
        } else {
          return Future.error(TelegramException(
              'Attribute \'thumb\' can only be either io.File or String (Telegram file_id or image url)'));
        }
      }
      return Message.fromJson(
          await _client.httpMultipartPost(requestUrl, files, body: body));
    } else if (audio is String) {
      body.addAll({'audio': audio});
      if (thumb != null) {
        if (thumb is io.File) {
          return Message.fromJson(await _client.httpMultipartPost(
              requestUrl,
              List.filled(
                  1,
                  http.MultipartFile(
                      'thumb', thumb.openRead(), thumb.lengthSync(),
                      filename: '${thumb.lengthSync()}')),
              body: body));
        } else if (thumb is String) {
          body.addAll({'thumb': thumb});
        } else {
          return Future.error(TelegramException(
              'Attribute \'thumb\' can only be either io.File or String (Telegram file_id or image url)'));
        }
      }
      return Message.fromJson(await _client.httpPost(requestUrl, body: body));
    } else {
      return Future.error(TelegramException(
          'Attribute \'audio\' can only be either io.File or String (Telegram file_id or image url)'));
    }
  }

  /// Use this method to send general files. On success, the sent [Message] is returned.
  /// Bots can currently send files of any type of up to 50 MB in size,
  /// this limit may be changed in the future.
  ///
  /// https://core.telegram.org/bots/api#senddocument
  ///
  /// [Message]: https://core.telegram.org/bots/api#message
  Future<Message> sendDocument(int chat_id, dynamic document,
      {dynamic thumb,
      String caption,
      String parse_mode,
      bool disable_notification,
      int reply_to_message_id,
      ReplyMarkup reply_markup}) async {
    String requestUrl = '${_baseUrl}${_token}/sendDocument';
    Map<String, dynamic> body = {
      'chat_id': chat_id,
      'caption': caption ?? '',
      'parse_mode': parse_mode ?? '',
      'disable_notification': disable_notification ?? '',
      'reply_to_message_id': reply_to_message_id ?? '',
      'reply_markup': reply_markup == null ? '' : jsonEncode(reply_markup)
    };

    if (document is io.File) {
      // filename cannot be empty to post to Telegram server
      List<http.MultipartFile> files = List.filled(
          1,
          http.MultipartFile(
              'document', document.openRead(), document.lengthSync(),
              filename: '${document.lengthSync()}'));
      if (thumb != null) {
        if (thumb is io.File) {
          files.add(http.MultipartFile(
              'thumb', thumb.openRead(), thumb.lengthSync(),
              filename: '${thumb.lengthSync()}'));
        } else if (thumb is String) {
          body.addAll({'thumb': thumb});
        } else {
          return Future.error(TelegramException(
              'Attribute \'thumb\' can only be either io.File or String (Telegram file_id or image url)'));
        }
      }
      return Message.fromJson(
          await _client.httpMultipartPost(requestUrl, files, body: body));
    } else if (document is String) {
      body.addAll({'document': document});
      if (thumb != null) {
        if (thumb is io.File) {
          return Message.fromJson(await _client.httpMultipartPost(
              requestUrl,
              List.filled(
                  1,
                  http.MultipartFile(
                      'thumb', thumb.openRead(), thumb.lengthSync(),
                      filename: '${thumb.lengthSync()}')),
              body: body));
        } else if (thumb is String) {
          body.addAll({'thumb': thumb});
        } else {
          return Future.error(TelegramException(
              'Attribute \'thumb\' can only be either io.File or String (Telegram file_id or image url)'));
        }
      }
      return Message.fromJson(await _client.httpPost(requestUrl, body: body));
    } else {
      return Future.error(TelegramException(
          'Attribute \'document\' can only be either io.File or String (Telegram file_id or image url)'));
    }
  }

  /// Use this method to send video files,
  /// Telegram clients support mp4 videos (other formats may be sent as [Document]).
  /// On success, the sent [Message] is returned.
  /// Bots can currently send video files of up to 50 MB in size,
  /// this limit may be changed in the future.
  ///
  /// https://core.telegram.org/bots/api#sendvideo
  ///
  /// [Document]: https://core.telegram.org/bots/api#document
  /// [Message]: https://core.telegram.org/bots/api#message
  Future<Message> sendVideo(int chat_id, dynamic video,
      {int duration,
      int width,
      int height,
      dynamic thumb,
      String caption,
      String parse_mode,
      bool supports_streaming,
      bool disable_notification,
      int reply_to_message_id,
      ReplyMarkup reply_markup}) async {
    String requestUrl = '${_baseUrl}${_token}/sendVideo';
    Map<String, dynamic> body = {
      'chat_id': chat_id,
      'duration': duration ?? '',
      'width': width ?? '',
      'height': height ?? '',
      'caption': caption ?? '',
      'parse_mode': parse_mode ?? '',
      'supports_streaming': supports_streaming ?? '',
      'disable_notification': disable_notification ?? '',
      'reply_to_message_id': reply_to_message_id ?? '',
      'reply_markup': reply_markup == null ? '' : jsonEncode(reply_markup)
    };

    if (video is io.File) {
      // filename cannot be empty to post to Telegram server
      List<http.MultipartFile> files = List.filled(
          1,
          http.MultipartFile('video', video.openRead(), video.lengthSync(),
              filename: '${video.lengthSync()}'));
      if (thumb != null) {
        if (thumb is io.File) {
          files.add(http.MultipartFile(
              'thumb', thumb.openRead(), thumb.lengthSync(),
              filename: '${thumb.lengthSync()}'));
        } else if (thumb is String) {
          body.addAll({'thumb': thumb});
        } else {
          return Future.error(TelegramException(
              'Attribute \'thumb\' can only be either io.File or String (Telegram file_id or image url)'));
        }
      }
      return Message.fromJson(
          await _client.httpMultipartPost(requestUrl, files, body: body));
    } else if (video is String) {
      body.addAll({'video': video});
      if (thumb != null) {
        if (thumb is io.File) {
          return Message.fromJson(await _client.httpMultipartPost(
              requestUrl,
              List.filled(
                  1,
                  http.MultipartFile(
                      'thumb', thumb.openRead(), thumb.lengthSync(),
                      filename: '${thumb.lengthSync()}')),
              body: body));
        } else if (thumb is String) {
          body.addAll({'thumb': thumb});
        } else {
          return Future.error(TelegramException(
              'Attribute \'thumb\' can only be either io.File or String (Telegram file_id or image url)'));
        }
      }
      return Message.fromJson(await _client.httpPost(requestUrl, body: body));
    } else {
      return Future.error(TelegramException(
          'Attribute \'video\' can only be either io.File or String (Telegram file_id or image url)'));
    }
  }

  /// Use this method to send animation files (GIF or H.264/MPEG-4 AVC video without sound).
  /// On success, the sent [Message] is returned.
  /// Bots can currently send animation files of up to 50 MB in size,
  /// this limit may be changed in the future.
  ///
  /// https://core.telegram.org/bots/api#sendanimation
  ///
  /// [Message]: https://core.telegram.org/bots/api#message
  Future<Message> sendAnimation(int chat_id, dynamic animation,
      {int duration,
      int width,
      int height,
      dynamic thumb,
      String caption,
      String parse_mode,
      bool disable_notification,
      int reply_to_message_id,
      ReplyMarkup reply_markup}) async {
    String requestUrl = '${_baseUrl}${_token}/sendAnimation';
    Map<String, dynamic> body = {
      'chat_id': chat_id,
      'duration': duration ?? '',
      'width': width ?? '',
      'height': height ?? '',
      'caption': caption ?? '',
      'parse_mode': parse_mode ?? '',
      'disable_notification': disable_notification ?? '',
      'reply_to_message_id': reply_to_message_id ?? '',
      'reply_markup': reply_markup == null ? '' : jsonEncode(reply_markup)
    };

    if (animation is io.File) {
      // filename cannot be empty to post to Telegram server
      List<http.MultipartFile> files = List.filled(
          1,
          http.MultipartFile(
              'animation', animation.openRead(), animation.lengthSync(),
              filename: '${animation.lengthSync()}'));
      if (thumb != null) {
        if (thumb is io.File) {
          files.add(http.MultipartFile(
              'thumb', thumb.openRead(), thumb.lengthSync(),
              filename: '${thumb.lengthSync()}'));
        } else if (thumb is String) {
          body.addAll({'thumb': thumb});
        } else {
          return Future.error(TelegramException(
              'Attribute \'thumb\' can only be either io.File or String (Telegram file_id or image url)'));
        }
      }
      return Message.fromJson(
          await _client.httpMultipartPost(requestUrl, files, body: body));
    } else if (animation is String) {
      body.addAll({'video': animation});
      if (thumb != null) {
        if (thumb is io.File) {
          return Message.fromJson(await _client.httpMultipartPost(
              requestUrl,
              List.filled(
                  1,
                  http.MultipartFile(
                      'thumb', thumb.openRead(), thumb.lengthSync(),
                      filename: '${thumb.lengthSync()}')),
              body: body));
        } else if (thumb is String) {
          body.addAll({'thumb': thumb});
        } else {
          return Future.error(TelegramException(
              'Attribute \'thumb\' can only be either io.File or String (Telegram file_id or image url)'));
        }
      }
      return Message.fromJson(await _client.httpPost(requestUrl, body: body));
    } else {
      return Future.error(TelegramException(
          'Attribute \'animation\' can only be either io.File or String (Telegram file_id or image url)'));
    }
  }

  /// Use this method to send audio files,
  /// if you want Telegram clients to display the file as a playable voice message.
  /// For this to work, your audio must be in an .ogg file encoded with OPUS
  /// (other formats may be sent as [Audio] or [Document]).
  /// On success, the sent [Message] is returned.
  /// Bots can currently send voice messages of up to 50 MB in size,
  /// this limit may be changed in the future.
  ///
  /// https://core.telegram.org/bots/api#sendvoice
  ///
  /// [Audio]: https://core.telegram.org/bots/api#audio
  /// [Document]: https://core.telegram.org/bots/api#document
  /// [Message]: https://core.telegram.org/bots/api#message
  Future<Message> sendVoice(int chat_id, dynamic voice,
      {String caption,
      String parse_mode,
      int duration,
      bool disable_notification,
      int reply_to_message_id,
      ReplyMarkup reply_markup}) async {
    String requestUrl = '${_baseUrl}${_token}/sendVoice';
    Map<String, dynamic> body = {
      'chat_id': chat_id,
      'caption': caption ?? '',
      'parse_mode': parse_mode ?? '',
      'duration': duration ?? '',
      'disable_notification': disable_notification ?? '',
      'reply_to_message_id': reply_to_message_id ?? '',
      'reply_markup': reply_markup == null ? '' : jsonEncode(reply_markup)
    };

    if (voice is io.File) {
      // filename cannot be empty to post to Telegram server
      List<http.MultipartFile> files = List.filled(
          1,
          http.MultipartFile('voice', voice.openRead(), voice.lengthSync(),
              filename: '${voice.lengthSync()}'));
      return Message.fromJson(
          await _client.httpMultipartPost(requestUrl, files, body: body));
    } else if (voice is String) {
      body.addAll({'voice': voice});
      return Message.fromJson(await _client.httpPost(requestUrl, body: body));
    } else {
      return Future.error(TelegramException(
          'Attribute \'voice\' can only be either io.File or String (Telegram file_id or image url)'));
    }
  }

  /// As of [v.4.0], Telegram clients support rounded square mp4 videos of up to 1 minute long.
  /// Use this method to send video [messages]. On success, the sent Message is returned.
  ///
  /// https://core.telegram.org/bots/api#sendvideonote
  ///
  /// [v.4.0]: https://telegram.org/blog/video-messages-and-telescope
  /// [messages]: https://core.telegram.org/bots/api#message
  Future<Message> sendVideoNote(int chat_id, dynamic video_note,
      {int duration,
      int length,
      dynamic thumb,
      bool disable_notification,
      int reply_to_message_id,
      ReplyMarkup reply_markup}) async {
    String requestUrl = '${_baseUrl}${_token}/sendVideoNote';
    Map<String, dynamic> body = {
      'chat_id': chat_id,
      'duration': duration ?? '',
      'length': length ?? '',
      'disable_notification': disable_notification ?? '',
      'reply_to_message_id': reply_to_message_id ?? '',
      'reply_markup': reply_markup == null ? '' : jsonEncode(reply_markup)
    };

    if (video_note is io.File) {
      // filename cannot be empty to post to Telegram server
      List<http.MultipartFile> files = List.filled(
          1,
          http.MultipartFile(
              'video_note', video_note.openRead(), video_note.lengthSync(),
              filename: '${video_note.lengthSync()}'));
      if (thumb != null) {
        if (thumb is io.File) {
          files.add(http.MultipartFile(
              'thumb', thumb.openRead(), thumb.lengthSync(),
              filename: '${thumb.lengthSync()}'));
        } else if (thumb is String) {
          body.addAll({'thumb': thumb});
        } else {
          return Future.error(TelegramException(
              'Attribute \'thumb\' can only be either io.File or String (Telegram file_id or image url)'));
        }
      }
      return Message.fromJson(
          await _client.httpMultipartPost(requestUrl, files, body: body));
    } else if (video_note is String) {
      body.addAll({'video_note': video_note});
      if (thumb != null) {
        if (thumb is io.File) {
          return Message.fromJson(await _client.httpMultipartPost(
              requestUrl,
              List.filled(
                  1,
                  http.MultipartFile(
                      'thumb', thumb.openRead(), thumb.lengthSync(),
                      filename: '${thumb.lengthSync()}')),
              body: body));
        } else if (thumb is String) {
          body.addAll({'thumb': thumb});
        } else {
          return Future.error(TelegramException(
              'Attribute \'thumb\' can only be either io.File or String (Telegram file_id or image url)'));
        }
      }
      return Message.fromJson(await _client.httpPost(requestUrl, body: body));
    } else {
      return Future.error(TelegramException(
          'Attribute \'video_note\' can only be either io.File or String (Telegram file_id or image url)'));
    }
  }

  // TODO: #9
  // ! media can only take file_id or url
  // * need to implement POST multipart/form-data uploading files
  // * or even mixed input
  /// Use this method to send a group of photos or videos as an album.
  /// On success, an array of the sent [Messages] is returned.
  ///
  /// https://core.telegram.org/bots/api#sendmediagroup
  ///
  /// [messages]: https://core.telegram.org/bots/api#message
  Future<List<Message>> sendMediaGroup(int chat_id, List<InputMedia> media,
      {bool disable_notification, int reply_to_message_id}) async {
    String requestUrl = '${_baseUrl}${_token}/sendMediaGroup';
    Map<String, dynamic> body = {
      'chat_id': chat_id,
      'media': jsonEncode(media),
      'disable_notification': disable_notification ?? '',
      'reply_to_message_id': reply_to_message_id ?? ''
    };
    return (await _client.httpPost(requestUrl, body: body))
        .map<Message>((message) => Message.fromJson(message))
        .toList();
  }

  /// Use this method to send point on the map. On success, the sent [Message] is returned.
  ///
  /// https://core.telegram.org/bots/api#sendlocation
  ///
  /// [messages]: https://core.telegram.org/bots/api#message
  Future<Message> sendLocation(int chat_id, double latitude, double longitude,
      {int live_period,
      bool disable_notification,
      int reply_to_message_id,
      ReplyMarkup reply_markup}) async {
    String requestUrl = '${_baseUrl}${_token}/sendLocation';
    Map<String, dynamic> body = {
      'chat_id': chat_id,
      'latitude': latitude,
      'longitude': longitude,
      'disable_notification': disable_notification ?? '',
      'reply_to_message_id': reply_to_message_id ?? '',
      'reply_markup': reply_markup == null ? '' : jsonEncode(reply_markup)
    };
    return Message.fromJson(await _client.httpPost(requestUrl, body: body));
  }

  /// Use this method to edit live location messages sent by the bot or via the bot
  /// (for [inline bots]).
  /// A location can be edited until its *live_period* expires or editing is explicitly disabled by a
  /// call to [stopMessageLiveLocation].
  /// On success, if the edited message was sent by the bot,
  /// the edited [Message] is returned, otherwise *True* is returned.
  ///
  /// https://core.telegram.org/bots/api#editmessagelivelocation
  ///
  /// [inline bots]: https://core.telegram.org/bots/api#inline-mode
  /// [stopMessageLiveLocation]: https://core.telegram.org/bots/api#stopmessagelivelocation
  /// [Message]: https://core.telegram.org/bots/api#message
  Future<Message> editMessageLiveLocation(double latitude, double longitude,
      {int chat_id,
      int message_id,
      String inline_message_id,
      ReplyMarkup reply_markup}) async {
    if (inline_message_id == null && (chat_id == null || message_id == null)) {
      return Future.error(TelegramException(
          'Require either \'chat_id\' and \'message_id\', or \'inline_message_id\''));
    }
    String requestUrl = '${_baseUrl}${_token}/editMessageLiveLocation';
    Map<String, dynamic> body = {
      'latitude': latitude,
      'longitude': longitude,
      'chat_id': chat_id ?? '',
      'message_id': message_id ?? '',
      'inline_message_id': inline_message_id ?? '',
      'reply_markup': reply_markup == null ? '' : jsonEncode(reply_markup)
    };
    return Message.fromJson(await _client.httpPost(requestUrl, body: body));
  }

  /// Use this method to stop updating a live location message sent by the bot or via the bot
  /// (for [inline bots]) before *live_period* expires.
  /// On success, if the message was sent by the bot, the sent [Message] is returned,
  /// otherwise *True* is returned.
  ///
  /// https://core.telegram.org/bots/api#stopmessagelivelocation
  ///
  /// [inline bots]: https://core.telegram.org/bots/api#inline-mode
  /// [Message]: https://core.telegram.org/bots/api#message
  Future<Message> stopMessageLiveLocation(
      {int chat_id,
      int message_id,
      String inline_message_id,
      ReplyMarkup reply_markup}) async {
    if (inline_message_id == null && (chat_id == null || message_id == null)) {
      return Future.error(TelegramException(
          'Require either \'chat_id\' and \'message_id\', or \'inline_message_id\''));
    }
    String requestUrl = '${_baseUrl}${_token}/stopMessageLiveLocation';
    Map<String, dynamic> body = {
      'chat_id': chat_id ?? '',
      'message_id': message_id ?? '',
      'inline_message_id': inline_message_id ?? '',
      'reply_markup': reply_markup == null ? '' : jsonEncode(reply_markup)
    };
    return Message.fromJson(await _client.httpPost(requestUrl, body: body));
  }

  /// Use this method to send information about a venue. On success, the sent [Message] is returned.
  ///
  /// https://core.telegram.org/bots/api#sendvenue
  ///
  /// [Message]: https://core.telegram.org/bots/api#message
  Future<Message> sendVenue(int chat_id, double latitude, double longitude,
      String title, String address,
      {String foursquare_id,
      String foursquare_type,
      bool disable_notification,
      int reply_to_message_id,
      ReplyMarkup reply_markup}) async {
    String requestUrl = '${_baseUrl}${_token}/sendVenue';
    Map<String, dynamic> body = {
      'chat_id': chat_id,
      'latitude': latitude,
      'longitude': longitude,
      'title': title,
      'address': address,
      'foursquare_id': foursquare_id ?? '',
      'foursquare_type': foursquare_type ?? '',
      'disable_notification': disable_notification ?? '',
      'reply_to_message_id': reply_to_message_id ?? '',
      'reply_markup': reply_markup == null ? '' : jsonEncode(reply_markup)
    };
    return Message.fromJson(await _client.httpPost(requestUrl, body: body));
  }

  /// Use this method to send phone contacts. On success, the sent [Message] is returned.
  ///
  /// https://core.telegram.org/bots/api#sendcontact
  ///
  /// [Message]: https://core.telegram.org/bots/api#message
  Future<Message> sendContact(
      int chat_id, String phone_number, String first_name,
      {String last_name,
      String vcard,
      bool disable_notification,
      int reply_to_message_id,
      ReplyMarkup reply_markup}) async {
    String requestUrl = '${_baseUrl}${_token}/sendContact';
    Map<String, dynamic> body = {
      'chat_id': chat_id,
      'phone_number': phone_number,
      'first_name': first_name,
      'last_name': last_name ?? '',
      'vcard': vcard ?? '',
      'disable_notification': disable_notification ?? '',
      'reply_to_message_id': reply_to_message_id ?? '',
      'reply_markup': reply_markup == null ? '' : jsonEncode(reply_markup)
    };
    return Message.fromJson(await _client.httpPost(requestUrl, body: body));
  }

  /// Use this method to send a native poll. A native poll can't be sent to a private chat.
  /// On success, the sent [Message] is returned.
  ///
  /// https://core.telegram.org/bots/api#sendpoll
  ///
  /// [Message]: https://core.telegram.org/bots/api#message
  Future<Message> sendPoll(int chat_id, String question, List<String> options,
      {bool disable_notification,
      int reply_to_message_id,
      ReplyMarkup reply_markup}) async {
    String requestUrl = '${_baseUrl}${_token}/sendPoll';
    Map<String, dynamic> body = {
      'chat_id': chat_id,
      'question': question,
      'options': options,
      'disable_notification': disable_notification ?? '',
      'reply_to_message_id': reply_to_message_id ?? '',
      'reply_markup': reply_markup == null ? '' : jsonEncode(reply_markup)
    };
    return Message.fromJson(await _client.httpPost(requestUrl, body: body));
  }

  /// Use this method when you need to tell the user that something is happening on the bot's side.
  /// The status is set for 5 seconds or less
  /// (when a message arrives from your bot, Telegram clients clear its typing status).
  /// Returns *True* on success.
  ///
  /// Example: The [ImageBot] needs some time to process a request and upload the image.
  /// Instead of sending a text message along the lines of “Retrieving image, please wait…”,
  /// the bot may use [sendChatAction] with action = upload_photo.
  /// The user will see a “sending photo” status for the bot.
  ///
  /// We only recommend using this method when a response from the bot will take a **noticeable**
  /// amount of time to arrive.
  ///
  /// https://core.telegram.org/bots/api#sendchataction
  ///
  /// [ImageBot]: https://t.me/imagebot
  /// [sendChatAction]: https://core.telegram.org/bots/api#sendchataction
  Future<bool> sendChatAction(int chat_id, String action) async {
    String requestUrl = '${_baseUrl}${_token}/sendChatAction';
    Map<String, dynamic> body = {'chat_id': chat_id, 'action': action};
    return await _client.httpPost(requestUrl, body: body);
  }

  /// Use this method to get a list of profile pictures for a user. Returns a [UserProfilePhotos] object.
  ///
  /// https://core.telegram.org/bots/api#getuserprofilephotos
  ///
  /// [UserProfilePhotos]: https://core.telegram.org/bots/api#userprofilephotos
  Future<UserProfilePhotos> getUserProfilePhotos(int user_id,
      {int offset, int limit}) async {
    String requestUrl = '${_baseUrl}${_token}/getUserProfilePhotos';
    Map<String, dynamic> body = {
      'user_id': user_id,
      'offset': offset ?? '',
      'limit': limit ?? ''
    };
    return UserProfilePhotos.fromJson(
        await _client.httpPost(requestUrl, body: body));
  }

  /// Use this method to get basic info about a file and prepare it for downloading.
  /// For the moment, bots can download files of up to 20MB in size. On success,
  /// a [File] object is returned. The file can then be downloaded via the link
  /// `https://api.telegram.org/file/bot<token>/<file_path>`,
  /// where [<file_path>] is taken from the response.
  /// It is guaranteed that the link will be valid for at least 1 hour.
  /// When the link expires, a one can be requested by calling [getFile] again.
  ///
  /// **Note:** This function may not preserve the original file name and MIME type.
  /// You should save the file's MIME type and name (if available) when the File object is received.
  ///
  /// https://core.telegram.org/bots/api#getfile
  ///
  /// [File]: https://core.telegram.org/bots/api#file
  /// [getFile]: https://core.telegram.org/bots/api#getfile
  Future<File> getFile(String file_id) async {
    String requestUrl = '${_baseUrl}${_token}/getFile';
    Map<String, dynamic> body = {'file_id': file_id};
    return File.fromJson(await _client.httpPost(requestUrl, body: body));
  }

  /// Use this method to kick a user from a group, a supergroup or a channel.
  /// In the case of supergroups and channels,
  /// the user will not be able to return to the group on their own using invite links, etc.,
  /// unless [unbanned] first.
  /// The bot must be an administrator in the chat for this to work and must have the appropriate
  /// admin rights. Returns *True* on success.
  ///
  /// Note: In regular groups (non-supergroups),
  /// this method will only work if the ‘All Members Are Admins’ setting is off in the target group.
  /// Otherwise members may only be removed by the group's creator or by the member that added them.
  ///
  /// https://core.telegram.org/bots/api#kickchatmember
  ///
  /// [unbanned]: https://core.telegram.org/bots/api#unbanchatmember
  Future<bool> kickChatMember(int chat_id, int user_id,
      {int until_date}) async {
    String requestUrl = '${_baseUrl}${_token}/kickChatMember';
    Map<String, dynamic> body = {
      'chat_id': chat_id,
      'user_id': user_id,
      'until_date': until_date ?? ''
    };
    return await _client.httpPost(requestUrl, body: body);
  }

  /// Use this method to unban a previously kicked user in a supergroup or channel.
  /// The user will **not** return to the group or channel automatically,
  /// but will be able to join via link, etc. The bot must be an administrator for this to work.
  /// Returns *True* on success.
  ///
  /// https://core.telegram.org/bots/api#unbanchatmember
  Future<bool> unbanChatMember(int chat_id, int user_id) async {
    String requestUrl = '${_baseUrl}${_token}/unbanChatMember';
    Map<String, dynamic> body = {'chat_id': chat_id, 'user_id': user_id};
    return await _client.httpPost(requestUrl, body: body);
  }

  /// Use this method to restrict a user in a supergroup.
  /// The bot must be an administrator in the supergroup for this to work and must have the
  /// appropriate admin rights.
  /// Pass *True* for all boolean parameters to lift restrictions from a user.
  /// Returns *True* on success.
  ///
  /// https://core.telegram.org/bots/api#restrictchatmember
  Future<bool> restrictChatMember(int chat_id, int user_id,
      {int until_date,
      bool can_send_messages,
      bool can_send_media_messages,
      bool can_send_other_messages,
      bool can_add_web_page_previews}) async {
    String requestUrl = '${_baseUrl}${_token}/unbanChatMember';
    Map<String, dynamic> body = {
      'chat_id': chat_id,
      'user_id': user_id,
      'until_date': until_date ?? '',
      'can_send_messages': can_send_messages ?? '',
      'can_send_media_messages': can_send_media_messages ?? '',
      'can_send_other_messages': can_send_other_messages ?? '',
      'can_add_web_page_previews': can_add_web_page_previews ?? ''
    };
    return await _client.httpPost(requestUrl, body: body);
  }

  /// Use this method to promote or demote a user in a supergroup or a channel.
  /// The bot must be an administrator in the chat for this to work and must have the appropriate
  /// admin rights.
  /// Pass *False* for all boolean parameters to demote a user. Returns *True* on success.
  ///
  /// https://core.telegram.org/bots/api#promotechatmember
  Future<bool> promoteChatMember(int chat_id, int user_id,
      {bool can_change_info,
      bool can_post_messages,
      bool can_edit_messages,
      bool can_delete_messages,
      bool can_invite_users,
      bool can_restrict_members,
      bool can_pin_messages,
      bool can_promote_members}) async {
    String requestUrl = '${_baseUrl}${_token}/promoteChatMember';
    Map<String, dynamic> body = {
      'chat_id': chat_id,
      'user_id': user_id,
      'can_change_info': can_change_info ?? '',
      'can_post_messages': can_post_messages ?? '',
      'can_edit_messages': can_edit_messages ?? '',
      'can_delete_messages': can_delete_messages ?? '',
      'can_invite_users': can_invite_users ?? '',
      'can_restrict_members': can_restrict_members ?? '',
      'can_pin_messages': can_pin_messages ?? '',
      'can_promote_members': can_promote_members ?? ''
    };
    return await _client.httpPost(requestUrl, body: body);
  }

  /// Use this method to generate a invite link for a chat;
  /// any previously generated link is revoked.
  /// The bot must be an administrator in the chat for this to work and must have the appropriate
  /// admin rights. Returns the invite link as *String* on success.
  ///
  /// https://core.telegram.org/bots/api#exportchatinvitelink
  Future<String> exportChatInviteLink(int chat_id) async {
    String requestUrl = '${_baseUrl}${_token}/exportChatInviteLink';
    Map<String, dynamic> body = {'chat_id': chat_id};
    return await _client.httpPost(requestUrl, body: body);
  }

  /// Use this method to set a profile photo for the chat.
  /// Photos can't be changed for private chats.
  /// The bot must be an administrator in the chat for this to work and must have the appropriate
  /// admin rights. Returns *True* on success.
  ///
  /// Note: In regular groups (non-supergroups),
  /// this method will only work if the ‘All Members Are Admins’ setting is off in the target group.
  ///
  /// https://core.telegram.org/bots/api#setchatphoto
  Future<bool> setChatPhoto(int chat_id, io.File photo) async {
    String requestUrl = '${_baseUrl}${_token}/setChatPhoto';
    Map<String, dynamic> body = {'chat_id': chat_id};
    // filename cannot be empty to post to Telegram server
    List<http.MultipartFile> files = List.filled(
        1,
        http.MultipartFile('photo', photo.openRead(), photo.lengthSync(),
            filename: '${photo.lengthSync()}'));
    return await _client.httpMultipartPost(requestUrl, files, body: body);
  }

  /// Use this method to delete a chat photo.
  /// Photos can't be changed for private chats.
  /// The bot must be an administrator in the chat for this to work and must have the appropriate
  /// admin rights. Returns *True* on success.
  ///
  /// Note: In regular groups (non-supergroups),
  /// this method will only work if the ‘All Members Are Admins’ setting is off in the target group.
  ///
  /// https://core.telegram.org/bots/api#deletechatphoto
  Future<bool> deleteChatPhoto(int chat_id) async {
    String requestUrl = '${_baseUrl}${_token}/deleteChatPhoto';
    Map<String, dynamic> body = {'chat_id': chat_id};
    return await _client.httpPost(requestUrl, body: body);
  }

  /// Use this method to change the title of a chat.
  /// Titles can't be changed for private chats.
  /// The bot must be an administrator in the chat for this to work and must have the appropriate
  /// admin rights. Returns *True* on success.
  ///
  /// Note: In regular groups (non-supergroups),
  /// this method will only work if the ‘All Members Are Admins’ setting is off in the target group.
  ///
  /// https://core.telegram.org/bots/api#setchattitle
  Future<bool> setChatTitle(int chat_id, String title) async {
    String requestUrl = '${_baseUrl}${_token}/setChatTitle';
    Map<String, dynamic> body = {'chat_id': chat_id, 'title': title};
    return await _client.httpPost(requestUrl, body: body);
  }

  /// Use this method to change the description of a supergroup or a channel.
  /// The bot must be an administrator in the chat for this to work and must have the appropriate
  /// admin rights. Returns *True* on success.
  ///
  /// https://core.telegram.org/bots/api#setchatdescription
  Future<bool> setChatDescription(int chat_id, {String description}) async {
    String requestUrl = '${_baseUrl}${_token}/setChatDescription';
    Map<String, dynamic> body = {
      'chat_id': chat_id,
      'description': description ?? ''
    };
    return await _client.httpPost(requestUrl, body: body);
  }

  /// Use this method to pin a message in a supergroup or a channel.
  /// The bot must be an administrator in the chat for this to work and must have the
  /// ‘can_pin_messages’ admin right in the supergroup or ‘can_edit_messages’ admin right
  /// in the channel. Returns *True* on success.
  ///
  /// https://core.telegram.org/bots/api#pinchatmessage
  Future<bool> pinChatMessage(int chat_id, int message_id,
      {bool disable_notification}) async {
    String requestUrl = '${_baseUrl}${_token}/pinChatMessage';
    Map<String, dynamic> body = {
      'chat_id': chat_id,
      'message_id': message_id,
      'disable_notification': disable_notification ?? ''
    };
    return await _client.httpPost(requestUrl, body: body);
  }

  /// Use this method to unpin a message in a supergroup or a channel.
  /// The bot must be an administrator in the chat for this to work and must have the
  /// ‘can_pin_messages’ admin right in the supergroup or ‘can_edit_messages’ admin right
  /// in the channel. Returns *True* on success.
  ///
  /// https://core.telegram.org/bots/api#unpinchatmessage
  Future<bool> unpinChatMessage(int chat_id) async {
    String requestUrl = '${_baseUrl}${_token}/unpinChatMessage';
    Map<String, dynamic> body = {'chat_id': chat_id};
    return await _client.httpPost(requestUrl, body: body);
  }

  /// Use this method for your bot to leave a group, supergroup or channel. Returns *True* on success.
  ///
  /// https://core.telegram.org/bots/api#leavechat
  Future<bool> leaveChat(int chat_id) async {
    String requestUrl = '${_baseUrl}${_token}/leaveChat';
    Map<String, dynamic> body = {'chat_id': chat_id};
    return await _client.httpPost(requestUrl, body: body);
  }

  /// Use this method to get up to date information about the chat
  /// (current name of the user for one-on-one conversations,
  /// current username of a user, group or channel, etc.).
  /// Returns a [Chat] object on success.
  ///
  /// https://core.telegram.org/bots/api#getchat
  ///
  /// [Chat]: https://core.telegram.org/bots/api#chat
  Future<Chat> getChat(int chat_id) async {
    String requestUrl = '${_baseUrl}${_token}/getChat';
    Map<String, dynamic> body = {'chat_id': chat_id};
    return Chat.fromJson(await _client.httpPost(requestUrl, body: body));
  }

  /// Use this method to get a list of administrators in a chat.
  /// On success, returns an Array of [ChatMember] objects that contains information about all chat
  /// administrators except other bots.
  /// If the chat is a group or a supergroup and no administrators were appointed,
  /// only the creator will be returned.
  ///
  /// https://core.telegram.org/bots/api#getchatadministrators
  ///
  /// [ChatMember]: https://core.telegram.org/bots/api#chatmember
  Future<List<ChatMember>> getChatAdministrators(int chat_id) async {
    String requestUrl = '${_baseUrl}${_token}/getChatAdministrators';
    Map<String, dynamic> body = {'chat_id': chat_id};
    return (await _client.httpPost(requestUrl, body: body))
        .map<ChatMember>((member) => ChatMember.fromJson(member))
        .toList();
  }

  /// Use this method to get the number of members in a chat. Returns *Int* on success.
  ///
  /// https://core.telegram.org/bots/api#getchatmemberscount
  Future<int> getChatMembersCount(int chat_id) async {
    String requestUrl = '${_baseUrl}${_token}/getChatMembersCount';
    Map<String, dynamic> body = {'chat_id': chat_id};
    return await _client.httpPost(requestUrl, body: body);
  }

  /// Use this method to get information about a member of a chat.
  /// Returns a [ChatMember] object on success.
  ///
  /// https://core.telegram.org/bots/api#getchatmember
  ///
  /// [ChatMember]: https://core.telegram.org/bots/api#chatmember
  Future<ChatMember> getChatMember(int chat_id, int user_id) async {
    String requestUrl = '${_baseUrl}${_token}/getChatMember';
    Map<String, dynamic> body = {'chat_id': chat_id, 'user_id': user_id};
    return ChatMember.fromJson(await _client.httpPost(requestUrl, body: body));
  }

  /// Use this method to set a group sticker set for a supergroup.
  /// The bot must be an administrator in the chat for this to work and must have the appropriate
  /// admin rights.
  /// Use the field *can_set_sticker_set* optionally returned in [getChat] requests to check if the
  /// bot can use this method.
  /// Returns *True* on success.
  ///
  /// https://core.telegram.org/bots/api#setchatstickerset
  ///
  /// [getChat]: https://core.telegram.org/bots/api#getchat
  Future<bool> setChatStickerSet(int chat_id, String sticker_set_name) async {
    String requestUrl = '${_baseUrl}${_token}/setChatStickerSet';
    Map<String, dynamic> body = {
      'chat_id': chat_id,
      'sticker_set_name': sticker_set_name
    };
    return await _client.httpPost(requestUrl, body: body);
  }

  /// Use this method to delete a group sticker set from a supergroup.
  /// The bot must be an administrator in the chat for this to work and must have the appropriate
  /// admin rights.
  /// Use the field *can_set_sticker_set* optionally returned in [getChat] requests to check if the
  /// bot can use this method.
  /// Returns *True* on success.
  ///
  /// https://core.telegram.org/bots/api#deletechatstickerset
  ///
  /// [getChat]: https://core.telegram.org/bots/api#getchat
  Future<bool> deleteChatStickerSet(int chat_id) async {
    String requestUrl = '${_baseUrl}${_token}/deleteChatStickerSet';
    Map<String, dynamic> body = {'chat_id': chat_id};
    return await _client.httpPost(requestUrl, body: body);
  }

  /// Use this method to send answers to callback queries sent from [inline keyboards].
  /// The answer will be displayed to the user as a notification at the top of the chat screen or as
  /// an alert. On success, *True* is returned.
  ///
  /// Alternatively, the user can be redirected to the specified Game URL.
  /// For this option to work, you must first create a game for your bot via [@Botfather]
  /// and accept the terms. Otherwise, you may use links like `t.me/your_bot?start=XXXX`
  /// that open your bot with a parameter.
  ///
  /// https://core.telegram.org/bots/api#answercallbackquery
  ///
  /// [inline keyboards]: https://core.telegram.org/bots#inline-keyboards-and-on-the-fly-updating
  /// [@Botfather]: https://t.me/botfather
  Future<bool> answerCallbackQuery(String callback_query_id,
      {String text, bool show_alert, String url, int cache_time}) async {
    String requestUrl = '${_baseUrl}${_token}/answerCallbackQuery';
    Map<String, dynamic> body = {
      'callback_query_id': callback_query_id,
      'text': text ?? '',
      'show_alert': show_alert ?? '',
      'url': url ?? '',
      'cache_time': cache_time ?? ''
    };
    return await _client.httpPost(requestUrl, body: body);
  }

  /// Use this method to edit text and [game] messages sent by the bot or via the bot
  /// (for [inline bots]).
  /// On success, if edited message is sent by the bot, the edited [Message] is returned,
  /// otherwise *True* is returned.
  ///
  /// https://core.telegram.org/bots/api#editmessagetext
  ///
  /// [game]: https://core.telegram.org/bots/api#games
  /// [inline bots]: https://core.telegram.org/bots/api#inline-mode
  /// [Message]: https://core.telegram.org/bots/api#message
  Future<Message> editMessageText(String text,
      {int chat_id,
      int message_id,
      String inline_message_id,
      String parse_mode,
      bool disable_web_page_preview,
      InlineKeyboardMarkup reply_markup}) async {
    if (inline_message_id == null && (chat_id == null || message_id == null)) {
      return Future.error(TelegramException(
          'Require either \'chat_id\' and \'message_id\', or \'inline_message_id\''));
    }
    String requestUrl = '${_baseUrl}${_token}/editMessageText';
    Map<String, dynamic> body = {
      'chat_id': chat_id ?? '',
      'message_id': message_id ?? '',
      'inline_message_id': inline_message_id ?? '',
      'text': text,
      'parse_mode': parse_mode ?? '',
      'disable_web_page_preview': disable_web_page_preview ?? '',
      'reply_markup': reply_markup == null ? '' : jsonEncode(reply_markup)
    };
    var res = await _client.httpPost(requestUrl, body: body);
    if (res == true) {
      return Future.error(
          TelegramException('Edited message is NOT sent by the bot'));
    } else {
      return Message.fromJson(res);
    }
  }

  /// Use this method to edit captions of messages sent by the bot or via the bot
  /// (for [inline bots]).
  /// On success, if edited message is sent by the bot, the edited [Message] is returned,
  /// otherwise True is returned.
  ///
  /// https://core.telegram.org/bots/api#editmessagecaption
  ///
  /// [inline bots]: https://core.telegram.org/bots/api#inline-mode
  /// [Message]: https://core.telegram.org/bots/api#message
  Future<Message> editMessageCaption(
      {int chat_id,
      int message_id,
      String inline_message_id,
      String caption,
      String parse_mode,
      InlineKeyboardMarkup reply_markup}) async {
    if (inline_message_id == null && (chat_id == null || message_id == null)) {
      return Future.error(TelegramException(
          'Require either \'chat_id\' and \'message_id\', or \'inline_message_id\''));
    }
    String requestUrl = '${_baseUrl}${_token}/editMessageCaption';
    Map<String, dynamic> body = {
      'chat_id': chat_id ?? '',
      'message_id': message_id ?? '',
      'inline_message_id': inline_message_id ?? '',
      'caption': caption ?? '',
      'parse_mode': parse_mode ?? '',
      'reply_markup': reply_markup == null ? '' : jsonEncode(reply_markup)
    };
    var res = await _client.httpPost(requestUrl, body: body);
    if (res == true) {
      return Future.error(
          TelegramException('Edited message is NOT sent by the bot'));
    } else {
      return Message.fromJson(res);
    }
  }

  /// Use this method to edit audio, document, photo, or video messages.
  /// If a message is a part of a message album, then it can be edited only to a photo or a video.
  /// Otherwise, message type can be changed arbitrarily.
  /// When inline message is edited, file can't be uploaded.
  /// Use previously uploaded file via its file_id or specify a URL.
  /// On success, if the edited message was sent by the bot, the edited [Message] is returned,
  /// otherwise *True* is returned.
  ///
  /// https://core.telegram.org/bots/api#editMessageMedia
  ///
  /// [Message]: https://core.telegram.org/bots/api#message
  Future<Message> editMessageMedia(
      {int chat_id,
      int message_id,
      String inline_message_id,
      InputMedia media,
      String parse_mode,
      InlineKeyboardMarkup reply_markup}) async {
    if (inline_message_id == null && (chat_id == null || message_id == null)) {
      return Future.error(TelegramException(
          'Require either \'chat_id\' and \'message_id\', or \'inline_message_id\''));
    }
    String requestUrl = '${_baseUrl}${_token}/editMessageMedia';
    Map<String, dynamic> body = {
      'chat_id': chat_id ?? '',
      'message_id': message_id ?? '',
      'inline_message_id': inline_message_id ?? '',
      'media': media == null ? '' : jsonEncode(media),
      'parse_mode': parse_mode ?? '',
      'reply_markup': reply_markup == null ? '' : jsonEncode(reply_markup)
    };
    var res = await _client.httpPost(requestUrl, body: body);
    if (res == true) {
      return Future.error(
          TelegramException('Edited message is NOT sent by the bot'));
    } else {
      return Message.fromJson(res);
    }
  }

  /// Use this method to edit only the reply markup of messages sent by the bot or via the bot
  /// (for [inline bots]).
  /// On success, if edited message is sent by the bot, the edited [Message] is returned,
  /// otherwise True is returned.
  ///
  /// https://core.telegram.org/bots/api#editmessagereplymarkup
  ///
  /// [inline bots]: https://core.telegram.org/bots/api#inline-mode
  /// [Message]: https://core.telegram.org/bots/api#message
  Future<Message> editMessageReplyMarkup(
      {int chat_id,
      int message_id,
      String inline_message_id,
      InlineKeyboardMarkup reply_markup}) async {
    if (inline_message_id == null && (chat_id == null || message_id == null)) {
      return Future.error(TelegramException(
          'Require either \'chat_id\' and \'message_id\', or \'inline_message_id\''));
    }
    String requestUrl = '${_baseUrl}${_token}/editMessageReplyMarkup';
    Map<String, dynamic> body = {
      'chat_id': chat_id ?? '',
      'message_id': message_id ?? '',
      'inline_message_id': inline_message_id ?? '',
      'reply_markup': reply_markup == null ? '' : jsonEncode(reply_markup)
    };
    var res = await _client.httpPost(requestUrl, body: body);
    if (res == true) {
      return Future.error(
          TelegramException('Edited message is NOT sent by the bot'));
    } else {
      return Message.fromJson(res);
    }
  }

  /// Use this method to stop a poll which was sent by the bot.
  /// On success, the stopped [Poll] with the final results is returned.
  ///
  /// https://core.telegram.org/bots/api#stoppoll
  ///
  /// [Poll]: https://core.telegram.org/bots/api#poll
  Future<Poll> stopPoll(
      int chat_id, int message_id, InlineKeyboardMarkup reply_markup) async {
    String requestUrl = '${_baseUrl}${_token}/stopPoll';
    Map<String, dynamic> body = {
      'chat_id': chat_id,
      'message_id': message_id,
      'reply_markup': reply_markup
    };
    return Poll.fromJson(await _client.httpPost(requestUrl, body: body));
  }

  /// Use this method to delete a message, including service messages, with the following limitations:
  /// * A message can only be deleted if it was sent less than 48 hours ago.
  /// * Bots can delete outgoing messages in groups and supergroups.
  /// * Bots can delete incoming messages in private chats.
  /// * Bots granted can_post_messages permissions can delete outgoing messages in channels.
  /// * If the bot is an administrator of a group, it can delete any message there.
  /// * If the bot has can_delete_messages permission in a supergroup or a channel, it can delete any message there.
  /// Returns *True* on success.
  ///
  /// https://core.telegram.org/bots/api#deletemessage
  Future<bool> deleteMessage(int chat_id, int message_id) async {
    String requestUrl = '${_baseUrl}${_token}/deleteMessage';
    Map<String, dynamic> body = {'chat_id': chat_id, 'message_id': message_id};
    return await _client.httpPost(requestUrl, body: body);
  }

  /// Use this method to send .webp stickers. On success, the sent [Message] is returned.
  ///
  /// https://core.telegram.org/bots/api#sendsticker
  ///
  /// [Message]: https://core.telegram.org/bots/api#message
  Future<Message> sendSticker(int chat_id, dynamic sticker,
      {bool disable_notification,
      int reply_to_message_id,
      ReplyMarkup reply_markup}) async {
    String requestUrl = '${_baseUrl}${_token}/sendSticker';
    Map<String, dynamic> body = {
      'chat_id': chat_id,
      'disable_notification': disable_notification ?? '',
      'reply_to_message_id': reply_to_message_id ?? '',
      'reply_markup': reply_markup == null ? '' : jsonEncode(reply_markup)
    };

    if (sticker is io.File) {
      // filename cannot be empty to post to Telegram server
      List<http.MultipartFile> files = List.filled(
          1,
          http.MultipartFile(
              'sticker', sticker.openRead(), sticker.lengthSync(),
              filename: '${sticker.lengthSync()}'));
      return Message.fromJson(
          await _client.httpMultipartPost(requestUrl, files, body: body));
    } else if (sticker is String) {
      body.addAll({'sticker': sticker});
      return Message.fromJson(await _client.httpPost(requestUrl, body: body));
    } else {
      return Future.error(TelegramException(
          'Attribute \'sticker\' can only be either io.File or String (Telegram file_id or image url)'));
    }
  }

  /// Use this method to get a sticker set. On success, a [StickerSet] object is returned.
  ///
  /// https://core.telegram.org/bots/api#getstickerset
  ///
  /// [StickerSet]: https://core.telegram.org/bots/api#stickerset
  Future<StickerSet> getStickerSet(String name) async {
    String requestUrl = '${_baseUrl}${_token}/getStickerSet';
    Map<String, dynamic> body = {'name': name};
    return StickerSet.fromJson(await _client.httpPost(requestUrl, body: body));
  }

  /// Use this method to upload a .png file with a sticker for later use in
  /// *createNewStickerSet* and *addStickerToSet* methods (can be used multiple times).
  /// Returns the uploaded [File] on success.
  ///
  /// https://core.telegram.org/bots/api#uploadstickerfile
  ///
  /// [File]: https://core.telegram.org/bots/api#file
  Future<File> uploadStickerFile(int user_id, io.File png_sticker) async {
    String requestUrl = '${_baseUrl}${_token}/uploadStickerFile';
    Map<String, dynamic> body = {'user_id': user_id};
    // filename cannot be empty to post to Telegram server
    List<http.MultipartFile> files = List.filled(
        1,
        http.MultipartFile(
            'png_sticker', png_sticker.openRead(), png_sticker.lengthSync(),
            filename: '${png_sticker.lengthSync()}'));
    return File.fromJson(
        await _client.httpMultipartPost(requestUrl, files, body: body));
  }

  /// Use this method to create sticker set owned by a user.
  /// The bot will be able to edit the created sticker set.
  /// Returns *True* on success.
  ///
  /// https://core.telegram.org/bots/api#createnewstickerset
  Future<bool> createNewStickerSet(int user_id, String name, String title,
      dynamic png_sticker, String emojis,
      {bool contains_masks, MaskPosition mask_position}) async {
    String requestUrl = '${_baseUrl}${_token}/createNewStickerSet';
    User botInfo = await getMe();
    Map<String, dynamic> body = {
      'user_id': user_id,
      'name': '${name}_by_${botInfo.username}',
      'title': title,
      'emojis': emojis,
      'contains_masks': contains_masks ?? '',
      'mask_position': mask_position == null ? '' : jsonEncode(mask_position)
    };

    if (png_sticker is io.File) {
      // filename cannot be empty to post to Telegram server
      List<http.MultipartFile> files = List.filled(
          1,
          http.MultipartFile(
              'png_sticker', png_sticker.openRead(), png_sticker.lengthSync(),
              filename: '${png_sticker.lengthSync()}'));
      return await _client.httpMultipartPost(requestUrl, files, body: body);
    } else if (png_sticker is String) {
      body.addAll({'png_sticker': png_sticker});
      return await _client.httpPost(requestUrl, body: body);
    } else {
      return Future.error(TelegramException(
          'Attribute \'png_sticker\' can only be either io.File or String (Telegram file_id or image url)'));
    }
  }

  /// Use this method to add a sticker to a set created by the bot.
  /// Returns *True* on success.
  ///
  /// https://core.telegram.org/bots/api#addstickertoset
  Future<bool> addStickerToSet(
      int user_id, String name, io.File png_sticker, String emojis,
      {MaskPosition mask_position}) async {
    String requestUrl = '${_baseUrl}${_token}/addStickerToSet';
    Map<String, dynamic> body = {
      'user_id': user_id,
      'name': name,
      'emojis': emojis,
      'mask_position': mask_position == null ? '' : jsonEncode(mask_position)
    };

    if (png_sticker is io.File) {
      // filename cannot be empty to post to Telegram server
      List<http.MultipartFile> files = List.filled(
          1,
          http.MultipartFile(
              'png_sticker', png_sticker.openRead(), png_sticker.lengthSync(),
              filename: '${png_sticker.lengthSync()}'));
      return await _client.httpMultipartPost(requestUrl, files, body: body);
    } else if (png_sticker is String) {
      body.addAll({'png_sticker': png_sticker});
      return await _client.httpPost(requestUrl, body: body);
    } else {
      return Future.error(TelegramException(
          'Attribute \'png_sticker\' can only be either io.File or String (Telegram file_id or image url)'));
    }
  }

  /// Use this method to move a sticker in a set created by the bot to a specific position.
  /// Returns *True* on success.
  ///
  /// https://core.telegram.org/bots/api#setstickerpositioninset
  Future<bool> setStickerPositionInSet(String sticker, int position) async {
    String requestUrl = '${_baseUrl}${_token}/setStickerPositionInSet';
    Map<String, dynamic> body = {'sticker': sticker, 'position': position};
    return await _client.httpPost(requestUrl, body: body);
  }

  /// Use this method to delete a sticker from a set created by the bot.
  /// Returns *True* on success.
  ///
  /// https://core.telegram.org/bots/api#deletestickerfromset
  Future<bool> deleteStickerFromSet(String sticker) async {
    String requestUrl = '${_baseUrl}${_token}/deleteStickerFromSet';
    Map<String, dynamic> body = {'sticker': sticker};
    return await _client.httpPost(requestUrl, body: body);
  }

  /// Use this method to send answers to an inline query.
  /// On success, *True* is returned.
  /// No more than **50** results per query are allowed.
  ///
  /// https://core.telegram.org/bots/api#answerinlinequery
  Future<bool> answerInlineQuery(
      String inline_query_id, List<InlineQueryResult> results,
      {int cache_time,
      bool is_personal,
      String next_offset,
      String switch_pm_text,
      String switch_pm_parameter}) async {
    String requestUrl = '${_baseUrl}${_token}/answerInlineQuery';
    Map<String, dynamic> body = {
      'inline_query_id': inline_query_id,
      'results': jsonEncode(results),
      'cache_time': cache_time ?? '',
      'is_personal': is_personal ?? '',
      'next_offset': next_offset ?? '',
      'switch_pm_text': switch_pm_text ?? '',
      'switch_pm_parameter': switch_pm_parameter ?? ''
    };
    return await _client.httpPost(requestUrl, body: body);
  }

  /// Use this method to send invoices. On success, the sent [Message] is returned.
  ///
  /// https://core.telegram.org/bots/api#sendinvoice
  ///
  /// [Message]: https://core.telegram.org/bots/api#message
  Future<Message> sendInvoice(
      int chat_id,
      String title,
      String description,
      String payload,
      String provider_token,
      String start_parameter,
      String currency,
      List<LabeledPrice> prices,
      {String provider_data,
      String photo_url,
      int photo_size,
      int photo_width,
      int photo_height,
      bool need_name,
      bool need_phone_number,
      bool need_email,
      bool need_shipping_address,
      bool send_phone_number_to_provider,
      bool send_email_to_provider,
      bool is_flexible,
      bool disable_notification,
      int reply_to_message_id,
      InlineKeyboardMarkup reply_markup}) async {
    String requestUrl = '${_baseUrl}${_token}/sendInvoice';
    Map<String, dynamic> body = {
      'chat_id': chat_id,
      'title': title,
      'description': description,
      'payload': payload,
      'provider_token': provider_token,
      'start_parameter': start_parameter,
      'currency': currency,
      'prices': jsonEncode(prices),
      'provider_data': provider_data ?? '',
      'photo_url': photo_url ?? '',
      'photo_size': photo_size ?? '',
      'photo_width': photo_width ?? '',
      'photo_height': photo_height ?? '',
      'need_name': need_name ?? '',
      'need_phone_number': need_phone_number ?? '',
      'need_email': need_email ?? '',
      'need_shipping_address': need_shipping_address ?? '',
      'send_phone_number_to_provider': send_phone_number_to_provider ?? '',
      'send_email_to_provider': send_email_to_provider ?? '',
      'is_flexible': is_flexible ?? '',
      'disable_notification': disable_notification ?? '',
      'reply_to_message_id': reply_to_message_id ?? '',
      'reply_markup': reply_markup == null ? '' : jsonEncode(reply_markup)
    };
    return Message.fromJson(await _client.httpPost(requestUrl, body: body));
  }

  /// If you sent an invoice requesting a shipping address and the parameter *is_flexible* was specified,
  /// the Bot API will send an [Update] with a *shipping_query* field to the bot.
  /// Use this method to reply to shipping queries. On success, *True* is returned.
  ///
  /// https://core.telegram.org/bots/api#answershippingquery
  ///
  /// [Update]: https://core.telegram.org/bots/api#update
  Future<bool> answerShippingQuery(String shipping_query_id, bool ok,
      {List<ShippingOption> shipping_options, String error_message}) async {
    if (!ok && (shipping_options == null || error_message == null)) {
      return Future.error(TelegramException(
          'Attribute \'shipping_options\' and \'error_message\' can not be null when \'ok\' = false'));
    }
    String requestUrl = '${_baseUrl}${_token}/answerShippingQuery';
    Map<String, dynamic> body = {
      'shipping_query_id': shipping_query_id,
      'ok': ok,
      'shipping_options':
          shipping_options == null ? '' : jsonEncode(shipping_options),
      'error_message': error_message ?? ''
    };
    return await _client.httpPost(requestUrl, body: body);
  }

  /// Once the user has confirmed their payment and shipping details,
  /// the Bot API sends the final confirmation in the form of an [Update] with the field *pre_checkout_query*.
  /// Use this method to respond to such pre-checkout queries.
  /// On success, *True* is returned.
  ///
  /// **Note:** The Bot API must receive an answer within 10 seconds after the pre-checkout query was sent.
  ///
  /// https://core.telegram.org/bots/api#answerprecheckoutquery
  ///
  /// [Update]: https://core.telegram.org/bots/api#update
  Future<bool> answerPreCheckoutQuery(String pre_checkout_query_id, bool ok,
      {String error_message}) async {
    if (!ok && error_message == null) {
      return Future.error(TelegramException(
          'Attribute \'error_message\' can not be null when \'ok\' = false'));
    }
    String requestUrl = '${_baseUrl}${_token}/answerShippingQuery';
    Map<String, dynamic> body = {
      'pre_checkout_query_id': pre_checkout_query_id,
      'ok': ok,
      'error_message': error_message ?? ''
    };
    return await _client.httpPost(requestUrl, body: body);
  }

  /// Informs a user that some of the Telegram Passport elements they provided contains errors.
  /// The user will not be able to re-submit their Passport to you until the errors are fixed
  /// (the contents of the field for which you returned the error must change).
  /// Returns *True* on success.
  ///
  /// Use this if the data submitted by the user doesn't satisfy the standards your service requires for any reason.
  /// For example, if a birthday date seems invalid, a submitted document is blurry,
  /// a scan shows evidence of tampering, etc.
  /// Supply some details in the error message to make sure the user knows how to correct the issues.
  ///
  /// https://core.telegram.org/bots/api#setpassportdataerrors
  Future<bool> setPassportDataErrors(
      int user_id, List<PassportElementError> errors) async {
    String requestUrl = '${_baseUrl}${_token}/setPassportDataErrors';
    Map<String, dynamic> body = {'user_id': user_id, 'errors': errors};
    return await _client.httpPost(requestUrl, body: body);
  }

  /// Use this method to send a game. On success, the sent [Message] is returned.
  ///
  /// https://core.telegram.org/bots/api#sendgame
  ///
  /// [Message]: https://core.telegram.org/bots/api#message
  Future<Message> sendGame(int chat_id, String game_short_name,
      {bool disable_notification,
      int reply_to_message_id,
      InlineKeyboardMarkup reply_markup}) async {
    String requestUrl = '${_baseUrl}${_token}/sendGame';
    Map<String, dynamic> body = {
      'chat_id': chat_id,
      'game_short_name': game_short_name,
      'disable_notification': disable_notification ?? '',
      'reply_to_message_id': reply_to_message_id ?? '',
      'reply_markup': reply_markup == null ? '' : jsonEncode(reply_markup)
    };
    return Message.fromJson(await _client.httpPost(requestUrl, body: body));
  }

  /// Use this method to set the score of the specified user in a game.
  /// On success, if the message was sent by the bot, returns the edited [Message],
  /// otherwise returns *True*. Returns an error,
  /// if the score is not greater than the user's current score in the chat and force is *False*.
  ///
  /// https://core.telegram.org/bots/api#setgamescore
  ///
  /// [Message]: https://core.telegram.org/bots/api#message
  Future<Message> setGameScore(int user_id, int score,
      {bool force,
      bool disable_edit_message,
      int chat_id,
      int message_id,
      String inline_message_id}) async {
    if (inline_message_id == null && (chat_id == null || message_id == null)) {
      return Future.error(TelegramException(
          'Require either \'chat_id\' and \'message_id\', or \'inline_message_id\''));
    }
    String requestUrl = '${_baseUrl}${_token}/setGameScore';
    Map<String, dynamic> body = {
      'user_id': user_id,
      'score': score,
      'force': force ?? '',
      'disable_edit_message': disable_edit_message ?? '',
      'chat_id': chat_id ?? '',
      'message_id': message_id ?? '',
      'inline_message_id': inline_message_id ?? ''
    };
    return Message.fromJson(await _client.httpPost(requestUrl, body: body));
  }

  /// Use this method to get data for high score tables.
  /// Will return the score of the specified user and several of his neighbors in a game.
  /// On success, returns an *Array* of [GameHighScore] objects.
  ///
  /// This method will currently return scores for the target user,
  /// plus two of his closest neighbors on each side.
  /// Will also return the top three users if the user and his neighbors are not among them.
  /// Please note that this behavior is subject to change.
  ///
  /// https://core.telegram.org/bots/api#getgamehighscores
  ///
  /// [GameHighScore]: https://core.telegram.org/bots/api#gamehighscore
  Future<List<GameHighScore>> getGameHighScores(int user_id,
      {int chat_id, int message_id, String inline_message_id}) async {
    if (inline_message_id == null && (chat_id == null || message_id == null)) {
      return Future.error(TelegramException(
          'Require either \'chat_id\' and \'message_id\', or \'inline_message_id\''));
    }
    String requestUrl = '${_baseUrl}${_token}/getGameHighScores';
    Map<String, dynamic> body = {
      'user_id': user_id,
      'chat_id': chat_id ?? '',
      'message_id': message_id ?? '',
      'inline_message_id': inline_message_id ?? ''
    };
    return (await _client.httpPost(requestUrl, body: body))
        .map<GameHighScore>(
            (gameHighScore) => GameHighScore.fromJson(gameHighScore))
        .toList();
  }
}

class TelegramException implements Exception {
  String cause;
  TelegramException(this.cause);
  String toString() => 'TelegramException: ${cause}';
}

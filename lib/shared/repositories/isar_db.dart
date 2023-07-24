import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:whatsapp_clone/features/chat/models/attachement.dart';
import 'package:whatsapp_clone/features/chat/models/recent_chat.dart';
import 'package:whatsapp_clone/features/home/data/repositories/contact_repository.dart';
import 'package:whatsapp_clone/shared/models/isar/messages.dart';
import 'package:whatsapp_clone/shared/models/user.dart';
import 'package:whatsapp_clone/shared/repositories/firebase_firestore.dart';
import 'package:whatsapp_clone/shared/utils/shared_pref.dart';

import '../../features/chat/models/message.dart';

final isarProvider = Provider((ref) => IsarDb());

class IsarDb {
  static late final Isar isar;

  static Future<void> init() async {
    final dir = await getApplicationDocumentsDirectory();
    isar = await Isar.open([StoredMessageSchema], directory: dir.path);
  }

  static Future<void> addMessage(Message message) async {
    final storedMsg = StoredMessage(
      messageId: message.id,
      chatId: message.chatId,
      content: message.content,
      senderId: message.senderId,
      receiverId: message.receiverId,
      status: message.status,
      timestamp: DateTime.now(),
      attachment: message.attachment != null
          ? EmbeddedAttachment(
              fileName: message.attachment!.fileName,
              fileExtension: message.attachment!.fileExtension,
              fileSize: message.attachment!.fileSize,
              width: message.attachment!.width,
              height: message.attachment!.height,
              uploadStatus: message.attachment!.uploadStatus,
              url: message.attachment!.url,
              type: message.attachment!.type,
            )
          : null,
    );

    await isar.writeTxn(() async {
      await isar.storedMessages.put(storedMsg);
    });
  }

  static Future<void> updateMessage(
    String messageId,
    Message newMessage,
  ) async {
    await isar.writeTxn(() async {
      StoredMessage? msg = await isar.storedMessages
          .filter()
          .messageIdEqualTo(messageId)
          .build()
          .findFirst();

      if (msg == null) return;

      msg.status = newMessage.status;
      msg.attachment = newMessage.attachment != null
          ? EmbeddedAttachment(
              fileName: newMessage.attachment!.fileName,
              fileExtension: newMessage.attachment!.fileExtension,
              fileSize: newMessage.attachment!.fileSize,
              width: newMessage.attachment!.width,
              height: newMessage.attachment!.height,
              uploadStatus: newMessage.attachment!.uploadStatus,
              url: newMessage.attachment!.url,
              type: newMessage.attachment!.type,
            )
          : null;
      await isar.storedMessages.put(msg);
    });
  }

  static Stream<List<Message>> getChatStream(String chatId) {
    return isar.storedMessages
        .filter()
        .chatIdEqualTo(chatId)
        .sortByTimestampDesc()
        .build()
        .watch(fireImmediately: true)
        .map((event) => event
            .map((msg) => Message(
                  id: msg.messageId!,
                  chatId: msg.chatId!,
                  content: msg.content!,
                  senderId: msg.senderId!,
                  receiverId: msg.receiverId!,
                  timestamp: Timestamp.fromDate(msg.timestamp!),
                  status: msg.status!,
                  attachment: msg.attachment != null
                      ? Attachment(
                          fileName: msg.attachment!.fileName!,
                          fileExtension: msg.attachment!.fileExtension!,
                          fileSize: msg.attachment!.fileSize!,
                          width: msg.attachment!.width,
                          height: msg.attachment!.height,
                          uploadStatus: msg.attachment!.uploadStatus!,
                          url: msg.attachment!.url!,
                          type: msg.attachment!.type!,
                        )
                      : null,
                ))
            .toList());
  }

  static Stream<List<RecentChat>> getRecentChatStream(WidgetRef ref) {
    final currentUser = User.fromMap(
      jsonDecode(SharedPref.instance.getString('user')!),
    );

    return isar.storedMessages
        .where()
        .sortByTimestampDesc()
        .watch(fireImmediately: true)
        .asyncMap((event) async {
      final visitedChats = <dynamic>{};
      final recentChats = <RecentChat>[];

      for (final msg in event) {
        if (visitedChats.contains(msg.chatId)) continue;
        if (msg.attachment != null &&
            msg.attachment!.uploadStatus != UploadStatus.uploaded) continue;

        final sender = await ref
            .read(firebaseFirestoreRepositoryProvider)
            .getUserById(
              msg.senderId! == currentUser.id ? msg.receiverId! : msg.senderId!,
            );

        final contact = await ref
            .read(contactsRepositoryProvider)
            .getContactByPhone(sender!.phone.number);

        final senderName = contact?.name ?? sender.name;

        recentChats.add(
          RecentChat(
            message: Message(
              id: msg.messageId!,
              chatId: msg.chatId!,
              content: msg.content!,
              senderId: msg.senderId!,
              receiverId: msg.receiverId!,
              timestamp: Timestamp.fromDate(msg.timestamp!),
              status: msg.status!,
              attachment: msg.attachment != null
                  ? Attachment(
                      fileName: msg.attachment!.fileName!,
                      fileExtension: msg.attachment!.fileExtension!,
                      fileSize: msg.attachment!.fileSize!,
                      width: msg.attachment!.width,
                      height: msg.attachment!.height,
                      uploadStatus: msg.attachment!.uploadStatus!,
                      url: msg.attachment!.url!,
                      type: msg.attachment!.type!,
                    )
                  : null,
            ),
            user: User.fromMap(
              sender.toMap()..addAll({'name': senderName}),
            ),
          ),
        );

        visitedChats.add(msg.chatId);
      }

      return recentChats;
    });
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_emoji/flutter_emoji.dart';
import 'package:whatsapp_clone/features/chat/models/message.dart';
import 'package:whatsapp_clone/shared/utils/abc.dart';
import 'package:whatsapp_clone/theme/theme.dart';

import '../../models/attachement.dart';
import 'attachment_viewer.dart';

enum MessageCardType { sentMessageCard, receivedMessageCard }

class MessageCard extends StatelessWidget {
  MessageCard({
    required this.message,
    required this.type,
    this.special = false,
  }) : super(key: ValueKey(message.id));

  final Message message;
  final bool special;
  final MessageCardType type;

  bool containsSingleEmoji(String text) {
    return EmojiParser().parseEmojis(text).length == 1 &&
        text.runes.length == 1;
  }

  @override
  Widget build(BuildContext context) {
    final colorTheme = Theme.of(context).custom.colorTheme;
    final size = MediaQuery.of(context).size;
    final hasAttachment = message.attachment != null;
    final attachmentType = message.attachment?.type;
    final isSentMessageCard = type == MessageCardType.sentMessageCard;
    final messageHasText = message.content.isNotEmpty;
    final hasSingleEmoji = containsSingleEmoji(message.content);
    final textPadding =
        '\u00A0' * (hasSingleEmoji ? 2 : (isSentMessageCard ? 16 : 12));
    final showTimeStamp = !hasAttachment ||
        (hasAttachment &&
            attachmentType == AttachmentType.audio &&
            messageHasText) ||
        (hasAttachment && attachmentType != AttachmentType.audio);

    return Align(
      alignment:
          isSentMessageCard ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          minHeight: 36,
          minWidth: 80,
          maxWidth: size.width * 0.80,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(hasAttachment ? 10.0 : 10.0),
          color: isSentMessageCard
              ? colorTheme.outgoingMessageBubbleColor
              : colorTheme.incomingMessageBubbleColor,
        ),
        margin: EdgeInsets.only(bottom: 4.0, top: special ? 6.0 : 0),
        padding: hasAttachment
            ? attachmentType == AttachmentType.audio && !messageHasText
                ? null
                : const EdgeInsets.all(4.0)
            : const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (hasAttachment) ...[
                  AttachmentPreview(
                    message: message,
                  ),
                ],
                if (messageHasText) ...[
                  Padding(
                    padding: hasAttachment
                        ? const EdgeInsets.only(left: 4.0, top: 4.0)
                        : EdgeInsets.only(
                            top: 4.0,
                            bottom: hasSingleEmoji ? 10.0 : 0,
                          ),
                    child: Text(
                      '${message.content} $textPadding',
                      style: Theme.of(context)
                          .custom
                          .textTheme
                          .bodyText1
                          .copyWith(fontSize: hasSingleEmoji ? 40 : 16),
                      softWrap: true,
                    ),
                  )
                ],
              ],
            ),
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                padding: !messageHasText && hasAttachment
                    ? const EdgeInsets.all(4.0)
                    : null,
                decoration: BoxDecoration(
                  boxShadow: [
                    if (!messageHasText &&
                        (attachmentType != AttachmentType.document &&
                            attachmentType != AttachmentType.audio)) ...[
                      const BoxShadow(
                        offset: Offset(-2, -2),
                        color: Color.fromARGB(225, 0, 0, 0),
                        blurRadius: 12,
                      )
                    ]
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (showTimeStamp) ...[
                      Text(
                        formattedTimestamp(
                          message.timestamp,
                          true,
                        ),
                        style: Theme.of(context)
                            .custom
                            .textTheme
                            .caption
                            .copyWith(
                                fontSize: 11,
                                color: messageHasText
                                    ? colorTheme.textColor2
                                    : Colors.white),
                      )
                    ],
                    if (isSentMessageCard) ...[
                      const SizedBox(
                        width: 2.0,
                      ),
                      Image.asset(
                        'assets/images/${message.status.value}.png',
                        color: message.status.value != 'SEEN'
                            ? messageHasText
                                ? colorTheme.textColor2
                                : Colors.white
                            : null,
                        width: 15.0,
                      )
                    ],
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}

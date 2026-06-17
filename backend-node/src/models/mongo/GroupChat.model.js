'use strict';

const mongoose = require('mongoose');

const readBySchema = new mongoose.Schema(
  {
    userId: String,
    readAt: Date,
  },
  { _id: false }
);

const messageSchema = new mongoose.Schema(
  {
    messageId: { type: mongoose.Schema.Types.ObjectId, default: () => new mongoose.Types.ObjectId() },
    senderId: { type: String, required: true },
    type: {
      type: String,
      enum: ['TEXT', 'IMAGE', 'SYSTEM', 'LOCATION_SHARE'],
      required: true,
    },
    content: String,
    metadata: mongoose.Schema.Types.Mixed,
    is_deleted: { type: Boolean, default: false },
    sentAt: { type: Date, default: Date.now },
    read_by: [readBySchema],
  },
  { _id: false }
);

const groupChatSchema = new mongoose.Schema(
  {
    sessionId: { type: String, required: true, unique: true, index: true },
    participant_ids: [{ type: String }],
    messages: [messageSchema],
    is_archived: { type: Boolean, default: false },
    overflow_sequence: { type: Number, default: 0 },
  },
  { timestamps: true, collection: 'groupchats' }
);

groupChatSchema.index({ participant_ids: 1 });

const OVERFLOW_LIMIT = parseInt(process.env.CHAT_MESSAGE_OVERFLOW_LIMIT || '500', 10);

/**
 * Add a message with overflow management.
 * When messages exceed 500, archive current doc and create overflow document.
 */
groupChatSchema.statics.addMessage = async function (sessionId, messageData) {
  let chat = await this.findOne({ sessionId, is_archived: false });

  if (!chat) {
    chat = await this.create({
      sessionId,
      participant_ids: messageData.participantIds || [],
      messages: [],
    });
  }

  if (chat.messages.length >= OVERFLOW_LIMIT) {
    chat.is_archived = true;
    await chat.save();

    const overflowSeq = (chat.overflow_sequence || 0) + 1;
    chat = await this.create({
      sessionId,
      participant_ids: chat.participant_ids,
      messages: [],
      overflow_sequence: overflowSeq,
    });
  }

  const message = {
    messageId: new mongoose.Types.ObjectId(),
    senderId: messageData.senderId,
    type: messageData.type || 'TEXT',
    content: messageData.content,
    metadata: messageData.metadata,
    sentAt: new Date(),
    read_by: [],
  };

  chat.messages.push(message);

  if (messageData.participantIds) {
    const merged = new Set([...chat.participant_ids, ...messageData.participantIds]);
    chat.participant_ids = [...merged];
  }

  await chat.save();
  return { chat, message };
};

/**
 * Get recent messages across active and archived overflow documents.
 */
groupChatSchema.statics.getMessages = async function (sessionId, limit = 50) {
  const chats = await this.find({ sessionId })
    .sort({ overflow_sequence: 1 })
    .lean();

  const allMessages = chats.flatMap((c) => c.messages || []);
  return allMessages.slice(-limit);
};

const GroupChat = mongoose.model('GroupChat', groupChatSchema);

module.exports = GroupChat;

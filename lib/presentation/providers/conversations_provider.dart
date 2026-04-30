import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/models/conversation_model.dart';

final conversationsStreamProvider =
    StreamProvider.family<List<ConversationMessage>, String>((ref, phone) {
  return Supabase.instance.client
      .from('conversations')
      .stream(primaryKey: ['id'])
      .eq('phone', phone)
      .order('created_at', ascending: true)
      .map((rows) => rows.map(ConversationMessage.fromJson).toList());
});

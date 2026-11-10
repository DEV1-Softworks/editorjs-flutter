import '../../domain/entities/blocks/checklist_block.dart';
import '../utils/json_reader.dart';
import 'block_mapper.dart';

class ChecklistMapper implements BlockMapper<ChecklistBlock> {
  const ChecklistMapper();

  @override
  String get supportedType => 'checklist';

  @override
  ChecklistBlock fromJson(Map<String, dynamic> data) {
    return ChecklistBlock(
      items: JsonReader.list(data['items'])
          .whereType<Map<String, dynamic>>()
          .map((i) => ChecklistItem(
                text: JsonReader.string(i['text']),
                checked: JsonReader.boolean(i['checked']),
              ))
          .toList(),
    );
  }
}

import '../../domain/entities/blocks/attaches_block.dart';
import '../utils/json_reader.dart';
import 'block_mapper.dart';

class AttachesMapper implements BlockMapper<AttachesBlock> {
  const AttachesMapper();

  static const _knownFileKeys = {'url', 'name', 'extension', 'size'};

  @override
  String get supportedType => 'attaches';

  @override
  AttachesBlock fromJson(Map<String, dynamic> data) {
    final file = JsonReader.map(data['file']);
    return AttachesBlock(
      url: JsonReader.string(file?['url']),
      name: JsonReader.nullableString(file?['name']),
      extension: JsonReader.nullableString(file?['extension']),
      size: JsonReader.integer(file?['size']),
      title: JsonReader.nullableString(data['title']),
      fileExtras: JsonReader.extras(file, _knownFileKeys),
    );
  }
}

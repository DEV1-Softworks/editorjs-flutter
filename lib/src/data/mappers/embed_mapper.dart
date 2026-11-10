import '../../domain/entities/blocks/embed_block.dart';
import '../utils/json_reader.dart';
import 'block_mapper.dart';

class EmbedMapper implements BlockMapper<EmbedBlock> {
  const EmbedMapper();

  @override
  String get supportedType => 'embed';

  @override
  EmbedBlock fromJson(Map<String, dynamic> data) => EmbedBlock(
        service: JsonReader.string(data['service']),
        source: JsonReader.string(data['source']),
        embed: JsonReader.string(data['embed']),
        width: JsonReader.integer(data['width']),
        height: JsonReader.integer(data['height']),
        caption: JsonReader.nullableString(data['caption']),
      );
}

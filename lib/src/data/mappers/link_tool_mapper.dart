import '../../domain/entities/blocks/link_tool_block.dart';
import '../utils/json_reader.dart';
import 'block_mapper.dart';

class LinkToolMapper implements BlockMapper<LinkToolBlock> {
  const LinkToolMapper();

  static const _knownMetaKeys = {'title', 'description', 'image'};

  @override
  String get supportedType => 'linkTool';

  @override
  LinkToolBlock fromJson(Map<String, dynamic> data) {
    // Some backends emit `"meta": []` for "no metadata" — treat any
    // non-object value as absent rather than failing the whole block.
    final rawMeta = JsonReader.map(data['meta']);

    return LinkToolBlock(
      link: JsonReader.string(data['link']),
      meta: rawMeta == null
          ? null
          : LinkToolMeta(
              title: JsonReader.nullableString(rawMeta['title']),
              description: JsonReader.nullableString(rawMeta['description']),
              imageUrl: JsonReader.nullableString(
                JsonReader.map(rawMeta['image'])?['url'],
              ),
              extras: JsonReader.extras(rawMeta, _knownMetaKeys),
            ),
    );
  }
}

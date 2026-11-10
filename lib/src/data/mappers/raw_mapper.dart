import '../../domain/entities/blocks/raw_block.dart';
import '../utils/json_reader.dart';
import 'block_mapper.dart';

class RawMapper implements BlockMapper<RawBlock> {
  const RawMapper();

  @override
  String get supportedType => 'raw';

  @override
  RawBlock fromJson(Map<String, dynamic> data) =>
      RawBlock(html: JsonReader.string(data['html']));
}

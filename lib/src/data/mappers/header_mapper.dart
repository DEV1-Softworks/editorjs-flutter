import '../../domain/entities/blocks/header_block.dart';
import '../utils/json_reader.dart';
import 'block_mapper.dart';

class HeaderMapper implements BlockMapper<HeaderBlock> {
  const HeaderMapper();

  @override
  String get supportedType => 'header';

  @override
  HeaderBlock fromJson(Map<String, dynamic> data) => HeaderBlock(
        text: JsonReader.string(data['text']),
        level: JsonReader.integer(data['level']) ?? 1,
      );
}

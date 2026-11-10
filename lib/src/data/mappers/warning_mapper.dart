import '../../domain/entities/blocks/warning_block.dart';
import '../utils/json_reader.dart';
import 'block_mapper.dart';

class WarningMapper implements BlockMapper<WarningBlock> {
  const WarningMapper();

  @override
  String get supportedType => 'warning';

  @override
  WarningBlock fromJson(Map<String, dynamic> data) => WarningBlock(
        title: JsonReader.string(data['title']),
        message: JsonReader.string(data['message']),
      );
}

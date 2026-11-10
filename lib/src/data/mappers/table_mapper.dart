import '../../domain/entities/blocks/table_block.dart';
import '../utils/json_reader.dart';
import 'block_mapper.dart';

class TableMapper implements BlockMapper<TableBlock> {
  const TableMapper();

  @override
  String get supportedType => 'table';

  @override
  TableBlock fromJson(Map<String, dynamic> data) {
    return TableBlock(
      withHeadings: JsonReader.boolean(data['withHeadings']),
      stretched: JsonReader.boolean(data['stretched']),
      content: JsonReader.list(data['content'])
          .map((row) =>
              JsonReader.list(row).map((cell) => cell.toString()).toList())
          .toList(),
    );
  }
}

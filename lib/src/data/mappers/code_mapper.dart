import '../../domain/entities/blocks/code_block.dart';
import '../utils/json_reader.dart';
import 'block_mapper.dart';

class CodeMapper implements BlockMapper<CodeBlock> {
  const CodeMapper();

  @override
  String get supportedType => 'code';

  @override
  CodeBlock fromJson(Map<String, dynamic> data) =>
      CodeBlock(code: JsonReader.string(data['code']));
}

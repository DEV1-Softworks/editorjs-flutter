import '../../domain/entities/blocks/quote_block.dart';
import '../utils/json_reader.dart';
import 'block_mapper.dart';

class QuoteMapper implements BlockMapper<QuoteBlock> {
  const QuoteMapper();

  @override
  String get supportedType => 'quote';

  @override
  QuoteBlock fromJson(Map<String, dynamic> data) {
    final alignStr = data['alignment'];
    return QuoteBlock(
      text: JsonReader.string(data['text']),
      caption: JsonReader.nullableString(data['caption']),
      alignment: QuoteAlignment.values.firstWhere(
        (a) => a.name == alignStr,
        orElse: () => QuoteAlignment.left,
      ),
    );
  }
}

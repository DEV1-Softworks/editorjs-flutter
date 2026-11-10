import '../../domain/entities/blocks/image_block.dart';
import '../utils/json_reader.dart';
import 'block_mapper.dart';

class ImageMapper implements BlockMapper<ImageBlock> {
  const ImageMapper();

  static const _knownFileKeys = {'url'};

  @override
  String get supportedType => 'image';

  @override
  ImageBlock fromJson(Map<String, dynamic> data) {
    final file = JsonReader.map(data['file']);
    return ImageBlock(
      url: JsonReader.string(file?['url']),
      caption: JsonReader.nullableString(data['caption']),
      withBorder: JsonReader.boolean(data['withBorder']),
      stretched: JsonReader.boolean(data['stretched']),
      withBackground: JsonReader.boolean(data['withBackground']),
      fileExtras: JsonReader.extras(file, _knownFileKeys),
    );
  }
}

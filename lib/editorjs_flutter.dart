// Widgets
export 'src/presentation/widgets/editorjs_view.dart';
export 'src/presentation/widgets/editorjs_editor.dart';
export 'src/presentation/widgets/editor_link_scope.dart';

// Controller
export 'src/presentation/controller/editor_controller.dart';

// Configuration
export 'src/presentation/config/block_editor_hooks.dart';
export 'src/presentation/config/editor_config.dart';
export 'src/presentation/config/editor_strings.dart';
export 'src/presentation/config/editor_toolbar_item.dart';
export 'src/presentation/config/image_uploader.dart';

// Registries — needed only by callers registering custom block types
export 'src/data/registry/block_type_registry.dart';
export 'src/presentation/registry/block_renderer_registry.dart';

// Contracts for custom block authors
export 'src/data/mappers/block_mapper.dart';
export 'src/presentation/blocks/base_block_renderer.dart';
export 'src/presentation/blocks/base_block_editor.dart';

// Domain entities — needed for typed access in callbacks and custom blocks
export 'src/domain/entities/block_entity.dart';
export 'src/domain/entities/block_document.dart';
export 'src/domain/entities/block_metadata.dart';
export 'src/domain/entities/style_config.dart';

// Built-in block entities
export 'src/domain/entities/blocks/header_block.dart';
export 'src/domain/entities/blocks/paragraph_block.dart';
export 'src/domain/entities/blocks/list_block.dart';
export 'src/domain/entities/blocks/delimiter_block.dart';
export 'src/domain/entities/blocks/image_block.dart';
export 'src/domain/entities/blocks/quote_block.dart';
export 'src/domain/entities/blocks/code_block.dart';
export 'src/domain/entities/blocks/checklist_block.dart';
export 'src/domain/entities/blocks/table_block.dart';
export 'src/domain/entities/blocks/warning_block.dart';
export 'src/domain/entities/blocks/embed_block.dart';
export 'src/domain/entities/blocks/link_tool_block.dart';
export 'src/domain/entities/blocks/attaches_block.dart';
export 'src/domain/entities/blocks/raw_block.dart';
export 'src/domain/entities/blocks/unknown_block.dart';

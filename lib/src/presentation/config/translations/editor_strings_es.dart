import '../editor_strings.dart';

/// Spanish texts for the editor and the viewer.
///
/// Use it through `EditorTranslations`. To add a language, copy this file,
/// translate every text, and register the result in `EditorTranslations`.
const EditorStrings editorStringsEs = EditorStrings(
  // Toolbar
  paragraph: 'Párrafo',
  paragraphLabel: 'T',
  heading: _heading,
  headingLabel: _headingLabel,
  quote: 'Cita',
  code: 'Código',
  unorderedList: 'Lista con viñetas',
  orderedList: 'Lista numerada',
  checklist: 'Lista de verificación',
  legacyChecklist: 'Lista de verificación (anterior)',
  table: 'Tabla',
  delimiter: 'Separador',
  warning: 'Advertencia',
  image: 'Imagen',
  embed: 'Contenido incrustado',
  linkPreview: 'Vista previa de enlace',
  attachment: 'Archivo adjunto',
  rawHtml: 'HTML sin procesar',
  hyperlink: 'Hipervínculo',
  undo: 'Deshacer',
  redo: 'Rehacer',
  removeLastBlock: 'Eliminar el último bloque',
  addHyperlinkTitle: 'Agregar hipervínculo',
  hyperlinkTitleHint: 'Título del enlace',
  // Shared actions and field labels
  add: 'Agregar',
  cancel: 'Cancelar',
  save: 'Guardar',
  caption: 'Leyenda',
  title: 'Título',
  addItem: 'Agregar elemento',
  // Block controls
  moveUp: 'Mover arriba',
  moveDown: 'Mover abajo',
  deleteBlock: 'Eliminar bloque',
  unsupportedBlock: _unsupportedBlock,
  // Paragraph
  paragraphHint: 'Escribe algo...',
  bold: 'Negrita',
  boldLabel: 'N',
  italic: 'Cursiva',
  italicLabel: 'K',
  underline: 'Subrayado',
  underlineLabel: 'S',
  strikethrough: 'Tachado',
  strikethroughLabel: 'T',
  inlineCode: 'Código en línea',
  highlight: 'Resaltar',
  highlightLabel: 'marca',
  link: 'Enlace',
  linkLabel: 'enlace',
  addLinkTitle: 'Agregar enlace',
  editLinkTitle: 'Editar enlace',
  linkAddress: 'Dirección del enlace',
  removeLink: 'Quitar enlace',
  // Header
  headingLevel: 'Nivel de encabezado',
  // List
  listUnordered: 'Con viñetas',
  listOrdered: 'Numerada',
  listChecklist: 'Lista de verificación',
  startWith: 'Empezar en',
  counterNumeric: 'Números',
  counterLowerRoman: 'Romanos en minúscula',
  counterUpperRoman: 'Romanos en mayúscula',
  counterLowerAlpha: 'Letras minúsculas',
  counterUpperAlpha: 'Letras mayúsculas',
  outdent: 'Reducir sangría',
  indent: 'Aumentar sangría',
  removeItem: 'Eliminar elemento',
  checklistItemHint: 'Elemento de la lista...',
  // Quote
  quoteHint: 'Texto de la cita...',
  quoteCaptionHint: 'Leyenda (opcional)',
  align: 'Alinear:',
  alignLeft: 'izquierda',
  alignCenter: 'centro',
  alignRight: 'derecha',
  // Code
  codeHint: 'Escribe el código...',
  copy: 'Copiar',
  // Warning
  warningTitleHint: 'Título de la advertencia',
  warningMessageHint: 'Mensaje de la advertencia...',
  // Table
  firstRowIsHeader: 'La primera fila es el encabezado',
  removeRow: 'Eliminar fila',
  removeColumn: 'Eliminar columna',
  addRow: 'Fila',
  addColumn: 'Columna',
  // Image
  camera: 'Cámara',
  gallery: 'Galería',
  imageUrl: 'URL de la imagen',
  imageBorder: 'Borde',
  imageStretch: 'Estirar',
  imageBackground: 'Fondo',
  imagePickFailed: 'No se pudo abrir la imagen.',
  imageUploadFailed: 'No se pudo subir la imagen. Inténtalo de nuevo.',
  // Embed
  embedLink: 'Enlace del contenido',
  embedService: _embedService,
  embedUnsupported: 'Este enlace no es de un servicio compatible.',
  embeddedContent: 'Contenido incrustado',
  // Link preview
  linkUrl: 'Enlace',
  fetchPreview: 'Obtener vista previa',
  description: 'Descripción',
  previewImageUrl: 'URL de la imagen de vista previa',
  noPreview: 'No hay vista previa disponible para este enlace.',
  previewFailed: 'No se pudo obtener la vista previa.',
  // Attachment
  chooseFile: 'Elegir archivo',
  fileUrl: 'URL del archivo',
  fileSize: _fileSize,
  attachFailed: 'No se pudo adjuntar el archivo.',
  downloadFile: 'Descargar archivo',
);

String _heading(int level) => 'Encabezado $level';
String _headingLabel(int level) => 'H$level';
String _unsupportedBlock(String type) => '[Bloque no compatible: $type]';
String _embedService(String service) => 'Servicio: $service';
String _fileSize(int bytes) => '$bytes bytes';

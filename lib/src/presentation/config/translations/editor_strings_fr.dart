import '../editor_strings.dart';

/// French texts for the editor and the viewer.
///
/// Use it through `EditorTranslations`. To add a language, copy this file,
/// translate every text, and register the result in `EditorTranslations`.
const EditorStrings editorStringsFr = EditorStrings(
  // Toolbar
  paragraph: 'Paragraphe',
  paragraphLabel: 'T',
  heading: _heading,
  headingLabel: _headingLabel,
  quote: 'Citation',
  code: 'Code',
  unorderedList: 'Liste à puces',
  orderedList: 'Liste numérotée',
  checklist: 'Liste de tâches',
  legacyChecklist: 'Liste de tâches (ancienne)',
  table: 'Tableau',
  delimiter: 'Séparateur',
  warning: 'Avertissement',
  image: 'Image',
  embed: 'Contenu intégré',
  linkPreview: 'Aperçu de lien',
  attachment: 'Pièce jointe',
  rawHtml: 'HTML brut',
  hyperlink: 'Lien hypertexte',
  undo: 'Annuler',
  redo: 'Rétablir',
  removeLastBlock: 'Supprimer le dernier bloc',
  addHyperlinkTitle: 'Ajouter un lien hypertexte',
  hyperlinkTitleHint: 'Titre du lien',
  // Shared actions and field labels
  add: 'Ajouter',
  cancel: 'Annuler',
  save: 'Enregistrer',
  caption: 'Légende',
  title: 'Titre',
  addItem: 'Ajouter un élément',
  // Block controls
  moveUp: 'Monter',
  moveDown: 'Descendre',
  deleteBlock: 'Supprimer le bloc',
  unsupportedBlock: _unsupportedBlock,
  // Paragraph
  paragraphHint: 'Écrivez quelque chose...',
  bold: 'Gras',
  boldLabel: 'G',
  italic: 'Italique',
  italicLabel: 'I',
  underline: 'Souligné',
  underlineLabel: 'S',
  strikethrough: 'Barré',
  strikethroughLabel: 'B',
  inlineCode: 'Code en ligne',
  highlight: 'Surligner',
  highlightLabel: 'marque',
  link: 'Lien',
  linkLabel: 'lien',
  addLinkTitle: 'Ajouter un lien',
  editLinkTitle: 'Modifier le lien',
  linkAddress: 'Adresse du lien',
  removeLink: 'Supprimer le lien',
  // Header
  headingLevel: 'Niveau de titre',
  // List
  listUnordered: 'À puces',
  listOrdered: 'Numérotée',
  listChecklist: 'Liste de tâches',
  startWith: 'Commencer à',
  counterNumeric: 'Chiffres',
  counterLowerRoman: 'Romains minuscules',
  counterUpperRoman: 'Romains majuscules',
  counterLowerAlpha: 'Lettres minuscules',
  counterUpperAlpha: 'Lettres majuscules',
  outdent: 'Diminuer le retrait',
  indent: 'Augmenter le retrait',
  removeItem: "Supprimer l'élément",
  checklistItemHint: 'Élément de la liste...',
  // Quote
  quoteHint: 'Texte de la citation...',
  quoteCaptionHint: 'Légende (facultatif)',
  align: 'Aligner :',
  alignLeft: 'gauche',
  alignCenter: 'centre',
  alignRight: 'droite',
  // Code
  codeHint: 'Saisissez le code...',
  copy: 'Copier',
  // Warning
  warningTitleHint: "Titre de l'avertissement",
  warningMessageHint: "Message de l'avertissement...",
  // Table
  firstRowIsHeader: "La première ligne est l'en-tête",
  removeRow: 'Supprimer la ligne',
  removeColumn: 'Supprimer la colonne',
  addRow: 'Ligne',
  addColumn: 'Colonne',
  // Image
  camera: 'Appareil photo',
  gallery: 'Galerie',
  imageUrl: "URL de l'image",
  imageBorder: 'Bordure',
  imageStretch: 'Étirer',
  imageBackground: 'Arrière-plan',
  imagePickFailed: "Impossible d'ouvrir l'image.",
  imageUploadFailed: "Échec de l'envoi. Réessayez.",
  // Embed
  embedLink: 'Lien du contenu',
  embedService: _embedService,
  embedUnsupported: "Ce lien ne provient pas d'un service pris en charge.",
  embeddedContent: 'Contenu intégré',
  // Link preview
  linkUrl: 'Lien',
  fetchPreview: "Récupérer l'aperçu",
  description: 'Description',
  previewImageUrl: "URL de l'image d'aperçu",
  noPreview: 'Aucun aperçu disponible pour ce lien.',
  previewFailed: "Impossible de récupérer l'aperçu.",
  // Attachment
  chooseFile: 'Choisir un fichier',
  fileUrl: 'URL du fichier',
  fileSize: _fileSize,
  attachFailed: 'Impossible de joindre le fichier.',
  downloadFile: 'Télécharger le fichier',
);

String _heading(int level) => 'Titre $level';
String _headingLabel(int level) => 'H$level';
String _unsupportedBlock(String type) => '[Bloc non pris en charge : $type]';
String _embedService(String service) => 'Service : $service';
String _fileSize(int bytes) => '$bytes octets';

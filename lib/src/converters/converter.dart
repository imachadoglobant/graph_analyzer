import '../../code_uml.dart';
import '../../utils.dart';

part 'mermaid_uml_converter.dart';
part 'plant_uml_converter.dart';

/// This class converts definitions to uml code
sealed class Converter {
  factory Converter(
      {required final String converterType,
      required final List<String> excludedClasses,
      required final List<String> excludedMethods,
      final String? theme}) {
    switch (converterType) {
      case 'mermaid':
        return MermaidUmlConverter(
            theme: theme,
            excludedClasses: excludedClasses,
            excludedMethods: excludedMethods);
      case 'plantuml':
      default:
        return PlantUmlConverter(
            theme: theme,
            excludedClasses: excludedClasses,
            excludedMethods: excludedMethods);
    }
  }

  /// Public access modifier
  String get publicAccessModifier;

  /// Private access modifier
  String get privateAccessModifier;

  /// File extension
  String get fileExtension;

  /// Divider between fields and methods
  String get methodsDivider;

  /// Converts start of [ClassDef] to uml code
  String convertStartClass(final ClassDef def);

  /// Converts end of [ClassDef] to uml code
  String convertEndClass(final ClassDef def);

  /// Converts start of [ClassDef] to uml code
  String convertStartEnum(final ClassDef def);

  /// Convert class dependencies to uml code
  String convertValues(final ClassDef def);

  /// Converts [FieldDef] to uml code
  String convertFields(final ClassDef def);

  /// Converts [MethodDef] to uml code
  String convertMethods(final ClassDef def);

  /// Converts [ClassDef] to uml code
  String convertToText(final List<ClassDef> defs);

  /// Converts 'extends' to uml code
  String convertExtends(final ClassDef classDef);

  /// Convert class dependencies to uml code
  String convertDependencies(final ClassDef def);

  /// Convert implements to uml code
  String convertImplements(final ClassDef def);
}

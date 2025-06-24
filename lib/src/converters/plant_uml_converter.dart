part of 'converter.dart';

final class PlantUmlConverter implements Converter {
  final String? theme;
  final String? title;
  final List<String> excludedClasses;
  final List<String> excludedMethods;

  PlantUmlConverter(
      {required this.excludedClasses,
      required this.excludedMethods,
      this.theme,
      this.title});

  @override
  String convertToText(final List<ClassDef> defs) {
    final stringBuffer = StringBuffer('@startuml @\n');

    // Apply the theme if provided
    if (theme != null && theme!.isNotEmpty) {
      // Basic validation: ensure theme name doesn't contain unsafe characters
      // You might want a more robust validation or allow list.
      if (RegExp(r'^[a-zA-Z0-9_-]+$').hasMatch(theme!)) {
        stringBuffer.writeln('!theme $theme');
        // Logger().info('Applied PlantUML theme: $theme'); // Optional logging
      } else {
        Logger().error(
            'Invalid theme name provided: $theme. Skipping theme application.');
      }
    }

    // Apply the title if provided
    if (title != null && title!.isNotEmpty) {
      // Escape double quotes
      final sanitizedTitle = title!
          .replaceAll('"', '""')
          // Remove newlines
          .replaceAll('\n', '');
      stringBuffer
          .writeln('title "$sanitizedTitle"'); // Enclose title in quotes
    }

    for (final def in defs) {
      stringBuffer.write('\n');
      stringBuffer.write(def.isAbstract ? 'abstract ' : '');
      stringBuffer
          .write(def.isEnum ? convertStartEnum(def) : convertStartClass(def));
      stringBuffer.write(def.isEnum ? convertValues(def) : '');
      stringBuffer.write(convertFields(def));
      if (def.methods.isNotEmpty) {
        stringBuffer.write(methodsDivider);
        stringBuffer.write(convertMethods(def));
      }
      stringBuffer.write(convertEndClass(def));
      stringBuffer.write(convertExtends(def));
      stringBuffer.write(convertDependencies(def));
      stringBuffer.write(convertImplements(def));
    }

    stringBuffer.write('@enduml');
    return stringBuffer.toString();
  }

  @override
  String get fileExtension => 'puml';

  @override
  String convertMethods(final ClassDef def) {
    final result = StringBuffer();

    for (final method in def.methods) {
      if (excludedMethods.contains(method.name)) {
        // Optionally log that a method is being skipped
        // logger.info('Excluding method: ${classDef.name}.${method.name}');
        continue; // Skip this method
      }
      result.write(
        '\t${method.isPrivate ? privateAccessModifier : publicAccessModifier}'
        '${method.isGetter || method.isSetter ? '«' : ''}'
        '${method.isGetter ? 'get' : ''}'
        '${method.isGetter && method.isSetter ? '/' : ''}'
        '${method.isSetter ? 'set' : ''}'
        '${method.isGetter || method.isSetter ? '»' : ''}'
        '${method.name}(): '
        '${method.returnType}\n',
      );
    }

    return result.toString();
  }

  @override
  String convertValues(final ClassDef def) {
    final result = StringBuffer();
    for (final field in def.values) {
      result.write(
        '\t$field\n',
      );
    }
    return result.toString();
  }

  @override
  String convertFields(final ClassDef def) {
    final result = StringBuffer();
    for (final field in def.fields) {
      result.write(
        '\t${field.isPrivate ? privateAccessModifier : publicAccessModifier}'
        '${field.name}:'
        ' ${field.type}\n',
      );
    }
    return result.toString();
  }

  @override
  String convertStartClass(final ClassDef def) {
    if (def.extendsOf != null && !excludedClasses.contains(def.extendsOf)) {
      return 'class ${def.name} <<${def.extendsOf}>> {\n';
    }
    if (def.implementsOf.isNotEmpty &&
        !excludedClasses.contains(def.extendsOf)) {
      return 'class ${def.name} <<${def.implementsOf.toList().toString()}>> {\n';
    }
    return 'class ${def.name} {\n';
  }

  @override
  String convertEndClass(final ClassDef def) => '}\n';

  @override
  String convertStartEnum(final ClassDef def) => 'enum ${def.name} {\n';

  @override
  String get methodsDivider => '---\n';

  @override
  String convertExtends(final ClassDef classDef) {
    if (classDef.extendsOf != null &&
        !excludedClasses.contains(classDef.extendsOf)) {
      return '${classDef.extendsOf} <|-- ${classDef.name}\n';
    }
    return '';
  }

  @override
  String convertDependencies(final ClassDef def) {
    final result = StringBuffer();
    for (final dep in def.deps) {
      if (excludedClasses.contains(dep)) continue;
      result.write('${def.name} ..> $dep\n');
    }
    return result.toString();
  }

  @override
  String convertImplements(final ClassDef def) {
    final result = StringBuffer();
    for (final implementOf in def.implementsOf) {
      result.write('${def.name} ..|> $implementOf\n');
    }
    return result.toString();
  }

  @override
  final privateAccessModifier = '-';
  @override
  final publicAccessModifier = '+';
}

import 'dart:io';

import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart';

import '../utils.dart';
import 'class_def.dart';
import 'field_def.dart';
import 'method_def.dart';
import 'reporter.dart';

/// Analyzes the code and turns it into uml code
///
/// [reporter] - the entity that outputs the result
class CodeUml {
  final Reporter reporter;
  final Logger logger;
  final List<String> excludedClasses;

  CodeUml({
    required this.reporter,
    required this.logger,
    this.excludedClasses = const [], // Default to an empty list
  });

  /// Retrieves files from the specified directories
  List<String> _getFilePathsFromDir(final List<String> dirsPath) {
    final files = <String>[];
    for (final dirPath in dirsPath) {
      final dir = Directory(dirPath);

      dir.listSync(recursive: true).forEach((final fileEntity) {
        if (fileEntity.statSync().type != FileSystemEntityType.file ||
            !fileEntity.path.endsWith('.dart')) {
          return;
        }

        final path = fileEntity.path;
        files.add(path);
      });
    }
    return files;
  }

  Future<void> analyze(final List<String> dirsPath) async {
    if (dirsPath.isEmpty) {
      throw Exception('Directories are not specified');
    }
    final includedPaths = _getFilePathsFromDir(dirsPath).toList();
    final classesDef = <ClassDef>[];
    final collection = AnalysisContextCollection(includedPaths: includedPaths);

    for (final path in includedPaths) {
      logger.regular(path);
      final unit = collection.contexts.first.currentSession.getParsedUnit(path);

      if (unit is ParsedUnitResult) {
        if (_isExcludedFile(unit.uri)) {
          continue;
        }

        for (final unitMember in unit.unit.declarations) {
          if (unitMember is ClassDeclaration) {
            final className = unitMember.name.lexeme;
            logger.regular('className=$className', onlyVerbose: true);
            // Check if the class is in the excluded list
            if (excludedClasses.contains(className)) {
              logger.info('Excluded class: $className', onlyVerbose: false);
              continue; // Skip this class
            }
            final analyzedClass = _analyzeClass(unitMember);
            classesDef.add(analyzedClass);
          }
          if (unitMember is EnumDeclaration) {
            final enumName = unitMember.name.lexeme;
            logger.regular('enumName=$enumName', onlyVerbose: true);
            final analyzedEnum = _analyzeEnum(unitMember);
            classesDef.add(analyzedEnum);
          }
        }
      }
    }

    await reporter.report(classesDef);
  }

  /// Analyzes a class for methods, fields, inheritance, implementations, and dependencies
  ClassDef _analyzeClass(final ClassDeclaration classDeclaration) {
    final extendsOf = classDeclaration.extendsClause?.superclass.name2.lexeme;
    final implementsOf = classDeclaration.implementsClause?.interfaces
            .map((final e) => e.name2.lexeme)
            .toList() ??
        [];
    final classDef = ClassDef();
    classDef.name = classDeclaration.name.lexeme;
    classDef.extendsOf = extendsOf;
    classDef.isAbstract = classDeclaration.abstractKeyword != null;
    classDef.implementsOf.addAll(implementsOf);
    for (final member in classDeclaration.members) {
      if (member is MethodDeclaration) {
        classDef.methods.add(_analyzeMethod(member));
      } else if (member is FieldDeclaration) {
        classDef.fields.add(_analyzeField(member));
        classDef.deps.addAll(_analyzeDeps(member));
      }
    }
    logger.info('- ${classDef.name} : ${classDef.extendsOf}',
        onlyVerbose: true);
    return classDef;
  }

  /// Analyzes a method
  MethodDef _analyzeMethod(final MethodDeclaration methodDeclaration) {
    final methodDef = MethodDef(methodDeclaration);
    return methodDef;
  }

  /// Analyzes a class field
  FieldDef _analyzeField(final FieldDeclaration fieldDeclaration) {
    final fieldDef = FieldDef(fieldDeclaration);
    return fieldDef;
  }

  /// Analyzes dependencies
  Set<String> _analyzeDeps(final FieldDeclaration fieldDeclaration) {
    final result = <String>{};
    var type = fieldDeclaration.fields.type.toString();
    // logger.regular('type=$type', onlyVerbose: true);

    if (type.endsWith('?')) {
      type = type.replaceAll('?', '');
    }

    if (type.contains('<')) {
      type = type.replaceAll(RegExp(r'<.*>'), '');
    }

    if (_isDep(type)) {
      result.add(type);
    }

    return result;
  }

  /// Determines whether the data type is a dependency. It is a dependency if it is not a base type
  bool _isDep(final String type) =>
      !type.startsWith('List') &&
      !type.startsWith('Map') &&
      !type.startsWith('Set') &&
      !type.startsWith(r'_$') &&
      !type.startsWith(r'__$') &&
      ![
        'String',
        'int',
        'double',
        'num',
        'String?',
        'int?',
        'double?',
        'num?',
        'Object',
        'Object?',
        'dynamic',
        'bool',
        'bool?',
        'null',
        'Symbol',
        'Symbol?',
        'Duration',
        'Duration?',
        'StreamSubscription',
        'StreamSubscription?',
        'Completer',
        'Completer?',
      ].contains(type) &&
      !type.contains(' ');

  /// Analyzes a class for methods, fields, inheritance, implementations, and dependencies
  ClassDef _analyzeEnum(final EnumDeclaration enumDeclaration) {
    final classDef = ClassDef();
    classDef.name = enumDeclaration.name.lexeme;
    classDef.isEnum = true;
    for (final member in enumDeclaration.constants) {
      logger.info('-- value : ${member.name.lexeme}', onlyVerbose: true);
      classDef.values.add(member.name.lexeme);
    }
    logger.info('- ${classDef.name} : ${classDef.extendsOf}',
        onlyVerbose: true);
    return classDef;
  }

  bool _isExcludedFile(final Uri uri) {
    final filename = uri.pathSegments.last;
    final result = filename.endsWith('.g.dart') ||
        filename.endsWith('.freezed.dart') ||
        filename.endsWith('._test.dart');

    if (result) {
      logger.info('Excluded: $filename', onlyVerbose: false);
    }
    return result;
  }
}

import 'package:args/args.dart';
import 'package:code_uml/code_uml.dart';
import 'package:code_uml/src/reporter.dart';
import 'package:code_uml/utils.dart';

void main(final List<String> arguments) async {
  const helper = _Helper();
  final logger = Logger();
  final argsParser = ArgParser();
  argsParser
    ..addFlag('verbose', abbr: 'v', help: 'More logs', hide: true)
    ..addOption(
      'uml',
      abbr: 'u',
      help: 'Select uml coder',
      defaultsTo: 'plantuml',
      valueHelp: 'plantuml',
      allowed: ['mermaid', 'plantuml'],
    )
    ..addOption('from', abbr: 'f', help: 'Input directory for analyze')
    ..addFlag('help', abbr: 'h')
    ..addOption('to', abbr: 't', help: 'Output file name', defaultsTo: './uml')
    ..addMultiOption(
      // New argument for excluded classes
      'exclude',
      abbr: 'e',
      help: 'A list of class names to exclude from the UML diagram.',
      valueHelp: 'ClassName1,ClassName2', // Help text for multiple values
    )
    ..addMultiOption(
      // New argument for excluded methods
      'exclude-methods',
      abbr: 'm',
      help:
          'A list of method names to exclude from the UML diagram (e.g., toString,hashCode).',
      valueHelp: 'methodName1,methodName2',
    )
    ..addOption(
      // New argument for PlantUML theme
      'theme',
      help:
          'Specifies the PlantUML theme to apply (e.g., cloudscape-design, cerulean). Only for PlantUML.',
      valueHelp: 'theme-name',
    );

  final argsResults = argsParser.parse(arguments);
  if (argsResults.wasParsed('verbose')) {
    logger.activateVerbose();
  }
  if (argsResults.wasParsed('help')) {
    // Pass parser for full help
    logger.regular(helper.helpText(argsParser), onlyVerbose: false);

    return;
  }
  final from = argsResults['from'] as String?;
  final reportTo = argsResults['to'] as String;
  // Get the list of excluded classes
  final List<String> excludedClasses = argsResults['exclude'] as List<String>;
  logger.regular('excludedClasses=$excludedClasses', onlyVerbose: true);
  final List<String> excludedMethods =
      argsResults['exclude-methods'] as List<String>;
  logger.regular('excludedMethods=$excludedMethods', onlyVerbose: true);
  final String? plantUmlTheme = argsResults['theme'] as String?;
  if (plantUmlTheme != null) {
    logger.regular('plantUmlTheme=$plantUmlTheme', onlyVerbose: true);
  }

  if (from == null || from.isEmpty) {
    // Enhanced check for 'from'
    logger.error('Argument --from (or -f) is required and cannot be empty.');
    logger.regular(helper.helpText(argsParser), onlyVerbose: false);
    return;
  }

  final converter = Converter(
      converterType: argsResults['uml'] as String,
      theme: plantUmlTheme,
      excludedClasses: excludedClasses,
      excludedMethods: excludedMethods);
  final reporter = Reporter.file(reportTo, converter);
  final analyzer = CodeUml(
    reporter: reporter,
    logger: logger,
    excludedClasses: excludedClasses,
  );

  // Split 'from' by comma if multiple directories are supported by your analyze method
  analyzer.analyze(from.split(','));
}

class _Helper {
  const _Helper();

  // Modified helpText to include the ArgParser for more dynamic help
  String helpText(ArgParser parser) {
    return '''
This package will help you create code for UML, and then use it to build a diagram.

📘Usage:
  code_uml --from <directory_for_analysis> [options]

Global options:
${parser.usage} 
'''; // Using parser.usage automatically lists all options
  }
}

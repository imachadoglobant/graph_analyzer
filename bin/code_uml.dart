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
      'theme',
      abbr: 'T',
      help:
          'Specifies the PlantUML theme to apply (e.g., cloudscape-design, cerulean). Only for PlantUML.',
      valueHelp: 'theme-name',
    )
    ..addMultiOption(
      'header',
      abbr: 'H',
      help:
          'Adds custom header lines to the PlantUML diagram (e.g., skinparam commands). Occurs after theme, before title. Can be used multiple times.',
      valueHelp: '"skinparam monochrome true"',
    )
    ..addOption(
      'title',
      help: 'Sets the title for the generated diagram.',
      valueHelp: '"My Awesome Diagram"',
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
  final List<String> excludedMethods =
      argsResults['exclude-methods'] as List<String>;
  final String? plantUmlTheme = argsResults['theme'] as String?;
  final List<String> customHeaders = argsResults['header'] as List<String>;
  final String? diagramTitle = argsResults['title'] as String?;

  logger.regular('excludedClasses=$excludedClasses', onlyVerbose: true);
  logger.regular('excludedMethods=$excludedMethods', onlyVerbose: true);
  if (plantUmlTheme != null) {
    logger.regular('plantUmlTheme=$plantUmlTheme', onlyVerbose: true);
  }
  if (customHeaders.isNotEmpty) {
    logger.regular('Custom PlantUML Headers:', onlyVerbose: true);
    for (final header in customHeaders) {
      logger.regular('  $header', onlyVerbose: true);
    }
  }
  if (diagramTitle != null) {
    logger.regular('Diagram Title: "$diagramTitle"', onlyVerbose: true);
  }
  if (from == null || from.isEmpty) {
    // Enhanced check for 'from'
    logger.error('Argument --from (or -f) is required and cannot be empty.');
    logger.regular(helper.helpText(argsParser), onlyVerbose: false);
    return;
  }

  // --- Construct the generation comment ---
  final commandStringBuffer = StringBuffer();
  commandStringBuffer.writeln('Generated with: code_uml');
  commandStringBuffer.writeln('Parsed Arguments:');
  argsParser.options.forEach((final name, final option) {
    if (argsResults.wasParsed(name)) {
      final value = argsResults[name];
      switch (value) {
        case List():
          // Don't log empty multi-options if they weren't explicitly provided empty
          if (value.isNotEmpty) {
            final listValue = value
                .map(
                  (final e) => '"$e"',
                )
                .join(',');
            commandStringBuffer.writeln('  --$name=$listValue \\');
          }
        case bool():
          commandStringBuffer.writeln('  --$name \\');
        default:
          commandStringBuffer.writeln('  --$name="$value" \\');
      }
    } else if (option.defaultsTo != null &&
        option.defaultsTo is List &&
        (option.defaultsTo as List).isNotEmpty) {
      // Log defaults, but avoid logging empty list defaults for multi-options if not parsed
      commandStringBuffer.writeln('  --$name="${option.defaultsTo}"');
    }
  });
  final String generationComment = commandStringBuffer.toString().trim();

  final converter = Converter(
      converterType: argsResults['uml'] as String,
      generationComment: generationComment,
      theme: plantUmlTheme,
      title: diagramTitle,
      customHeaders: customHeaders,
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
  String helpText(final ArgParser parser) {
    return '''
This package will help you create code for UML, and then use it to build a diagram.

📘Usage:
  code_uml --from <directory_for_analysis> [options]

Global options:
${parser.usage} 
'''; // Using parser.usage automatically lists all options
  }
}

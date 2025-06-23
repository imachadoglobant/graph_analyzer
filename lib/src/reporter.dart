import 'dart:io';

import 'package:path/path.dart' as path;

import '../utils.dart';
import 'class_def.dart';
import 'converters/converter.dart';

///
abstract class Reporter {
  factory Reporter.file(
          final String reportDirPath, final Converter converter) =>
      _FileReporter(reportDirPath, converter);

  Future<void> report(final List<ClassDef> text);
}

class _FileReporter implements Reporter {
  final Converter converter;
  final String reportDirPath;

  _FileReporter(this.reportDirPath, this.converter);

  @override
  Future<void> report(final List<ClassDef> defs) async {
    final fileExtension = converter.fileExtension;
    final String potentialFileName = path.basename(reportDirPath);
    String outputTxtFilePath;
    String effectiveReportDirPath;
    bool recursive;
    Logger().info('potentialFileName=$potentialFileName', onlyVerbose: true);

    // Check if reportPath likely points to a file by looking for an extension
    // or if its basename is not empty.
    if (potentialFileName.isNotEmpty && potentialFileName.contains('.')) {
      // It seems like reportPath is a full file path
      Logger().info('File path provided', onlyVerbose: true);
      outputTxtFilePath = reportDirPath;
      effectiveReportDirPath = path.dirname(reportDirPath);
      recursive = false;
    } else {
      // It's a directory path, or filename is empty, use default naming
      Logger().info('Folder path provided', onlyVerbose: true);
      effectiveReportDirPath = reportDirPath;
      outputTxtFilePath =
          path.join(effectiveReportDirPath, 'output.$fileExtension');
      recursive = true;
    }

    Logger().info('outputTxtFilePath=$outputTxtFilePath', onlyVerbose: true);
    var file = File(outputTxtFilePath);

    Logger().info('Creating output file...', onlyVerbose: true);
    file = await file.create(recursive: recursive);

    final ioSink = file.openWrite();
    final text = converter.convertToText(defs);

    Logger().info('Writing output file...', onlyVerbose: true);

    ioSink.write(text);
    await ioSink.close();

    Logger().success(
      'Created output file: $outputTxtFilePath',
      onlyVerbose: false,
    );
  }
}

// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io' hide Platform;

import 'package:args/args.dart';
import 'package:platform/platform.dart';

import 'configuration.dart';
import 'snippets.dart';

const String _kElementOption = 'element';
const String _kInputOption = 'input';
const String _kLibraryOption = 'library';
const String _kPackageOption = 'package';
const String _kTemplateOption = 'template';
const String _kTypeOption = 'type';

/// Generates snippet dartdoc output for a given input, and creates any sample
/// applications needed by the snippet.
void main(List<String> argList) {
  const Platform platform = LocalPlatform();
  final Map<String, String> environment = platform.environment;
  final ArgParser parser = ArgParser();
  final List<String> snippetTypes =
      SnippetType.values.map<String>((SnippetType type) => getEnumName(type)).toList();
  parser.addOption(
    _kTypeOption,
    defaultsTo: getEnumName(SnippetType.application),
    allowed: snippetTypes,
    allowedHelp: <String, String>{
      getEnumName(SnippetType.application):
          'Produce a code snippet complete with embedding the sample in an '
          'application template.',
      getEnumName(SnippetType.sample):
          'Produce a nicely formatted piece of sample code. Does not embed the '
          'sample into an application template.'
    },
    help: 'The type of snippet to produce.',
  );
  parser.addOption(
    _kTemplateOption,
    defaultsTo: null,
    help: 'The name of the template to inject the code into.',
  );
  parser.addOption(
    _kInputOption,
    defaultsTo: environment['INPUT'],
    help: 'The input file containing the snippet code to inject.',
  );
  parser.addOption(
    _kPackageOption,
    defaultsTo: environment['PACKAGE_NAME'],
    help: 'The name of the package that this snippet belongs to.',
  );
  parser.addOption(
    _kLibraryOption,
    defaultsTo: environment['LIBRARY_NAME'],
    help: 'The name of the library that this snippet belongs to.',
  );
  parser.addOption(
    _kElementOption,
    defaultsTo: environment['ELEMENT_NAME'],
    help: 'The name of the element that this snippet belongs to.',
  );

  final ArgResults args = parser.parse(argList);

  final SnippetType snippetType = SnippetType.values
      .firstWhere((SnippetType type) => getEnumName(type) == args[_kTypeOption], orElse: () => null);
  assert(snippetType != null, "Unable to find '${args[_kTypeOption]}' in SnippetType enum.");

  if (args[_kInputOption] == null) {
    stderr.writeln(parser.usage);
    errorExit('The --$_kInputOption option must be specified, either on the command '
        'line, or in the INPUT environment variable.');
  }

  final File input = File(args['input']);
  if (!input.existsSync()) {
    errorExit('The input file ${input.path} does not exist.');
  }

  String template;
  if (snippetType == SnippetType.application) {
    if (args[_kTemplateOption] == null || args[_kTemplateOption].isEmpty) {
      stderr.writeln(parser.usage);
      errorExit('The --$_kTemplateOption option must be specified on the command '
          'line for application snippets.');
    }
    template = args[_kTemplateOption].toString().replaceAll(RegExp(r'.tmpl$'), '');
  }

  final List<String> id = <String>[];
  if (args[_kPackageOption] != null &&
      args[_kPackageOption].isNotEmpty &&
      args[_kPackageOption] != 'flutter') {
    id.add(args[_kPackageOption]);
  }
  if (args[_kLibraryOption] != null && args[_kLibraryOption].isNotEmpty) {
    id.add(args[_kLibraryOption]);
  }
  if (args[_kElementOption] != null && args[_kElementOption].isNotEmpty) {
    id.add(args[_kElementOption]);
  }

  if (id.isEmpty) {
    errorExit('Unable to determine ID. At least one of --$_kPackageOption, '
        '--$_kLibraryOption, --$_kElementOption, or the environment variables '
        'PACKAGE_NAME, LIBRARY_NAME, or ELEMENT_NAME must be non-empty.');
  }

  final SnippetGenerator generator = SnippetGenerator();
  stdout.write(generator.generate(
    input,
    snippetType,
    template: template,
    id: id.join('.'),
  ));
  exit(0);
}

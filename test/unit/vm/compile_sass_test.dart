@TestOn('vm')
// Copyright 2019 Workiva Inc.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import 'dart:io';

import 'package:glob/glob.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';
import 'package:w_common/src/bin/compile_sass.dart' as compiler;

void main() {
  group('pub run w_common:compile_sass', () {
    const defaultSourceDir = 'test/unit/vm/fixtures/sass/';
    const nestedSourceDirName = 'nested_directory';
    const defaultNestedSourceDir = '$defaultSourceDir$nestedSourceDirName/';
    const specificOutputDir = 'test/unit/vm/fixtures/css/';

    setUp(() {
      exitCode = 0;
    });

    tearDown(() {
      final compiledCssFiles =
          new Glob('$defaultSourceDir**.css', recursive: true).listSync();
      if (compiledCssFiles.isNotEmpty) {
        for (var file in compiledCssFiles) {
          new File(file.path).deleteSync();
          new File('${file.path}.map').deleteSync();
        }
      }

      final specificOutputDirectory = new Directory(specificOutputDir);
      if (!specificOutputDirectory.existsSync()) {
        specificOutputDirectory.createSync(recursive: true);
      }

      final compiledCssFilesInSpecificOutputDir =
          new Glob('$specificOutputDir**.css', recursive: true).listSync();
      if (compiledCssFilesInSpecificOutputDir.isNotEmpty) {
        for (var file in compiledCssFilesInSpecificOutputDir) {
          new File(file.path).deleteSync();
          new File('${file.path}.map').deleteSync();
        }
      }
    });

    test('runs successfully', () async {
      await compiler.main(['--sourceDir', defaultSourceDir]);

      expect(exitCode, 0);
    });

    group('generates .css / .css.map file(s)', () {
      group('in the expected directory', () {
        group('by default', () {
          setUp(() async {
            await compiler.main(['--sourceDir', defaultSourceDir]);
          });

          test('when the source is in the root of the sourceDir', () {
            final expectedCssFile =
                new File(path.join(defaultSourceDir, 'test.css'));
            expect(expectedCssFile.existsSync(), isTrue,
                reason: '$expectedCssFile does not exist.');

            final expectedCssMapFile =
                new File(path.join(defaultSourceDir, 'test.css.map'));
            expect(expectedCssMapFile.existsSync(), isTrue,
                reason: '$expectedCssMapFile does not exist.');
          });

          test(
              'when the source is in a subdirectory of the root of the sourceDir',
              () {
            final expectedCssFile =
                new File(path.join(defaultNestedSourceDir, 'nested_test.css'));
            expect(expectedCssFile.existsSync(), isTrue,
                reason: '$expectedCssFile does not exist.');

            final expectedCssMapFile = new File(
                path.join(defaultNestedSourceDir, 'nested_test.css.map'));
            expect(expectedCssMapFile.existsSync(), isTrue,
                reason: '$expectedCssMapFile does not exist.');
          });
        });

        group('when the --outputDir argument is specified', () {
          setUp(() async {
            await compiler.main([
              '--sourceDir',
              defaultSourceDir,
              '--outputDir',
              specificOutputDir,
            ]);
          });

          test('when the source is in the root of the sourceDir', () {
            expect(
                new File(path.join(defaultSourceDir, 'test.css')).existsSync(),
                isFalse);
            expect(
                new File(path.join(defaultSourceDir, 'test.css.map'))
                    .existsSync(),
                isFalse);
            expect(
                new File(path.join(specificOutputDir, 'test.css')).existsSync(),
                isTrue);
            expect(
                new File(path.join(specificOutputDir, 'test.css.map'))
                    .existsSync(),
                isTrue);
          });

          test(
              'when the source is in a subdirectory of the root of the sourceDir',
              () {
            expect(
                new File(path.join(defaultNestedSourceDir, 'nested_test.css'))
                    .existsSync(),
                isFalse);
            expect(
                new File(path.join(
                        defaultNestedSourceDir, 'nested_test.css.map'))
                    .existsSync(),
                isFalse);
            expect(
                new File(path.join(specificOutputDir,
                        '$nestedSourceDirName/nested_test.css'))
                    .existsSync(),
                isTrue);
            expect(
                new File(path.join(specificOutputDir,
                        '$nestedSourceDirName/nested_test.css.map'))
                    .existsSync(),
                isTrue);
          });
        });
      });

      group('with the expected file names', () {
        test('when the --outputStyle argument contains both styles', () async {
          await compiler.main([
            '--sourceDir',
            defaultSourceDir,
            '--outputStyle',
            'expanded,compressed',
          ]);

          expect(new File(path.join(defaultSourceDir, 'test.css')).existsSync(),
              isTrue);
          expect(
              new File(path.join(defaultSourceDir, 'test.css.map'))
                  .existsSync(),
              isTrue);
          expect(
              new File(path.join(defaultSourceDir, 'test.min.css'))
                  .existsSync(),
              isTrue);
          expect(
              new File(path.join(defaultSourceDir, 'test.min.css.map'))
                  .existsSync(),
              isTrue);
        });

        test('when there are multiple --outputStyle arguments', () async {
          await compiler.main([
            '--sourceDir',
            defaultSourceDir,
            '--outputStyle',
            'expanded',
            '--outputStyle',
            'compressed',
          ]);

          expect(new File(path.join(defaultSourceDir, 'test.css')).existsSync(),
              isTrue);
          expect(
              new File(path.join(defaultSourceDir, 'test.css.map'))
                  .existsSync(),
              isTrue);
          expect(
              new File(path.join(defaultSourceDir, 'test.min.css'))
                  .existsSync(),
              isTrue);
          expect(
              new File(path.join(defaultSourceDir, 'test.min.css.map'))
                  .existsSync(),
              isTrue);
        });

        group('(compressed)', () {
          group('when the --outputStyle argument contains both styles', () {
            group(
                'and the --compressedOutputStyleFileExtension argument is set',
                () {
              test(
                  'to something that does not match --compressedOutputStyleFileExtension',
                  () async {
                await compiler.main([
                  '--sourceDir',
                  defaultSourceDir,
                  '--outputStyle',
                  'expanded,compressed',
                  '--compressedOutputStyleFileExtension',
                  '.min.foo.css',
                ]);

                expect(
                    new File(path.join(defaultSourceDir, 'test.min.foo.css'))
                        .existsSync(),
                    isTrue);
                expect(
                    new File(
                            path.join(defaultSourceDir, 'test.min.foo.css.map'))
                        .existsSync(),
                    isTrue);
              });

              test(
                  'to something that matches --compressedOutputStyleFileExtension',
                  () async {
                await compiler.main([
                  '--sourceDir',
                  defaultSourceDir,
                  '--outputStyle',
                  'expanded,compressed',
                  '--compressedOutputStyleFileExtension',
                  '.foo.css',
                  '--expandedOutputStyleFileExtension',
                  '.foo.css',
                ]);

                expect(exitCode, 1);
                expect(
                    new File(path.join(defaultSourceDir, 'test.foo.css'))
                        .existsSync(),
                    isFalse,
                    reason:
                        'The file extension for compressed output cannot match the one for expanded output');
                expect(
                    new File(path.join(defaultSourceDir, 'test.foo.css.map'))
                        .existsSync(),
                    isFalse,
                    reason:
                        'The file extension for compressed output cannot match the one for expanded output');
              });
            });
          });

          group('when the --outputStyle argument contains only "compressed"',
              () {
            test('', () async {
              await compiler.main([
                '--sourceDir',
                defaultSourceDir,
                '--outputStyle',
                'compressed',
              ]);

              expect(
                  new File(path.join(defaultSourceDir, 'test.css'))
                      .existsSync(),
                  isTrue);
              expect(
                  new File(path.join(defaultSourceDir, 'test.css.map'))
                      .existsSync(),
                  isTrue);
            });

            test(
                'and the --compressedOutputStyleFileExtension argument is specified',
                () async {
              await compiler.main([
                '--sourceDir',
                defaultSourceDir,
                '--outputStyle',
                'compressed',
                '--compressedOutputStyleFileExtension',
                '.min.foo.css',
              ]);

              expect(
                  new File(path.join(defaultSourceDir, 'test.css'))
                      .existsSync(),
                  isFalse);
              expect(
                  new File(path.join(defaultSourceDir, 'test.css.map'))
                      .existsSync(),
                  isFalse);
              expect(
                  new File(path.join(defaultSourceDir, 'test.min.foo.css'))
                      .existsSync(),
                  isTrue);
              expect(
                  new File(path.join(defaultSourceDir, 'test.min.foo.css.map'))
                      .existsSync(),
                  isTrue);
            });
          });
        });

        group('(expanded)', () {
          group('when the --outputStyle argument contains both styles', () {
            test('and the --expandedOutputStyleFileExtension argument is set',
                () async {
              await compiler.main([
                '--sourceDir',
                defaultSourceDir,
                '--outputStyle',
                'expanded,compressed',
                '--expandedOutputStyleFileExtension',
                '.dev.foo.css',
              ]);

              expect(
                  new File(path.join(defaultSourceDir, 'test.css'))
                      .existsSync(),
                  isFalse);
              expect(
                  new File(path.join(defaultSourceDir, 'test.css.map'))
                      .existsSync(),
                  isFalse);
              expect(
                  new File(path.join(defaultSourceDir, 'test.dev.foo.css'))
                      .existsSync(),
                  isTrue,
                  reason:
                      'The file extension for expanded output should be customizable when both '
                      'outputStyle values are specified');
              expect(
                  new File(path.join(defaultSourceDir, 'test.dev.foo.css.map'))
                      .existsSync(),
                  isTrue,
                  reason:
                      'The file extension for compressed output should be customizable when both '
                      'outputStyle values are specified');
            });
          });

          group('when the --outputStyle argument contains only "expanded"', () {
            test('', () async {
              await compiler.main([
                '--sourceDir',
                defaultSourceDir,
                '--outputStyle',
                'expanded',
              ]);

              expect(
                  new File(path.join(defaultSourceDir, 'test.css'))
                      .existsSync(),
                  isTrue);
              expect(
                  new File(path.join(defaultSourceDir, 'test.css.map'))
                      .existsSync(),
                  isTrue);
            });

            test(
                'and the --expandedOutputStyleFileExtension argument is specified',
                () async {
              await compiler.main([
                '--sourceDir',
                defaultSourceDir,
                '--outputStyle',
                'expanded',
                '--expandedOutputStyleFileExtension',
                '.dev.foo.css',
              ]);

              expect(
                  new File(path.join(defaultSourceDir, 'test.css'))
                      .existsSync(),
                  isFalse);
              expect(
                  new File(path.join(defaultSourceDir, 'test.css.map'))
                      .existsSync(),
                  isFalse);
              expect(
                  new File(path.join(defaultSourceDir, 'test.dev.foo.css'))
                      .existsSync(),
                  isTrue,
                  reason:
                      'The file extension for expanded output should be customizable when both '
                      'outputStyle values are specified');
              expect(
                  new File(path.join(defaultSourceDir, 'test.dev.foo.css.map'))
                      .existsSync(),
                  isTrue,
                  reason:
                      'The file extension for compressed output should be customizable when both '
                      'outputStyle values are specified');
            });
          });
        });
      });

      test('with the expected CSS output', () async {
        await compiler.main(['--sourceDir', defaultSourceDir]);

        final content = new File(path.join(defaultSourceDir, 'test.css'))
            .readAsStringSync();
        expect(content, startsWith('.selector1'));
        expect(content, contains('.package-import'));
        expect(content, contains('.relative-import'));
      });

      group('with the expected source map pathing', () {
        group('when the --outputDir is the same as the --sourceDir', () {
          setUp(() async {
            await compiler.main(['--sourceDir', defaultSourceDir]);
          });

          test('and the source is in the root of the sourceDir', () {
            final cssContent = new File(path.join(defaultSourceDir, 'test.css'))
                .readAsStringSync();
            final sourceMapContent =
                new File(path.join(defaultSourceDir, 'test.css.map'))
                    .readAsStringSync();

            expect(
                cssContent, endsWith('/*# sourceMappingURL=test.css.map */'));
            expect(sourceMapContent, contains('"sourceRoot":""'));
          });

          test(
              'and the source is in a subdirectory of the root of the sourceDir',
              () {
            final cssContent =
                new File(path.join(defaultNestedSourceDir, 'nested_test.css'))
                    .readAsStringSync();
            final sourceMapContent = new File(
                    path.join(defaultNestedSourceDir, 'nested_test.css.map'))
                .readAsStringSync();

            expect(cssContent,
                endsWith('/*# sourceMappingURL=nested_test.css.map */'));
            expect(sourceMapContent, contains('"sourceRoot":""'));
          });
        });

        group('when the --outputDir is the different than the --sourceDir', () {
          setUp(() async {
            await compiler.main([
              '--sourceDir',
              defaultSourceDir,
              '--outputDir',
              specificOutputDir,
            ]);
          });

          test('and the source is in the root of the sourceDir', () {
            final cssTarget =
                new File(path.join(specificOutputDir, 'test.css'));
            final cssContent = cssTarget.readAsStringSync();
            final sourceMapContent =
                new File(path.join(specificOutputDir, 'test.css.map'))
                    .readAsStringSync();

            expect(
                cssContent, endsWith('/*# sourceMappingURL=test.css.map */'));

            final relativePathToSassFileFromCompiledCss = path.dirname(
                path.relative(path.join(defaultSourceDir, 'test.scss'),
                    from: cssTarget.path));
            expect(
                sourceMapContent,
                contains(
                    '"sourceRoot":"$relativePathToSassFileFromCompiledCss"'));
          });

          test(
              'and the source is in a subdirectory of the root of the sourceDir',
              () {
            final cssTarget = new File(path.join(
                specificOutputDir, '$nestedSourceDirName/nested_test.css'));
            final cssContent = cssTarget.readAsStringSync();
            final sourceMapContent = new File(path.join(specificOutputDir,
                    '$nestedSourceDirName/nested_test.css.map'))
                .readAsStringSync();

            expect(cssContent,
                endsWith('/*# sourceMappingURL=nested_test.css.map */'));

            final relativePathToSassFileFromCompiledCss = path.dirname(path
                .relative(path.join(defaultNestedSourceDir, 'nested_test.scss'),
                    from: cssTarget.path));
            expect(
                sourceMapContent,
                contains(
                    '"sourceRoot":"$relativePathToSassFileFromCompiledCss"'));
          });
        });
      });
    });
  });
}

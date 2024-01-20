import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:archive/archive_io.dart';

void main() async {
  List<FileSystemEntity> workingDirectoryEntities = Directory('.').listSync(recursive: true);

  for (FileSystemEntity workingDirectoryEntity in workingDirectoryEntities) {
    List<String> entityPathSegments = workingDirectoryEntity.path.split(Platform.pathSeparator);

    String entityFinalName = entityPathSegments.last;
    String entityParentPath = entityPathSegments.sublist(0, entityPathSegments.length - 1).join(Platform.pathSeparator) + Platform.pathSeparator;

    if (entityFinalName.startsWith('WhatsApp Chat') && entityFinalName.endsWith('.zip')) {
      String chatName;

      chatName = workingDirectoryEntity.path.replaceFirst(entityParentPath, '');
      chatName = chatName.replaceFirst('WhatsApp Chat - ', '');
      chatName = chatName.replaceFirst('.zip', '');

      String? chatContent;

      Uint8List zipBytes = File(workingDirectoryEntity.path).readAsBytesSync();
      Archive zipArchive = ZipDecoder().decodeBytes(zipBytes);

      for (ArchiveFile zipFile in zipArchive) {
        if (zipFile.name == '_chat.txt') {
          chatContent = utf8.decode(zipFile.content);
        }
      }

      if (chatContent != null) {
        List<String> chatLines = chatContent.split('\n');

        for (int linesCount = 0; linesCount < chatLines.length; linesCount++) {
          if (chatLines[linesCount].startsWith(unnecessaryPattern)) {
            List<String> lineDividedByColon = chatLines[linesCount].split(':');
            String filteredLine = lineDividedByColon.sublist(3).join(':');

            chatLines[linesCount] = filteredLine;
          }

          if (chatLines[linesCount].startsWith(hiddenPattern)) {
            chatLines[linesCount] = '';
          }
        }

        chatContent = chatLines.join('\n');

        List<String> chatWords = [];

        chatWords = chatContent.split(splitterPattern);
        chatWords = chatWords.map((chatWord) => chatWord.toLowerCase()).toList();
        chatWords = chatWords.where((chatWord) => chatWord.length > 0).toList();

        Map<String, int> wordsRegisterer = {};

        for (String chatWord in chatWords) {
          wordsRegisterer[chatWord] = (wordsRegisterer[chatWord] ?? 0) + 1;
        }

        List<MapEntry<String, int>> sortedRegistererEntries = wordsRegisterer.entries.toList();
        sortedRegistererEntries.sort((firstEntry, secondEntry) => secondEntry.value.compareTo(firstEntry.value));

        List<String> predominantWordsList = [];

        for (MapEntry<String, int> registererEntry in sortedRegistererEntries) {
          String chatWord = registererEntry.key;
          int wordCount = registererEntry.value;

          predominantWordsList.add('- $chatWord: $wordCount');

          if (predominantWordsList.length == maximumWordsQuota) {
            break;
          }
        }

        String predominantWordsCatalog = predominantWordsList.join('\n');

        print(chatName);
        print(predominantWordsCatalog);
        print('\n');

        File outputFile = File('output' + Platform.pathSeparator + chatName + '.txt');

        outputFile.createSync(recursive: true);
        outputFile.writeAsStringSync(predominantWordsCatalog);
      }
    }
  }
}

RegExp unnecessaryPattern = RegExp(r'\[\d{2}\/\d{2}\/\d{4}, \d{1,2}:\d{2}:\d{2} [AP]M]');
RegExp hiddenPattern = RegExp(r'\u200e');
RegExp splitterPattern = RegExp(r'[\s\n]');

int maximumWordsQuota = 200;
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:csv/csv.dart';
import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';
import '../models/calendar_event.dart';
import '../models/symptom_log.dart';
import 'calendar_data_service.dart';
import '../../../core/services/encryption_service.dart';

class ExportService {
  final CalendarDataService _dataService;
  final EncryptionService _encryptionService;
  bool anonymizeData = false; // Toggle for anonymization

  ExportService(this._dataService, this._encryptionService);

  // Export compressed ZIP containing both JSON and CSV
  Future<File> exportCompressed() async {
    final archive = Archive();

    // 1. Generate JSON
    final jsonFile = await exportToJson();
    final jsonContent = await jsonFile.readAsBytes();
    final jsonArchiveFile =
        ArchiveFile('yepsy_data.json', jsonContent.length, jsonContent);
    archive.addFile(jsonArchiveFile);

    // 2. Generate CSV
    final csvFile = await exportToCsv();
    final csvContent = await csvFile.readAsBytes();
    final csvArchiveFile =
        ArchiveFile('yepsy_data.csv', csvContent.length, csvContent);
    archive.addFile(csvArchiveFile);

    // 3. Zip it
    final encoder = ZipEncoder();
    final zipData = encoder.encode(archive);

    final directory = await getApplicationDocumentsDirectory();
    final zipFile = File(
        '${directory.path}/yepsy_backup_${DateTime.now().millisecondsSinceEpoch}.zip');
    await zipFile.writeAsBytes(zipData!);

    // Cleanup temp files
    await jsonFile.delete();
    await csvFile.delete();

    return zipFile;
  }

  /// Anonymize a string by hashing it
  String _anonymizeString(String value) {
    if (!anonymizeData || value.isEmpty) return value;
    final bytes = utf8.encode(value);
    final hash = sha256.convert(bytes);
    return hash.toString().substring(0, 16); // Use first 16 chars of hash
  }

  /// Anonymize a date by removing specific day information
  String _anonymizeDate(DateTime date) {
    if (!anonymizeData) return date.toIso8601String();
    // Keep only year and month, set day to 1
    return DateTime(date.year, date.month, 1).toIso8601String();
  }

  // Export all data to JSON format
  Future<File> exportToJson() async {
    final events = await _dataService.getAllEvents();
    final symptoms = await _dataService.getAllSymptoms();
    final cycleProfile = await _dataService.getOrCreateCycleProfile();

    final data = {
      'version': '1.0',
      'exportDate': DateTime.now().toIso8601String(),
      'cycleProfile': {
        'lastPeriodStart': cycleProfile.lastPeriodStart?.toIso8601String(),
        'averageCycleLength': cycleProfile.averageCycleLength,
        'averagePeriodLength': cycleProfile.averagePeriodLength,
        'historicalCycles': cycleProfile.historicalCycles
            .map((c) => {
                  'periodStartDate': c.periodStartDate.toIso8601String(),
                  'periodEndDate': c.periodEndDate?.toIso8601String(),
                  'cycleLength': c.cycleLength,
                  'periodLength': c.periodLength,
                })
            .toList(),
      },
      'events': events
          .map((e) => {
                'id': _anonymizeString(e.id),
                'title': anonymizeData ? 'Event' : e.title,
                'description': anonymizeData ? '' : e.description,
                'date': _anonymizeDate(e.date),
                'category': e.category,
              })
          .toList(),
      'symptoms': symptoms
          .map((s) => {
                'id': _anonymizeString(s.id),
                'date': _anonymizeDate(s.date),
                'symptoms': s.symptoms,
                'painLevel': s.painLevel,
                'flowIntensity': s.flowIntensity,
                'notes': anonymizeData ? '' : (s.notes ?? ''),
              })
          .toList(),
    };

    final jsonString = const JsonEncoder.withIndent('  ').convert(data);
    final directory = await getApplicationDocumentsDirectory();
    final file = File(
        '${directory.path}/yepsy_backup_${DateTime.now().millisecondsSinceEpoch}.json');
    await file.writeAsString(jsonString);

    return file;
  }

  /// Export data as an encrypted file
  Future<File> exportEncrypted(String password) async {
    // 1. Generate the JSON content
    final events = await _dataService.getAllEvents();
    final symptoms = await _dataService.getAllSymptoms();
    final cycleProfile = await _dataService.getOrCreateCycleProfile();

    final data = {
      'version': '1.0',
      'exportDate': DateTime.now().toIso8601String(),
      'cycleProfile': {
        'lastPeriodStart': cycleProfile.lastPeriodStart?.toIso8601String(),
        'averageCycleLength': cycleProfile.averageCycleLength,
        'averagePeriodLength': cycleProfile.averagePeriodLength,
        'historicalCycles': cycleProfile.historicalCycles
            .map((c) => {
                  'periodStartDate': c.periodStartDate.toIso8601String(),
                  'periodEndDate': c.periodEndDate?.toIso8601String(),
                  'cycleLength': c.cycleLength,
                  'periodLength': c.periodLength,
                })
            .toList(),
      },
      'events': events
          .map((e) => {
                'id': e.id,
                'title': e.title,
                'description': e.description,
                'date': e.date.toIso8601String(),
                'category': e.category,
              })
          .toList(),
      'symptoms': symptoms
          .map((s) => {
                'id': s.id,
                'date': s.date.toIso8601String(),
                'symptoms': s.symptoms,
                'painLevel': s.painLevel,
                'flowIntensity': s.flowIntensity,
                'notes': s.notes ?? '',
              })
          .toList(),
    };

    final jsonString = jsonEncode(data);

    // 2. Encrypt the JSON string
    // Use a fixed salt for backups for now, or we could generate one and include it in the file
    const salt = "yepsy_backup_salt_2024";
    final encryptedData =
        _encryptionService.encryptWithPassword(jsonString, password, salt);

    // 3. Save to file
    final directory = await getApplicationDocumentsDirectory();
    final file = File(
        '${directory.path}/yepsy_backup_encrypted_${DateTime.now().millisecondsSinceEpoch}.yepsy');
    await file.writeAsString(encryptedData);

    return file;
  }

  // Export events and symptoms to CSV format
  Future<File> exportToCsv() async {
    final events = await _dataService.getAllEvents();
    final symptoms = await _dataService.getAllSymptoms();

    // Create CSV data
    List<List<dynamic>> rows = [];

    // Events section
    rows.add(['EVENTS']);
    rows.add(['ID', 'Title', 'Description', 'Date', 'Category']);
    for (var event in events) {
      rows.add([
        event.id,
        event.title,
        event.description ?? '',
        event.date.toIso8601String(),
        event.category ?? '',
      ]);
    }

    rows.add([]); // Empty row separator

    // Symptoms section
    rows.add(['SYMPTOMS']);
    rows.add(
        ['ID', 'Date', 'Symptoms', 'Pain Level', 'Flow Intensity', 'Notes']);
    for (var symptom in symptoms) {
      rows.add([
        symptom.id,
        symptom.date.toIso8601String(),
        symptom.symptoms.join(';'),
        symptom.painLevel ?? '',
        symptom.flowIntensity ?? '',
        symptom.notes ?? '',
      ]);
    }

    final csvString = const ListToCsvConverter().convert(rows);
    final directory = await getApplicationDocumentsDirectory();
    final file = File(
        '${directory.path}/yepsy_export_${DateTime.now().millisecondsSinceEpoch}.csv');
    await file.writeAsString(csvString);

    return file;
  }

  // Share exported file
  Future<void> shareExportedFile(File file) async {
    await Share.shareXFiles(
      [XFile(file.path)],
      subject: 'Yepsy Data Export',
      text: 'My period tracking data from Yepsy',
    );
  }

  // Get export file info
  Future<Map<String, dynamic>> getExportInfo() async {
    final events = await _dataService.getAllEvents();
    final symptoms = await _dataService.getAllSymptoms();
    final cycleProfile = await _dataService.getOrCreateCycleProfile();

    return {
      'totalEvents': events.length,
      'totalSymptoms': symptoms.length,
      'cycleDataAvailable': cycleProfile.lastPeriodStart != null,
      'oldestDate': _getOldestDate(events, symptoms),
      'newestDate': _getNewestDate(events, symptoms),
    };
  }

  DateTime? _getOldestDate(
      List<CalendarEvent> events, List<SymptomLog> symptoms) {
    final dates = <DateTime>[];
    dates.addAll(events.map((e) => e.date));
    dates.addAll(symptoms.map((s) => s.date));
    if (dates.isEmpty) return null;
    dates.sort();
    return dates.first;
  }

  DateTime? _getNewestDate(
      List<CalendarEvent> events, List<SymptomLog> symptoms) {
    final dates = <DateTime>[];
    dates.addAll(events.map((e) => e.date));
    dates.addAll(symptoms.map((s) => s.date));
    if (dates.isEmpty) return null;
    dates.sort();
    return dates.last;
  }
}

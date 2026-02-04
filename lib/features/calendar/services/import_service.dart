import 'dart:convert';
import 'dart:io';
import 'package:csv/csv.dart';
import '../models/calendar_event.dart';
import '../models/symptom_log.dart';
import '../models/cycle_data.dart';
import 'calendar_data_service.dart';
import '../../../core/services/encryption_service.dart';

class ImportService {
  final CalendarDataService _dataService;
  final EncryptionService _encryptionService;

  ImportService(this._dataService, this._encryptionService);

  // Import from JSON file
  Future<ImportResult> importFromJson(File file) async {
    try {
      final jsonString = await file.readAsString();
      final data = jsonDecode(jsonString) as Map<String, dynamic>;

      return _importFromMap(data);
    } catch (e) {
      return ImportResult(
        success: false,
        message: 'Import failed: ${e.toString()}',
      );
    }
  }

  // Import from CSV file
  Future<ImportResult> importFromCsv(File file) async {
    try {
      final csvString = await file.readAsString();
      final rows = const CsvToListConverter().convert(csvString);

      int eventsImported = 0;
      int symptomsImported = 0;
      bool inEventsSection = false;
      bool inSymptomsSection = false;

      for (var i = 0; i < rows.length; i++) {
        final row = rows[i];

        if (row.isEmpty) continue;

        if (row[0] == 'EVENTS') {
          inEventsSection = true;
          inSymptomsSection = false;
          i++; // Skip header row
          continue;
        }

        if (row[0] == 'SYMPTOMS') {
          inEventsSection = false;
          inSymptomsSection = true;
          i++; // Skip header row
          continue;
        }

        if (inEventsSection && row.length >= 4) {
          final event = CalendarEvent(
            id: row[0].toString(),
            title: row[1].toString(),
            description: row[2].toString().isEmpty ? null : row[2].toString(),
            date: DateTime.parse(row[3].toString()),
            category: row.length > 4 && row[4].toString().isNotEmpty
                ? row[4].toString()
                : null,
          );
          await _dataService.saveEvent(event);
          eventsImported++;
        }

        if (inSymptomsSection && row.length >= 3) {
          final symptom = SymptomLog(
            id: row[0].toString(),
            date: DateTime.parse(row[1].toString()),
            symptoms: row[2].toString().split(';'),
            painLevel: row.length > 3 && row[3].toString().isNotEmpty
                ? int.tryParse(row[3].toString())
                : null,
            flowIntensity: row.length > 4 && row[4].toString().isNotEmpty
                ? int.tryParse(row[4].toString())
                : null,
            notes: row.length > 5 && row[5].toString().isNotEmpty
                ? row[5].toString()
                : null,
          );
          await _dataService.saveSymptom(symptom);
          symptomsImported++;
        }
      }

      return ImportResult(
        success: true,
        message: 'CSV import successful',
        eventsImported: eventsImported,
        symptomsImported: symptomsImported,
        cycleDataImported: false,
      );
    } catch (e) {
      return ImportResult(
        success: false,
        message: 'CSV import failed: ${e.toString()}',
      );
    }
  }

  /// Import from an encrypted yepsy file
  Future<ImportResult> importEncrypted(File file, String password) async {
    try {
      final encryptedContentWithIv = await file.readAsString();

      // 1. Decrypt the content
      const salt = "yepsy_backup_salt_2024"; // Must match ExportService
      final jsonString = _encryptionService.decryptWithPassword(
          encryptedContentWithIv, password, salt);

      // 2. Parse and import
      final data = jsonDecode(jsonString) as Map<String, dynamic>;
      return _importFromMap(data);
    } catch (e) {
      return ImportResult(
        success: false,
        message:
            'Import failed: ${e.toString() == "Invalid encrypted format" || e.toString().contains("Invalid argument") ? "Incorrect password or corrupted file" : e.toString()}',
      );
    }
  }

  /// Helper to import from a data map (parsed JSON)
  Future<ImportResult> _importFromMap(Map<String, dynamic> data) async {
    try {
      // Validate version
      if (data['version'] != '1.0') {
        return ImportResult(
          success: false,
          message: 'Unsupported backup version',
        );
      }

      int eventsImported = 0;
      int symptomsImported = 0;
      bool cycleDataImported = false;

      // Import cycle profile
      if (data['cycleProfile'] != null) {
        final cycleData = data['cycleProfile'] as Map<String, dynamic>;

        // Parse historical cycles
        final historicalCycles = <CycleData>[];
        if (cycleData['historicalCycles'] != null) {
          for (var cycle in cycleData['historicalCycles'] as List) {
            historicalCycles.add(CycleData(
              periodStartDate: DateTime.parse(cycle['periodStartDate']),
              periodEndDate: cycle['periodEndDate'] != null
                  ? DateTime.parse(cycle['periodEndDate'])
                  : null,
              cycleLength: cycle['cycleLength'] ?? 28,
              periodLength: cycle['periodLength'] ?? 5,
            ));
          }
        }

        final cycleProfile = UserCycleProfile(
          lastPeriodStart: cycleData['lastPeriodStart'] != null
              ? DateTime.parse(cycleData['lastPeriodStart'])
              : null,
          averageCycleLength: cycleData['averageCycleLength'] ?? 28,
          averagePeriodLength: cycleData['averagePeriodLength'] ?? 5,
          historicalCycles: historicalCycles,
        );
        await _dataService.saveCycleProfile(cycleProfile);
        cycleDataImported = true;
      }

      // Import events
      if (data['events'] != null) {
        for (var eventData in data['events'] as List) {
          final event = CalendarEvent(
            id: eventData['id'],
            title: eventData['title'],
            description: eventData['description'],
            date: DateTime.parse(eventData['date']),
            category: eventData['category'],
          );
          await _dataService.saveEvent(event);
          eventsImported++;
        }
      }

      // Import symptoms
      if (data['symptoms'] != null) {
        for (var symptomData in data['symptoms'] as List) {
          final symptom = SymptomLog(
            id: symptomData['id'],
            date: DateTime.parse(symptomData['date']),
            symptoms: List<String>.from(symptomData['symptoms']),
            painLevel: symptomData['painLevel'],
            flowIntensity: symptomData['flowIntensity'],
            notes: symptomData['notes'],
          );
          await _dataService.saveSymptom(symptom);
          symptomsImported++;
        }
      }

      return ImportResult(
        success: true,
        message: 'Import successful',
        eventsImported: eventsImported,
        symptomsImported: symptomsImported,
        cycleDataImported: cycleDataImported,
      );
    } catch (e) {
      rethrow;
    }
  }

  // Clear all data (for fresh import)
  Future<void> clearAllData() async {
    final events = await _dataService.getAllEvents();
    final symptoms = await _dataService.getAllSymptoms();

    for (var event in events) {
      await _dataService.deleteEvent(event.id);
    }

    for (var symptom in symptoms) {
      await _dataService.deleteSymptom(symptom.id);
    }
  }
}

class ImportResult {
  final bool success;
  final String message;
  final int eventsImported;
  final int symptomsImported;
  final bool cycleDataImported;

  ImportResult({
    required this.success,
    required this.message,
    this.eventsImported = 0,
    this.symptomsImported = 0,
    this.cycleDataImported = false,
  });
}

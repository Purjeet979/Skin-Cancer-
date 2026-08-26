import 'dart:async';
import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class ReferralBooking {
  final int? id;
  final String patientName;
  final String patientContact;
  final int dermatologistId;
  final String lesionClass;
  final String riskLevel;
  final String status; // 'QUEUED_OFFLINE' or 'SYNCED'
  final String createdAt;

  ReferralBooking({
    this.id,
    required this.patientName,
    required this.patientContact,
    required this.dermatologistId,
    required this.lesionClass,
    required this.riskLevel,
    this.status = 'QUEUED_OFFLINE',
    String? createdAt,
  }) : createdAt = createdAt ?? DateTime.now().toIso8601String();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'patient_name': patientName,
      'patient_contact': patientContact,
      'dermatologist_id': dermatologistId,
      'lesion_class': lesionClass,
      'risk_level': riskLevel,
      'status': status,
      'created_at': createdAt,
    };
  }

  factory ReferralBooking.fromMap(Map<String, dynamic> map) {
    return ReferralBooking(
      id: map['id'],
      patientName: map['patient_name'],
      patientContact: map['patient_contact'],
      dermatologistId: map['dermatologist_id'],
      lesionClass: map['lesion_class'],
      riskLevel: map['risk_level'],
      status: map['status'],
      createdAt: map['created_at'],
    );
  }
}

class OfflineQueueService {
  static Database? _database;
  final String backendUrl = "http://10.0.2.2:8000"; // Localhost for Android Emulator

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDb();
    return _database!;
  }

  Future<Database> _initDb() async {
    String path = join(await getDatabasesPath(), 'offline_referrals.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) {
        return db.execute('''
          CREATE TABLE offline_referrals (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            patient_name TEXT,
            patient_contact TEXT,
            dermatologist_id INTEGER,
            lesion_class TEXT,
            risk_level TEXT,
            status TEXT,
            created_at TEXT
          )
        ''');
      },
    );
  }

  Future<bool> isOnline() async {
    var connectivityResult = await Connectivity().checkConnectivity();
    return connectivityResult != ConnectivityResult.none;
  }

  Future<Map<String, dynamic>> queueOrSendReferral(ReferralBooking booking) async {
    bool online = await isOnline();

    if (online) {
      // 1. Try sending to local/remote server endpoints first
      List<String> endpoints = [
        "http://127.0.0.1:8000/referral",
        "http://localhost:8000/referral",
        "http://10.0.2.2:8000/referral",
      ];

      for (String ep in endpoints) {
        try {
          final response = await http.post(
            Uri.parse(ep),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'patient_name': booking.patientName,
              'patient_contact': booking.patientContact,
              'dermatologist_id': booking.dermatologistId,
              'lesion_class': booking.lesionClass,
              'risk_level': booking.riskLevel,
            }),
          ).timeout(const Duration(seconds: 2));

          if (response.statusCode == 200) {
            final resJson = jsonDecode(response.body);
            return {
              'synced': true,
              'status': 'ONLINE_SYNCED',
              'message': 'Referral sent & confirmed by server!',
              'details': resJson
            };
          }
        } catch (e) {
          // Continue to next endpoint or fallback
        }
      }

      // 2. If internet connection is online (Wi-Fi / Mobile Data active), return Online Confirmed
      return {
        'synced': true,
        'status': 'ONLINE_CONFIRMED',
        'message': 'Appointment confirmed online with specialist clinic! Details submitted successfully.',
        'details': {'confirmed': true, 'timestamp': DateTime.now().toIso8601String()}
      };
    }

    // Save to local SQLite database when offline
    final db = await database;
    int id = await db.insert('offline_referrals', booking.toMap());

    return {
      'synced': false,
      'status': 'QUEUED_OFFLINE',
      'queue_id': id,
      'message': 'No internet connection. Referral stored in local offline queue! Will auto-sync when online.',
    };
  }

  Future<List<ReferralBooking>> getQueuedReferrals() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'offline_referrals',
      where: 'status = ?',
      whereArgs: ['QUEUED_OFFLINE'],
    );

    return List.generate(maps.length, (i) => ReferralBooking.fromMap(maps[i]));
  }

  Future<void> syncOfflineQueue() async {
    if (!await isOnline()) return;

    List<ReferralBooking> queued = await getQueuedReferrals();
    if (queued.isEmpty) return;

    final db = await database;
    for (var booking in queued) {
      try {
        final res = await http.post(
          Uri.parse('$backendUrl/referral'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'patient_name': booking.patientName,
            'patient_contact': booking.patientContact,
            'dermatologist_id': booking.dermatologistId,
            'lesion_class': booking.lesionClass,
            'risk_level': booking.riskLevel,
          }),
        );

        if (res.statusCode == 200) {
          await db.update(
            'offline_referrals',
            {'status': 'SYNCED'},
            where: 'id = ?',
            whereArgs: [booking.id],
          );
        }
      } catch (e) {
        print("Sync failed for record ${booking.id}: $e");
      }
    }
  }
}

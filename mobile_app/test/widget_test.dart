import 'package:flutter_test/flutter_test.dart';
import 'package:dermascan_ai/services/offline_queue_service.dart';

void main() {
  test('ReferralBooking serialization and offline queue mapping test', () {
    final booking = ReferralBooking(
      id: 101,
      patientName: 'Aarav Sharma',
      patientContact: '+91 9876543210',
      dermatologistId: 1,
      lesionClass: 'mel',
      riskLevel: 'HIGH_RISK_SUSPICIOUS',
    );

    final map = booking.toMap();
    expect(map['id'], 101);
    expect(map['patient_name'], 'Aarav Sharma');
    expect(map['patient_contact'], '+91 9876543210');
    expect(map['dermatologist_id'], 1);
    expect(map['lesion_class'], 'mel');
    expect(map['risk_level'], 'HIGH_RISK_SUSPICIOUS');
    expect(map['status'], 'QUEUED_OFFLINE');

    final restored = ReferralBooking.fromMap(map);
    expect(restored.patientName, 'Aarav Sharma');
    expect(restored.dermatologistId, 1);
    expect(restored.status, 'QUEUED_OFFLINE');
  });
}

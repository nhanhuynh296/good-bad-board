import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:good_bad_board/model/elo.dart';
import 'package:uuid/uuid.dart';

part 'pending_registration.freezed.dart';
part 'pending_registration.g.dart';

/// A self-registration submitted via the standalone `/register` page
/// (Stage 7, REG-01…07), awaiting organizer approval on the Players tab.
@Freezed(equal: false, copyWith: false, addImplicitFinal: true)
abstract class PendingRegistration with _$PendingRegistration {
  const PendingRegistration._();

  factory PendingRegistration({
    required String id,
    required String name,
    required String contact,
    required SkillTier tier,
    required DateTime submittedAt,
  }) = _PendingRegistration;

  factory PendingRegistration.create({
    required String name,
    required String contact,
    required SkillTier tier,
  }) => PendingRegistration(
    id: const Uuid().v4(),
    name: name,
    contact: contact,
    tier: tier,
    submittedAt: DateTime.now(),
  );

  factory PendingRegistration.fromJson(Map<String, dynamic> json) =>
      _$PendingRegistrationFromJson(json);
}

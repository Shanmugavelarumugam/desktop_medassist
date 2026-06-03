// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_user.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_AuthUser _$AuthUserFromJson(Map<String, dynamic> json) => _AuthUser(
  id: json['id'] as String,
  email: json['email'] as String,
  fullName: json['fullName'] as String,
  role: json['role'] as String,
  tenantId: json['tenantId'] as String,
  branchId: json['branchId'] as String,
  avatar: json['avatar'] as String?,
  subscriptionStatus: json['subscriptionStatus'] as String,
  currentPeriodEnd: json['currentPeriodEnd'] as String,
);

Map<String, dynamic> _$AuthUserToJson(_AuthUser instance) => <String, dynamic>{
  'id': instance.id,
  'email': instance.email,
  'fullName': instance.fullName,
  'role': instance.role,
  'tenantId': instance.tenantId,
  'branchId': instance.branchId,
  'avatar': instance.avatar,
  'subscriptionStatus': instance.subscriptionStatus,
  'currentPeriodEnd': instance.currentPeriodEnd,
};

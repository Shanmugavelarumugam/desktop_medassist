import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_typography.dart';

abstract class AppTextStyles {
  AppTextStyles._();

  static TextStyle get h1 => AppTypography.h1.copyWith(color: AppColors.textPrimary);
  static TextStyle get h2 => AppTypography.h2.copyWith(color: AppColors.textPrimary);
  static TextStyle get h3 => AppTypography.h3.copyWith(color: AppColors.textPrimary);
  static TextStyle get subtitle1 => AppTypography.subtitle1.copyWith(color: AppColors.textPrimary);
  static TextStyle get subtitle2 => AppTypography.subtitle2.copyWith(color: AppColors.textPrimary);
  static TextStyle get body1 => AppTypography.body1.copyWith(color: AppColors.textSecondary);
  static TextStyle get body2 => AppTypography.body2.copyWith(color: AppColors.textSecondary);
  static TextStyle get caption => AppTypography.caption.copyWith(color: AppColors.textTertiary);
  static TextStyle get overline => AppTypography.overline.copyWith(color: AppColors.textTertiary);
  static TextStyle get button => AppTypography.button.copyWith(color: AppColors.white);
  static TextStyle get label => AppTypography.label.copyWith(color: AppColors.textTertiary);
  static TextStyle get metric => AppTypography.metric.copyWith(color: AppColors.textPrimary);
  static TextStyle get metricSmall => AppTypography.metricSmall.copyWith(color: AppColors.textPrimary);
}

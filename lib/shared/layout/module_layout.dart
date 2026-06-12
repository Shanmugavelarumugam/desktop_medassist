import 'package:flutter/material.dart';

class ModuleLayout extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? searchActions; // Left search bar and custom inline filters
  final List<Widget>?
  primaryActions; // Right CTA buttons (e.g. "Add medicine", "Export")
  final Widget body; // Central container (e.g. Data grid, List, Charts)
  final double padding;

  const ModuleLayout({
    super.key,
    required this.title,
    this.subtitle,
    this.searchActions,
    this.primaryActions,
    required this.body,
    this.padding = 32.0,
  });

  @override
  Widget build(BuildContext context) {
    const textDark = Color(0xFF1E293B);
    const softSlate = Color(0xFF64748B);
    const borderGrey = Color(0xFFE2E8F0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. MODULE PAGE TITLE HEADER
        Padding(
          padding: EdgeInsets.fromLTRB(padding, padding, padding, 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: textDark,
                      letterSpacing: -0.5,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle!,
                      style: const TextStyle(
                        fontSize: 14,
                        color: softSlate,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ],
              ),
              if (primaryActions != null)
                Row(spacing: 12, children: primaryActions!),
            ],
          ),
        ),

        // 2. SEARCH & CONTROLS SUB-HEADER
        if (searchActions != null)
          Container(
            margin: EdgeInsets.symmetric(horizontal: padding),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderGrey),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: searchActions,
          ),

        SizedBox(height: searchActions != null ? 24 : 0),

        // 3. MAIN DYNAMIC ERP MODULE WORKSPACE
        Expanded(
          child: Padding(
            padding: EdgeInsets.fromLTRB(padding, 0, padding, padding),
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderGrey),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.015),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: body,
            ),
          ),
        ),
      ],
    );
  }
}

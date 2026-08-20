import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gestion_formations/config/theme.dart';

class ProColumn {
  final String label;
  final int flex;
  final Alignment alignment;
  final bool numeric;

  const ProColumn({
    required this.label,
    this.flex = 1,
    this.alignment = Alignment.centerLeft,
    this.numeric = false,
  });
}

class ProDataCell {
  final Widget? child;
  final String? text;
  final TextStyle? style;

  const ProDataCell({
    this.child,
    this.text,
    this.style,
  });
}

class ProDataRow {
  final List<ProDataCell> cells;
  final VoidCallback? onTap;

  const ProDataRow({
    required this.cells,
    this.onTap,
  });
}

class ProDataTable extends StatelessWidget {
  final List<ProColumn> columns;
  final List<ProDataRow> rows;
  final String? title;
  final String? subtitle;
  final Widget? headerAction;
  final String? searchQuery;
  final ValueChanged<String>? onSearchChanged;
  final bool isLoading;
  final String emptyMessage;

  const ProDataTable({
    super.key,
    required this.columns,
    required this.rows,
    this.title,
    this.subtitle,
    this.headerAction,
    this.searchQuery,
    this.onSearchChanged,
    this.isLoading = false,
    this.emptyMessage = 'Aucune donnée disponible',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Table Toolbar Header
          if (title != null || onSearchChanged != null || headerAction != null)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  if (title != null) ...[
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title!,
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          if (subtitle != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              subtitle!,
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                  if (onSearchChanged != null)
                    SizedBox(
                      width: 240,
                      height: 40,
                      child: TextField(
                        onChanged: onSearchChanged,
                        style: GoogleFonts.poppins(fontSize: 13),
                        decoration: InputDecoration(
                          hintText: 'Rechercher...',
                          hintStyle: GoogleFonts.poppins(fontSize: 12, color: AppTheme.textSecondary),
                          prefixIcon: const Icon(Icons.search_rounded, size: 18, color: AppTheme.primary),
                          contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: AppTheme.primary, width: 1.5),
                          ),
                        ),
                      ),
                    ),
                  if (headerAction != null) ...[
                    const SizedBox(width: 12),
                    headerAction!,
                  ],
                ],
              ),
            ),

          if (title != null || onSearchChanged != null || headerAction != null)
            const Divider(height: 1, thickness: 1, color: Color(0xFFE2E8F0)),

          // Table Column Headers
          Container(
            color: const Color(0xFFF8FAFC),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: columns.map((col) {
                return Expanded(
                  flex: col.flex,
                  child: Align(
                    alignment: col.alignment,
                    child: Text(
                      col.label.toUpperCase(),
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.6,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const Divider(height: 1, thickness: 1, color: Color(0xFFE2E8F0)),

          // Table Body Content
          if (isLoading)
            const Padding(
              padding: EdgeInsets.all(40.0),
              child: Center(
                child: CircularProgressIndicator(color: AppTheme.primary),
              ),
            )
          else if (rows.isEmpty)
            Padding(
              padding: const EdgeInsets.all(40.0),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.inbox_outlined, size: 48, color: Colors.grey.shade400),
                    const SizedBox(height: 12),
                    Text(
                      emptyMessage,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: AppTheme.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: rows.length,
              separatorBuilder: (context, index) => const Divider(
                height: 1,
                thickness: 1,
                color: Color(0xFFF1F5F9),
              ),
              itemBuilder: (context, rowIndex) {
                final row = rows[rowIndex];
                final isEven = rowIndex % 2 == 0;

                return InkWell(
                  onTap: row.onTap,
                  hoverColor: AppTheme.primary.withValues(alpha: 0.04),
                  child: Container(
                    color: isEven ? Colors.white : const Color(0xFFFAFAFA),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      children: List.generate(columns.length, (colIndex) {
                        final col = columns[colIndex];
                        final cell = colIndex < row.cells.length
                            ? row.cells[colIndex]
                            : const ProDataCell(text: '-');

                        return Expanded(
                          flex: col.flex,
                          child: Align(
                            alignment: col.alignment,
                            child: cell.child ??
                                Text(
                                  cell.text ?? '',
                                  style: cell.style ??
                                      GoogleFonts.poppins(
                                        fontSize: 13,
                                        color: AppTheme.textPrimary,
                                        fontWeight: FontWeight.w500,
                                      ),
                                ),
                          ),
                        );
                      }),
                    ),
                  ),
                );
              },
            ),

          // Table Footer / Item Count
          if (rows.isNotEmpty) ...[
            const Divider(height: 1, thickness: 1, color: Color(0xFFE2E8F0)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Affichage de ${rows.length} élément(s)',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

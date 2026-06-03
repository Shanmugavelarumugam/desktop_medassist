class CsvHelper {
  /// Parses standard RFC-4180 CSV text.
  /// Handles commas, carriage returns, quotes, and nested newlines within quotes.
  static List<List<String>> parse(String csvText) {
    final List<List<String>> results = [];
    List<String> currentRow = [];
    final StringBuffer currentCell = StringBuffer();
    bool inQuotes = false;
    
    int i = 0;
    while (i < csvText.length) {
      final String char = csvText[i];
      
      if (char == '"') {
        if (inQuotes && i + 1 < csvText.length && csvText[i + 1] == '"') {
          // Escaped quote: "" -> "
          currentCell.write('"');
          i++; // skip next quote character
        } else {
          // Toggle quote boundary
          inQuotes = !inQuotes;
        }
      } else if (char == ',' && !inQuotes) {
        // End of cell
        currentRow.add(currentCell.toString().trim());
        currentCell.clear();
      } else if ((char == '\n' || char == '\r') && !inQuotes) {
        // End of row
        if (char == '\r' && i + 1 < csvText.length && csvText[i + 1] == '\n') {
          i++; // skip LF after CR
        }
        currentRow.add(currentCell.toString().trim());
        currentCell.clear();
        
        if (currentRow.isNotEmpty && (currentRow.length > 1 || currentRow.first.isNotEmpty)) {
          results.add(currentRow);
        }
        currentRow = [];
      } else {
        currentCell.write(char);
      }
      i++;
    }
    
    // Add residual cell/row
    if (currentCell.isNotEmpty || currentRow.isNotEmpty) {
      currentRow.add(currentCell.toString().trim());
      results.add(currentRow);
    }
    
    return results;
  }

  /// Converts a parsed 2D CSV grid to a list of maps, mapping header name to cell value.
  static List<Map<String, String>> toMaps(List<List<String>> csvRows) {
    if (csvRows.isEmpty) return [];
    final List<String> headers = csvRows.first;
    final List<Map<String, String>> maps = [];
    
    for (int i = 1; i < csvRows.length; i++) {
      final List<String> row = csvRows[i];
      final Map<String, String> map = {};
      for (int h = 0; h < headers.length; h++) {
        final String header = headers[h];
        final String value = h < row.length ? row[h] : '';
        map[header] = value;
      }
      maps.add(map);
    }
    
    return maps;
  }
}

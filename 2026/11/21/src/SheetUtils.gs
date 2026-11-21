/**
 * Processes spreadsheet cell-edit commands.
 *
 * @param {Object} e Apps Script edit event
 */

/**
 * Add to local project's Code.gs:
 * 
 * function onEdit(e) { SheetUtils.handleEdit(e); }
 * 
 * Add SheetUtils in the Libraries section using
 * Script ID: <redacted>
 */

/**
 * Decimal year using UTC calendar-year boundaries.
 *
 * 2025.0 = 2025-01-01 00:00:00 UTC
 * 2026.0 = 2026-01-01 00:00:00 UTC
 *
 * @param {Date} at Date to convert
 * @return {number} Stardate
 */
function stardate(at = new Date()) {
  const year = at.getUTCFullYear();
  const start = Date.UTC(year, 0, 1);
  const end = Date.UTC(year + 1, 0, 1);

  return year + (at.getTime() - start) / (end - start);
}

function handleEdit(e) {
  if (!e?.range) return;

  const range = e.range;
  const values = range.getValues();
  const timezone = e.source.getSpreadsheetTimeZone()
    || Session.getScriptTimeZone()
    || "Etc/UTC";

  // All commands in this edit share one timestamp.
  const now = new Date();

  const timestamp = Utilities.formatDate(
    now, timezone, "yyyy-MM-dd HH:mm:ss z (Z)"
  );

  const today = Utilities.formatDate(
    now, timezone, "yyyy-MM-dd"
  );

  const sd = stardate(now);

  for (let r = 0; r < values.length; r++) {
    for (let c = 0; c < values[r].length; c++) {
      const value = values[r][c];

      if (typeof value !== "string") continue;

      const cell = range.getCell(r + 1, c + 1);

      switch (value.toLowerCase()) {
        case "#now":
          cell.setValue(timestamp);
          break;

        case "#today":
          cell.setValue(today);
          break;

        case "#sd":
        case "#stardate":
          cell.setValue(sd);
          cell.setNumberFormat("0.000000");
          break;
      }
    }
  }
}

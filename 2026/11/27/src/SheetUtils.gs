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
 * Script ID: 12XtFq5nzSnmzkJW8TOSVDpuzUEXOInGSWBwDJ13rO6D3Bfg8Yi8UkgGO
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
  const sheet = range.getSheet();
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

  // Queue structural changes until cell processing is complete.
  const rowInsertions = [];

  for (let r = 0; r < values.length; r++) {
    for (let c = 0; c < values[r].length; c++) {
      const value = values[r][c];

      if (typeof value !== "string") continue;

      const cell = range.getCell(r + 1, c + 1);
      const lower = value.toLowerCase();

      switch (lower) {
        case "#now":
          cell.setValue(timestamp);
          break;

        case "#sd":
        case "#stardate":
          cell.setValue(sd);
          cell.setNumberFormat("0.000000");
          break;

        case "#today":
          cell.setValue(today);
          break;

        default:
          if (lower.startsWith("#rows:")) {
            const arg = value.slice(6).trim();
            const n = Number(arg);

            if (/^\d+$/.test(arg) &&
                Number.isSafeInteger(n) && n > 0) {
              rowInsertions.push({
                row: cell.getRow(),
                count: n,
                cell: cell
              });
            }
          } else if (lower.startsWith("#unq:")) {
            const url = value.slice(5).trim();
            cell.setValue(url.split("?")[0]);
          }
          break;
      }
    }
  }

  // Clear all row-insertion commands before changing coordinates.
  for (const { cell } of rowInsertions) {
    cell.clearContent();
  }

  // Insert rows from bottom to top to preserve coordinates.
  rowInsertions.sort((a, b) => b.row - a.row);

  for (const { row, count } of rowInsertions) {
    sheet.insertRowsAfter(row, count);
  }
}

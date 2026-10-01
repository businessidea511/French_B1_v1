// POST /api/content  — admin-only writes to Supabase with the service role key.
// Requires "Authorization: Bearer <token from /api/admin>".
//
// Actions:
//   { action: 'upsert',   table: 'lessons'|'grammar', rows: [ {id, title, subtitle, icon, description, content} ] }
//   { action: 'delete',   table: 'lessons'|'grammar'|'admin_ai_saved_qas', id }
//   { action: 'list_qas' }
//   { action: 'insert_qa', question, answer, language }
const { handleCors, isAdmin, supabaseRest } = require('./_lib');

const CONTENT_TABLES = ['lessons', 'grammar'];
const CONTENT_COLUMNS = ['id', 'title', 'subtitle', 'icon', 'description', 'content'];

function pick(row, columns) {
  const out = {};
  for (const c of columns) if (row[c] !== undefined) out[c] = row[c];
  return out;
}

module.exports = async (req, res) => {
  if (handleCors(req, res)) return;
  if (!isAdmin(req)) return res.status(401).json({ error: 'Admin login required' });

  const body = req.body || {};
  try {
    switch (body.action) {
      case 'upsert': {
        if (!CONTENT_TABLES.includes(body.table)) return res.status(400).json({ error: 'invalid table' });
        const rows = Array.isArray(body.rows) ? body.rows : [];
        if (rows.length === 0 || rows.length > 100 || rows.some((r) => !r || typeof r.id !== 'string' || !r.id)) {
          return res.status(400).json({ error: 'rows must be 1-100 objects with a string id' });
        }
        const saved = await supabaseRest(`${body.table}?on_conflict=id`, {
          method: 'POST',
          body: rows.map((r) => pick(r, CONTENT_COLUMNS)),
          prefer: 'resolution=merge-duplicates,return=representation',
        });
        return res.status(200).json({ rows: saved });
      }

      case 'delete': {
        const tables = [...CONTENT_TABLES, 'admin_ai_saved_qas'];
        if (!tables.includes(body.table)) return res.status(400).json({ error: 'invalid table' });
        if (typeof body.id !== 'string' || !body.id) return res.status(400).json({ error: 'id is required' });
        await supabaseRest(`${body.table}?id=eq.${encodeURIComponent(body.id)}`, { method: 'DELETE' });
        return res.status(200).json({ ok: true });
      }

      case 'list_qas': {
        const rows = await supabaseRest('admin_ai_saved_qas?select=*&order=created_at.desc');
        return res.status(200).json({ rows });
      }

      case 'insert_qa': {
        const { question, answer, language } = body;
        if (typeof question !== 'string' || typeof answer !== 'string') {
          return res.status(400).json({ error: 'question and answer are required' });
        }
        const rows = await supabaseRest('admin_ai_saved_qas', {
          method: 'POST',
          body: { question, answer, language: typeof language === 'string' ? language : 'English' },
          prefer: 'return=representation',
        });
        return res.status(200).json({ row: rows[0] });
      }

      default:
        return res.status(400).json({ error: 'unknown action' });
    }
  } catch (e) {
    return res.status(500).json({ error: e.message });
  }
};

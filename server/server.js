const express = require('express');
const fs = require('fs');
const path = require('path');

const app = express();
app.use(express.json());

const DATA_DIR = '/data';
const DATA_FILE = path.join(DATA_DIR, 'inscriptions.json');
const FORMATIONS_FILE = path.join(DATA_DIR, 'formations.json');

function ensureDataFile() {
  const bundled = path.join(__dirname, 'data', 'formations.json');

  function seedFormations() {
    if (fs.existsSync(bundled)) {
      const payload = fs.readFileSync(bundled, 'utf8');
      fs.writeFileSync(FORMATIONS_FILE, payload);
      console.log('Seeded formations.json from bundled data');
    } else {
      fs.writeFileSync(FORMATIONS_FILE, '[]');
      console.log('Created empty formations.json because bundled seed file is missing');
    }
  }

  try {
    if (!fs.existsSync(DATA_DIR)) fs.mkdirSync(DATA_DIR, { recursive: true });
    if (!fs.existsSync(DATA_FILE)) fs.writeFileSync(DATA_FILE, '[]');

    if (!fs.existsSync(FORMATIONS_FILE)) {
      seedFormations();
    } else {
      try {
        const raw = fs.readFileSync(FORMATIONS_FILE, 'utf8').trim();
        if (!raw) {
          seedFormations();
        } else {
          const parsed = JSON.parse(raw);
          if (!Array.isArray(parsed) || parsed.length === 0) {
            seedFormations();
          }
        }
      } catch (e) {
        console.warn('Could not parse formations.json, reseeding from bundled data', e);
        seedFormations();
      }
    }
  } catch (e) {
    console.error('Could not create data file', e);
  }
}

app.get('/api/health', (req, res) => {
  res.json({ status: 'ok' });
});

app.get('/api/inscriptions', (req, res) => {
  ensureDataFile();
  try {
    const raw = fs.readFileSync(DATA_FILE, 'utf8');
    const list = JSON.parse(raw || '[]');
    res.json(list);
  } catch (e) {
    console.error(e);
    res.status(500).json({ error: 'failed to read data' });
  }
});

app.get('/api/formations', (req, res) => {
  ensureDataFile();
  try {
    const raw = fs.readFileSync(FORMATIONS_FILE, 'utf8');
    const list = JSON.parse(raw || '[]');
    res.json(list);
  } catch (e) {
    console.error(e);
    res.status(500).json({ error: 'failed to read formations' });
  }
});

app.post('/api/inscriptions', (req, res) => {
  ensureDataFile();
  try {
    const payload = req.body || {};
    const insc = Object.assign({}, payload);
    insc._id = `insc_${Date.now()}`;
    insc._receivedAt = new Date().toISOString();

    const raw = fs.readFileSync(DATA_FILE, 'utf8');
    const list = JSON.parse(raw || '[]');
    list.push(insc);
    fs.writeFileSync(DATA_FILE, JSON.stringify(list, null, 2));

    res.json({ success: true, id: insc._id });
  } catch (e) {
    console.error(e);
    res.status(500).json({ error: 'failed to save' });
  }
});

const PORT = 5001;
app.listen(PORT, () => console.log(`API server listening on ${PORT}`));

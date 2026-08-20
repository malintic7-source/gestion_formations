const express = require('express');
const fs = require('fs');
const path = require('path');
const crypto = require('crypto');

const app = express();
app.use(express.json({ limit: '15mb' }));

const dataDir = process.env.DATA_DIR || '/data';
const dataFile = path.join(dataDir, 'database.json');
const collections = ['users', 'formations', 'inscriptions', 'payments', 'notifications', 'audit_logs', 'seances'];
const sessions = new Map();

function sessionFromRequest(req) {
  const cookies = Object.fromEntries((req.headers.cookie || '').split(';').map((value) => {
    const [key, ...rest] = value.trim().split('=');
    return [key, decodeURIComponent(rest.join('='))];
  }).filter(([key]) => key));
  return sessions.get(cookies.malintic_session);
}

function requireSession(req, res, next) {
  const session = sessionFromRequest(req);
  if (!session) return res.status(401).json({ error: 'Authentification requise' });
  req.session = session;
  next();
}

function isEmployee(session) {
  const role = String(session?.role || '').toLowerCase();
  return session && role !== 'userrole.etudiant' && role !== 'userrole.apprenant';
}

function requireEmployee(req, res, next) {
  const session = sessionFromRequest(req);
  if (!isEmployee(session)) return res.status(403).json({ error: 'Accès réservé au personnel' });
  req.session = session;
  next();
}

function initialState() {
  const state = Object.fromEntries(collections.map((name) => [name, []]));
  const email = String(process.env.BOOTSTRAP_ADMIN_EMAIL || '').trim().toLowerCase();
  const password = String(process.env.BOOTSTRAP_ADMIN_PASSWORD || '');
  if (email && password) {
    state.users.push({
      id: 'admin_local_initial',
      email,
      nom: 'Administrateur',
      prenom: 'Mamadou',
      phone: '',
      role: 'UserRole.admin',
      password,
      estActif: true,
      dateCreation: new Date().toISOString(),
    });
  }
  return state;
}

function readState() {
  fs.mkdirSync(dataDir, { recursive: true });
  if (!fs.existsSync(dataFile)) {
    const bundledSeed = path.join(__dirname, 'initial_database.json');
    if (fs.existsSync(bundledSeed)) {
      try {
        const seedData = JSON.parse(fs.readFileSync(bundledSeed, 'utf8'));
        for (const name of collections) if (!Array.isArray(seedData[name])) seedData[name] = [];
        fs.writeFileSync(dataFile, JSON.stringify(seedData, null, 2));
        return seedData;
      } catch (_) {}
    }
    const state = initialState();
    fs.writeFileSync(dataFile, JSON.stringify(state, null, 2));
    return state;
  }
  try {
    const parsed = JSON.parse(fs.readFileSync(dataFile, 'utf8'));
    for (const name of collections) if (!Array.isArray(parsed[name])) parsed[name] = [];
    return parsed;
  } catch (error) {
    throw new Error(`Base locale illisible : ${error.message}`);
  }
}

function writeState(state) {
  const temporary = `${dataFile}.tmp`;
  fs.writeFileSync(temporary, JSON.stringify(state, null, 2));
  fs.renameSync(temporary, dataFile);
}

function isCollection(name) { return collections.includes(name); }

function validateFormationAssignments(data, users) {
  const modules = Array.isArray(data.modules) ? data.modules.map(String) : [];
  const assignments = data.moduleFormateurIds;
  if (assignments == null) return null;
  if (typeof assignments !== 'object' || Array.isArray(assignments)) {
    return 'moduleFormateurIds doit être un objet {module: idFormateur}.';
  }
  for (const [module, formateurId] of Object.entries(assignments)) {
    if (!formateurId) continue;
    if (!modules.includes(module)) continue;
    const formateur = users.find((user) => String(user.id) === String(formateurId));
    if (formateur) {
      const role = String(formateur.role || '').toLowerCase();
      if (!role.includes('formateur') && !role.includes('admin')) {
        return `Le responsable du module « ${module} » doit être un formateur ou administrateur.`;
      }
    }
  }
  return null;
}

app.get('/api/health', (_, res) => res.json({ status: 'ok' }));
app.post('/api/auth/login', (req, res) => {
  const email = String(req.body?.email || '').trim().toLowerCase();
  const password = String(req.body?.password || '');
  const user = readState().users.find((item) => String(item.email || '').trim().toLowerCase() === email);
  if (!user || (user.password && user.password !== password) || user.estActif === false) {
    return res.status(401).json({ error: 'Identifiants incorrects' });
  }
  const token = crypto.randomBytes(32).toString('hex');
  sessions.set(token, { userId: user.id, role: user.role, createdAt: Date.now() });
  // Session cookie: it is discarded when the browser process closes. A tab
  // close is additionally handled by the authenticated tab's pagehide beacon.
  res.setHeader('Set-Cookie', `malintic_session=${token}; Path=/; HttpOnly; SameSite=Lax`);
  res.json(user);
});
app.post('/api/auth/logout', requireSession, (req, res) => {
  const token = (req.headers.cookie || '').match(/malintic_session=([^;]+)/)?.[1];
  if (token) sessions.delete(token);
  res.setHeader('Set-Cookie', 'malintic_session=; Path=/; HttpOnly; SameSite=Lax; Max-Age=0');
  res.status(204).end();
});
app.get('/api/auth/session', requireSession, (req, res) => {
  const user = readState().users.find((item) => item.id === req.session.userId);
  if (!user || user.estActif === false) return res.status(401).json({ error: 'Session invalide' });
  res.json(user);
});

app.get('/api/state', (req, res) => {
  res.setHeader('Cache-Control', 'no-store');
  const state = readState();
  const session = sessionFromRequest(req);
  if (isEmployee(session)) {
    return res.json(state);
  }
  // Public access (catalog of formations for visitors, students and login screen)
  return res.json({
    users: [],
    formations: state.formations || [],
    inscriptions: [],
    payments: [],
    notifications: [],
    audit_logs: [],
    seances: state.seances || [],
  });
});

// Migration contrôlée : le premier navigateur qui possède encore les données
// locales peut initialiser un volume Docker neuf. Une base déjà remplie n'est
// jamais écrasée par cette route.
app.put('/api/state', requireEmployee, (req, res) => {
  const current = readState();
  const isEmpty = collections.every((name) => current[name].length === 0);
  if (!isEmpty) return res.status(409).json({ error: 'Base déjà initialisée' });
  const candidate = initialState();
  for (const name of collections) {
    if (Array.isArray(req.body?.[name])) candidate[name] = req.body[name];
  }
  writeState(candidate);
  res.json(candidate);
});

// Fusion de migration : ajoute uniquement les documents absents du volume
// Docker. Les données déjà reçues par le serveur ne sont jamais écrasées.
app.post('/api/state/merge', requireEmployee, (req, res) => {
  const state = readState();
  let added = 0;
  for (const name of collections) {
    const incoming = Array.isArray(req.body?.[name]) ? req.body[name] : [];
    const knownIds = new Set(state[name].map((item) => String(item.id)));
    for (const item of incoming) {
      if (!item?.id || knownIds.has(String(item.id))) continue;
      state[name].push(item);
      knownIds.add(String(item.id));
      added += 1;
    }
  }
  if (added > 0) writeState(state);
  res.json({ added });
});

app.get('/api/:collection', (req, res) => {
  if (!isCollection(req.params.collection)) return res.status(404).json({ error: 'Collection inconnue' });
  if (req.params.collection !== 'formations' && !sessionFromRequest(req)) {
    return res.status(401).json({ error: 'Authentification requise' });
  }
  if (req.params.collection !== 'formations' && !isEmployee(sessionFromRequest(req))) {
    return res.status(403).json({ error: 'Accès réservé au personnel' });
  }
  res.json(readState()[req.params.collection]);
});

app.get('/api/:collection/:id', (req, res) => {
  const { collection, id } = req.params;
  if (!isCollection(collection)) return res.status(404).json({ error: 'Collection inconnue' });
  if (collection !== 'formations') {
    if (!sessionFromRequest(req)) return res.status(401).json({ error: 'Authentification requise' });
    if (!isEmployee(sessionFromRequest(req))) return res.status(403).json({ error: 'Accès réservé au personnel' });
  }
  const item = readState()[collection].find((entry) => String(entry.id) === id);
  if (!item) return res.status(404).json({ error: 'Document introuvable' });
  res.setHeader('Cache-Control', 'no-store');
  res.json(item);
});

app.put('/api/:collection/:id', (req, res) => {
  const { collection, id } = req.params;
  if (!isCollection(collection)) return res.status(404).json({ error: 'Collection inconnue' });
  const isPublicRegistration = collection === 'inscriptions' && req.body?.source === 'web';
  if (!isPublicRegistration && !isEmployee(sessionFromRequest(req))) {
    return res.status(403).json({ error: 'Accès réservé au personnel' });
  }
  const state = readState();
  const list = state[collection];
  const data = { ...(req.body || {}), id };
  if (collection === 'formations') {
    const assignmentError = validateFormationAssignments(data, state.users);
    if (assignmentError) return res.status(400).json({ error: assignmentError });
  }
  const index = list.findIndex((item) => String(item.id) === id);
  if (index >= 0) list[index] = { ...list[index], ...data };
  else list.push(data);
  writeState(state);
  res.json(data);
});

app.delete('/api/:collection/:id', (req, res) => {
  const { collection, id } = req.params;
  if (!isCollection(collection)) return res.status(404).json({ error: 'Collection inconnue' });
  if (!isEmployee(sessionFromRequest(req))) return res.status(403).json({ error: 'Accès réservé au personnel' });
  const state = readState();
  state[collection] = state[collection].filter((item) => String(item.id) !== id);
  writeState(state);
  res.status(204).end();
});

app.listen(5001, () => console.log('API locale disponible sur le port 5001'));



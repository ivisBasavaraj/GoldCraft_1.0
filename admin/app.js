// ── Helpers ──────────────────────────────────────────────────────────────────
function fmt(n, dec = 0) { return Number(n || 0).toFixed(dec); }
function fmtRs(n) {
  n = Number(n || 0);
  if (n >= 100000) return '₹' + (n / 100000).toFixed(1) + 'L';
  if (n >= 1000) return '₹' + (n / 1000).toFixed(1) + 'K';
  return '₹' + n.toFixed(0);
}
function fmtDate(d) {
  if (!d) return '—';
  return new Date(d).toLocaleDateString('en-IN', { day: 'numeric', month: 'short', year: 'numeric' });
}
function badge(label, type) {
  return `<span class="badge badge-${type}">${label}</span>`;
}
function statusBadge(status) {
  const map = {
    assigned: ['info', 'Assigned'],
    inProgress: ['warning', 'In Progress'],
    qualityCheck: ['warning', 'QC'],
    completed: ['success', 'Completed'],
    cancelled: ['error', 'Cancelled'],
    draft: ['neutral', 'Draft'],
    underReview: ['info', 'Under Review'],
    approved: ['warning', 'Approved'],
    partiallyPaid: ['warning', 'Partial'],
    paid: ['success', 'Paid'],
    active: ['success', 'Active'],
    inactive: ['neutral', 'Inactive'],
  };
  const [type, lbl] = map[status] || ['neutral', status];
  return badge(lbl, type);
}
function loading(id) {
  document.getElementById(id).innerHTML = `<div class="loading"><div class="spinner"></div><div>Loading...</div></div>`;
}
function empty(id, icon, msg) {
  document.getElementById(id).innerHTML = `<div class="empty"><div class="empty-icon">${icon}</div><h3>${msg}</h3></div>`;
}
function openModal(title, html) {
  document.getElementById('modalTitle').textContent = title;
  document.getElementById('modalBody').innerHTML = html;
  document.getElementById('modal').classList.remove('hidden');
}
function closeModal() {
  document.getElementById('modal').classList.add('hidden');
}
document.getElementById('modal').addEventListener('click', function(e) {
  if (e.target === this) closeModal();
});

// ── Auth ──────────────────────────────────────────────────────────────────────
async function doLogin() {
  const user = document.getElementById('loginUser').value.trim();
  const pass = document.getElementById('loginPass').value.trim();
  const err = document.getElementById('loginError');
  err.classList.add('hidden');
  try {
    const data = await api.post('/auth/login', { username: user, password: pass });
    api.token = data.accessToken;
    localStorage.setItem('gc_token', data.accessToken);
    localStorage.setItem('gc_user', JSON.stringify(data.user));
    document.getElementById('sidebarUser').textContent = data.user.name;
    document.getElementById('loginPage').classList.add('hidden');
    document.getElementById('appShell').classList.remove('hidden');
    showPage('dashboard', document.querySelector('.nav-item'));
  } catch (e) {
    err.textContent = e.message;
    err.classList.remove('hidden');
  }
}

function doLogout() {
  api.token = null;
  localStorage.removeItem('gc_token');
  localStorage.removeItem('gc_user');
  document.getElementById('appShell').classList.add('hidden');
  document.getElementById('loginPage').classList.remove('hidden');
}

// ── Routing ───────────────────────────────────────────────────────────────────
const pageLoaders = {
  dashboard: loadDashboard,
  karagars: loadKaragars,
  jobs: loadJobs,
  treasury: loadTreasury,
  advances: loadAdvances,
  payroll: loadPayroll,
  reports: loadReports,
  users: loadUsers,
};

function showPage(name, el) {
  document.querySelectorAll('.page').forEach(p => p.classList.remove('active'));
  document.querySelectorAll('.nav-item').forEach(n => n.classList.remove('active'));
  document.getElementById('page-' + name).classList.add('active');
  if (el) el.classList.add('active');
  if (pageLoaders[name]) pageLoaders[name]();
  return false;
}

// ── Init ──────────────────────────────────────────────────────────────────────
(function init() {
  const token = localStorage.getItem('gc_token');
  const user = JSON.parse(localStorage.getItem('gc_user') || 'null');
  if (token && user) {
    api.token = token;
    document.getElementById('sidebarUser').textContent = user.name;
    document.getElementById('loginPage').classList.add('hidden');
    document.getElementById('appShell').classList.remove('hidden');
    showPage('dashboard', document.querySelector('.nav-item'));
  }
  document.getElementById('loginPass').addEventListener('keydown', e => {
    if (e.key === 'Enter') doLogin();
  });
})();

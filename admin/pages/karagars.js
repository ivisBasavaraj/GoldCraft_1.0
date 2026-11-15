let _karagars = [];

async function loadKaragars() {
  const el = document.getElementById('page-karagars');
  el.innerHTML = `
    <div class="page-header">
      <div><h2>Karagars</h2><p>Manage artisans</p></div>
      <button class="btn btn-primary" onclick="openAddKaragar()">+ Add Karagar</button>
    </div>
    <div class="table-wrap">
      <div class="table-toolbar">
        <input id="k-search" placeholder="Search name or code…" oninput="filterKaragars()"/>
      </div>
      <div id="k-table"></div>
    </div>`;
  try {
    const data = await api.get('/karagars');
    _karagars = data.items || [];
    renderKaragars(_karagars);
  } catch (e) {
    document.getElementById('k-table').innerHTML = `<div class="alert alert-error">${e.message}</div>`;
  }
}

function renderKaragars(list) {
  if (!list.length) { empty('k-table', '&#128100;', 'No karagars found'); return; }
  document.getElementById('k-table').innerHTML = `
    <table><thead><tr><th>Code</th><th>Name</th><th>Group</th><th>Specialization</th><th>Phone</th><th>Jobs</th><th>Status</th><th></th></tr></thead>
    <tbody>${list.map(k => `
      <tr>
        <td><code>${k.employeeCode}</code></td>
        <td><strong>${k.name}</strong></td>
        <td>${k.meltingGroup}</td>
        <td>${k.specialization}</td>
        <td>${k.phone || '—'}</td>
        <td>${k.activeJobCount || 0}</td>
        <td>${statusBadge(k.isActive ? 'active' : 'inactive')}</td>
        <td><button class="btn btn-sm btn-outline" onclick="openEditKaragar('${k._id}')">Edit</button></td>
      </tr>`).join('')}
    </tbody></table>`;
}

function filterKaragars() {
  const q = document.getElementById('k-search').value.toLowerCase();
  renderKaragars(_karagars.filter(k => k.name.toLowerCase().includes(q) || k.employeeCode.toLowerCase().includes(q)));
}

function openAddKaragar() {
  openModal('Add Karagar', karagarForm());
}

function openEditKaragar(id) {
  const k = _karagars.find(x => x._id === id);
  if (!k) return;
  openModal('Edit Karagar', karagarForm(k));
}

function karagarForm(k = {}) {
  return `
    <div class="form-row">
      <div class="form-group"><label>Name *</label><input id="kf-name" value="${k.name||''}"/></div>
      <div class="form-group"><label>Employee Code *</label><input id="kf-code" value="${k.employeeCode||''}"/></div>
    </div>
    <div class="form-row">
      <div class="form-group"><label>Melting Group *</label>
        <select id="kf-group">
          ${['A','B','C','D'].map(g=>`<option ${k.meltingGroup===g?'selected':''}>${g}</option>`).join('')}
        </select>
      </div>
      <div class="form-group"><label>Specialization *</label><input id="kf-spec" value="${k.specialization||''}"/></div>
    </div>
    <div class="form-group"><label>Phone</label><input id="kf-phone" value="${k.phone||''}"/></div>
    ${k._id ? `<div class="form-group"><label>Status</label>
      <select id="kf-active"><option value="true" ${k.isActive?'selected':''}>Active</option><option value="false" ${!k.isActive?'selected':''}>Inactive</option></select>
    </div>` : ''}
    <div class="modal-footer">
      <button class="btn btn-outline" onclick="closeModal()">Cancel</button>
      <button class="btn btn-primary" onclick="saveKaragar('${k._id||''}')">Save</button>
    </div>`;
}

async function saveKaragar(id) {
  const body = {
    name: document.getElementById('kf-name').value.trim(),
    employeeCode: document.getElementById('kf-code').value.trim(),
    meltingGroup: document.getElementById('kf-group').value,
    specialization: document.getElementById('kf-spec').value.trim(),
    phone: document.getElementById('kf-phone').value.trim(),
  };
  if (id) body.isActive = document.getElementById('kf-active').value === 'true';
  if (!body.name || !body.employeeCode || !body.specialization) return alert('Fill required fields');
  try {
    if (id) await api.patch('/karagars/' + id, body);
    else await api.post('/karagars', body);
    closeModal();
    loadKaragars();
  } catch (e) { alert(e.message); }
}

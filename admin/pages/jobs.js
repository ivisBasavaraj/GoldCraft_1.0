let _jobs = [], _jobKaragars = [];

async function loadJobs() {
  const el = document.getElementById('page-jobs');
  el.innerHTML = `
    <div class="page-header">
      <div><h2>Jobs</h2><p>Track all work orders</p></div>
      <button class="btn btn-primary" onclick="openAddJob()">+ New Job</button>
    </div>
    <div class="table-wrap">
      <div class="table-toolbar">
        <input id="j-search" placeholder="Search job# or title…" oninput="filterJobs()"/>
        <select id="j-status" onchange="filterJobs()" style="padding:8px 12px;border:1px solid #e0dbd5;border-radius:8px;font-size:13px">
          <option value="">All Status</option>
          <option>assigned</option><option>inProgress</option><option>qualityCheck</option>
          <option>completed</option><option>cancelled</option>
        </select>
      </div>
      <div id="j-table"></div>
    </div>`;
  try {
    const [jData, kData] = await Promise.all([api.get('/jobs'), api.get('/karagars')]);
    _jobs = jData.items || [];
    _jobKaragars = kData.items || [];
    renderJobs(_jobs);
  } catch (e) {
    document.getElementById('j-table').innerHTML = `<div class="alert alert-error">${e.message}</div>`;
  }
}

function renderJobs(list) {
  if (!list.length) { empty('j-table', '&#128295;', 'No jobs found'); return; }
  document.getElementById('j-table').innerHTML = `
    <table><thead><tr><th>Job#</th><th>Title</th><th>Karagar</th><th>Weight</th><th>Due</th><th>Status</th><th></th></tr></thead>
    <tbody>${list.map(j => `
      <tr>
        <td><strong>${j.jobNumber}</strong></td>
        <td>${j.title}</td>
        <td>${j.karagarName}</td>
        <td>${fmt(j.requiredWeightGrams,2)}g</td>
        <td>${fmtDate(j.dueDate)}</td>
        <td>${statusBadge(j.status)}</td>
        <td><button class="btn btn-sm btn-outline" onclick="openJobDetail('${j._id}')">View</button></td>
      </tr>`).join('')}
    </tbody></table>`;
}

function filterJobs() {
  const q = document.getElementById('j-search').value.toLowerCase();
  const s = document.getElementById('j-status').value;
  renderJobs(_jobs.filter(j =>
    (!q || j.jobNumber.toLowerCase().includes(q) || j.title.toLowerCase().includes(q)) &&
    (!s || j.status === s)
  ));
}

function openAddJob() {
  const opts = _jobKaragars.filter(k => k.isActive).map(k =>
    `<option value="${k._id}">${k.name} (${k.employeeCode})</option>`).join('');
  openModal('New Job', `
    <div class="form-row">
      <div class="form-group"><label>Title *</label><input id="jf-title"/></div>
      <div class="form-group"><label>Karagar *</label><select id="jf-karagar"><option value="">Select…</option>${opts}</select></div>
    </div>
    <div class="form-row">
      <div class="form-group"><label>Required Weight (g) *</label><input id="jf-weight" type="number" step="0.01"/></div>
      <div class="form-group"><label>Due Date *</label><input id="jf-due" type="date"/></div>
    </div>
    <div class="form-group"><label>Notes</label><textarea id="jf-notes" rows="2"></textarea></div>
    <div class="modal-footer">
      <button class="btn btn-outline" onclick="closeModal()">Cancel</button>
      <button class="btn btn-primary" onclick="saveJob()">Create Job</button>
    </div>`);
}

async function saveJob() {
  const body = {
    title: document.getElementById('jf-title').value.trim(),
    karagarId: document.getElementById('jf-karagar').value,
    requiredWeightMg: Math.round(Number(document.getElementById('jf-weight').value) * 1000),
    dueDate: document.getElementById('jf-due').value,
    notes: document.getElementById('jf-notes').value.trim(),
  };
  if (!body.title || !body.karagarId || !body.requiredWeightMg || !body.dueDate) return alert('Fill required fields');
  try {
    await api.post('/jobs', body);
    closeModal();
    loadJobs();
  } catch (e) { alert(e.message); }
}

function openJobDetail(id) {
  const j = _jobs.find(x => x._id === id);
  if (!j) return;
  const statuses = ['assigned','inProgress','qualityCheck','completed','cancelled'];
  openModal(`Job ${j.jobNumber}`, `
    <div class="form-row">
      <div><div class="stat-label">Title</div><strong>${j.title}</strong></div>
      <div><div class="stat-label">Karagar</div>${j.karagarName}</div>
    </div>
    <div class="form-row" style="margin-top:12px">
      <div><div class="stat-label">Required Weight</div>${fmt(j.requiredWeightGrams,2)}g</div>
    <div class="form-row" style="margin-top:12px">
      <div><div class="stat-label">Issued</div>${fmt(j.issuedWeightGrams,2)}g</div>
      <div><div class="stat-label">Returned</div>${fmt(j.returnedWeightGrams,2)}g</div>
    </div>
    <div class="form-group" style="margin-top:16px"><label>Update Status</label>
      <select id="jd-status">${statuses.map(s=>`<option ${j.status===s?'selected':''}>${s}</option>`).join('')}</select>
    </div>
    <div class="form-row">
      <div class="form-group"><label>Issued Weight (g)</label><input id="jd-issued" type="number" step="0.001" value="${j.issuedWeightGrams}"/></div>
      <div class="form-group"><label>Returned Weight (g)</label><input id="jd-returned" type="number" step="0.001" value="${j.returnedWeightGrams}"/></div>
    </div>
    <div class="modal-footer">
      <button class="btn btn-outline" onclick="closeModal()">Close</button>
      <button class="btn btn-primary" onclick="updateJob('${j._id}')">Update</button>
    </div>`);
}

async function updateJob(id) {
  try {
    await api.patch('/jobs/' + id, {
      status: document.getElementById('jd-status').value,
      issuedWeightGrams: Number(document.getElementById('jd-issued').value),
      returnedWeightGrams: Number(document.getElementById('jd-returned').value),
    });
    closeModal();
    loadJobs();
  } catch (e) { alert(e.message); }
}

let _payrolls = [], _payKaragars = [];

async function loadPayroll() {
  const el = document.getElementById('page-payroll');
  el.innerHTML = `
    <div class="page-header">
      <div><h2>Payroll</h2><p>Salary history</p></div>
      <button class="btn btn-primary" onclick="openAddPayroll()">+ Add Payment</button>
    </div>
    <div class="table-wrap">
      <div class="table-toolbar">
        <input id="pr-search" placeholder="Search karagar…" oninput="filterPayroll()"/>
      </div>
      <div id="pr-table"></div>
    </div>`;
  try {
    const [pData, kData] = await Promise.all([api.get('/payroll'), api.get('/karagars')]);
    _payrolls = pData.items || [];
    _payKaragars = kData.items || [];
    renderPayroll(_payrolls);
  } catch (e) {
    document.getElementById('pr-table').innerHTML = `<div class="alert alert-error">${e.message}</div>`;
  }
}

function renderPayroll(list) {
  if (!list.length) { empty('pr-table', '&#128203;', 'No payroll records'); return; }
  document.getElementById('pr-table').innerHTML = `
    <table><thead><tr><th>Karagar</th><th>Period</th><th>Paid</th><th></th></tr></thead>
    <tbody>${list.map(p => `
      <tr>
        <td><strong>${p.karagarName}</strong></td>
        <td>${fmtDate(p.periodStart)} – ${fmtDate(p.periodEnd)}</td>
        <td>${fmtRs(p.paidRupees)}</td>
        <td>
          <button class="btn btn-sm btn-outline" onclick="openEditPayroll('${p._id}')">Edit</button>
          <button class="btn btn-sm btn-danger" onclick="deletePayroll('${p._id}')">Delete</button>
        </td>
      </tr>`).join('')}
    </tbody></table>`;
}

function filterPayroll() {
  const q = document.getElementById('pr-search').value.toLowerCase();
  renderPayroll(_payrolls.filter(p => !q || p.karagarName.toLowerCase().includes(q)));
}

function openAddPayroll() {
  const opts = _payKaragars.filter(k => k.isActive).map(k =>
    `<option value="${k._id}">${k.name} (${k.employeeCode})</option>`).join('');
  const today = new Date().toISOString().slice(0,10);
  const monthStart = today.slice(0,8) + '01';
  openModal('Add Payment', `
    <div class="form-group"><label>Karagar *</label><select id="pf-karagar"><option value="">Select…</option>${opts}</select></div>
    <div class="form-row">
      <div class="form-group"><label>Period Start *</label><input id="pf-start" type="date" value="${monthStart}"/></div>
      <div class="form-group"><label>Period End *</label><input id="pf-end" type="date" value="${today}"/></div>
    </div>
    <div class="form-group"><label>Paid Amount (₹) *</label><input id="pf-paid" type="number" step="0.01" min="0"/></div>
    <div class="form-group"><label>Notes</label><textarea id="pf-notes" rows="2"></textarea></div>
    <div class="modal-footer">
      <button class="btn btn-outline" onclick="closeModal()">Cancel</button>
      <button class="btn btn-primary" onclick="savePayroll()">Save</button>
    </div>`);
}

async function savePayroll() {
  const body = {
    karagarId: document.getElementById('pf-karagar').value,
    periodStart: document.getElementById('pf-start').value,
    periodEnd: document.getElementById('pf-end').value,
    paidRupees: Number(document.getElementById('pf-paid').value),
    notes: document.getElementById('pf-notes').value.trim(),
  };
  if (!body.karagarId || !body.periodStart || !body.periodEnd) return alert('Fill required fields');
  try {
    await api.post('/payroll', body);
    closeModal();
    loadPayroll();
  } catch (e) { alert(e.message); }
}

function openEditPayroll(id) {
  const p = _payrolls.find(x => x._id === id);
  if (!p) return;
  openModal('Edit Payment', `
    <div class="form-group"><label>Paid Amount (₹) *</label><input id="pe-paid" type="number" step="0.01" value="${p.paidRupees}"/></div>
    <div class="form-group"><label>Notes</label><textarea id="pe-notes" rows="2">${p.notes || ''}</textarea></div>
    <div class="modal-footer">
      <button class="btn btn-outline" onclick="closeModal()">Cancel</button>
      <button class="btn btn-primary" onclick="updatePayroll('${id}')">Update</button>
    </div>`);
}

async function updatePayroll(id) {
  try {
    await api.patch('/payroll/' + id, {
      paidRupees: Number(document.getElementById('pe-paid').value),
      notes: document.getElementById('pe-notes').value.trim(),
    });
    closeModal();
    loadPayroll();
  } catch (e) { alert(e.message); }
}

async function deletePayroll(id) {
  if (!confirm('Delete this payment record?')) return;
  try {
    await api.delete('/payroll/' + id);
    loadPayroll();
  } catch (e) { alert(e.message); }
}

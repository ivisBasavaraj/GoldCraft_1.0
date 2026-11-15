let _advances = [], _advKaragars = [];

async function loadAdvances() {
  const el = document.getElementById('page-advances');
  el.innerHTML = `
    <div class="page-header">
      <div><h2>Advances</h2><p>Salary advances & repayments</p></div>
      <button class="btn btn-primary" onclick="openAddAdvance()">+ New Advance</button>
    </div>
    <div class="table-wrap">
      <div class="table-toolbar">
        <input id="adv-search" placeholder="Search karagar…" oninput="filterAdvances()"/>
        <select id="adv-filter" onchange="filterAdvances()" style="padding:8px 12px;border:1px solid #e0dbd5;border-radius:8px;font-size:13px">
          <option value="">All</option><option value="pending">Pending</option><option value="repaid">Fully Repaid</option>
        </select>
      </div>
      <div id="adv-table"></div>
    </div>`;
  try {
    const [aData, kData] = await Promise.all([api.get('/advances'), api.get('/karagars')]);
    _advances = aData.items || [];
    _advKaragars = kData.items || [];
    renderAdvances(_advances);
  } catch (e) {
    document.getElementById('adv-table').innerHTML = `<div class="alert alert-error">${e.message}</div>`;
  }
}

function renderAdvances(list) {
  if (!list.length) { empty('adv-table', '&#128176;', 'No advances found'); return; }
  document.getElementById('adv-table').innerHTML = `
    <table><thead><tr><th>ID</th><th>Karagar</th><th>Amount</th><th>Repaid</th><th>Outstanding</th><th>Mode</th><th>Date</th><th>Status</th><th></th></tr></thead>
    <tbody>${list.map(a => {
      const outstanding = a.amountRupees - a.repaidRupees;
      return `<tr>
        <td><code>${a.transactionId}</code></td>
        <td>${a.karagarName}</td>
        <td>${fmtRs(a.amountRupees)}</td>
        <td>${fmtRs(a.repaidRupees)}</td>
        <td>${fmtRs(outstanding)}</td>
        <td>${a.paymentMode}</td>
        <td>${fmtDate(a.createdAt)}</td>
        <td>${statusBadge(a.fullyRepaid ? 'paid' : 'approved')}</td>
        <td>${!a.fullyRepaid ? `<button class="btn btn-sm btn-success" onclick="openRepay('${a._id}','${a.karagarName}',${outstanding})">Repay</button>` : ''}</td>
      </tr>`;
    }).join('')}
    </tbody></table>`;
}

function filterAdvances() {
  const q = document.getElementById('adv-search').value.toLowerCase();
  const f = document.getElementById('adv-filter').value;
  renderAdvances(_advances.filter(a =>
    (!q || a.karagarName.toLowerCase().includes(q)) &&
    (!f || (f === 'repaid' ? a.fullyRepaid : !a.fullyRepaid))
  ));
}

function openAddAdvance() {
  const opts = _advKaragars.filter(k => k.isActive).map(k =>
    `<option value="${k._id}">${k.name} (${k.employeeCode})</option>`).join('');
  openModal('New Advance', `
    <div class="form-group"><label>Karagar *</label><select id="af-karagar"><option value="">Select…</option>${opts}</select></div>
    <div class="form-group"><label>Amount (₹) *</label><input id="af-amount" type="number" step="0.01"/></div>
    <div class="form-group"><label>Payment Mode</label>
      <select id="af-mode"><option>cash</option><option>bank</option><option>upi</option></select>
    </div>
    <div class="form-group"><label>Purpose</label><input id="af-purpose"/></div>
    <div class="form-group"><label>Reference Number</label><input id="af-ref"/></div>
    <div class="modal-footer">
      <button class="btn btn-outline" onclick="closeModal()">Cancel</button>
      <button class="btn btn-primary" onclick="saveAdvance()">Create</button>
    </div>`);
}

async function saveAdvance() {
  const body = {
    karagarId: document.getElementById('af-karagar').value,
    amountRupees: Number(document.getElementById('af-amount').value),
    paymentMode: document.getElementById('af-mode').value,
    purpose: document.getElementById('af-purpose').value.trim(),
    referenceNumber: document.getElementById('af-ref').value.trim(),
  };
  if (!body.karagarId || !body.amountRupees) return alert('Fill required fields');
  try {
    await api.post('/advances', body);
    closeModal();
    loadAdvances();
  } catch (e) { alert(e.message); }
}

function openRepay(id, name, outstanding) {
  openModal('Record Repayment', `
    <p style="margin-bottom:16px;color:#6b6560">Karagar: <strong>${name}</strong> — Outstanding: <strong>${fmtRs(outstanding)}</strong></p>
    <div class="form-group"><label>Repayment Amount (₹) *</label><input id="rp-amount" type="number" step="0.01" max="${outstanding}"/></div>
    <div class="modal-footer">
      <button class="btn btn-outline" onclick="closeModal()">Cancel</button>
      <button class="btn btn-success" onclick="saveRepay('${id}')">Record</button>
    </div>`);
}

async function saveRepay(id) {
  const amount = Number(document.getElementById('rp-amount').value);
  if (!amount) return alert('Enter amount');
  try {
    await api.post('/advances/' + id + '/repay', { amountRupees: amount });
    closeModal();
    loadAdvances();
  } catch (e) { alert(e.message); }
}

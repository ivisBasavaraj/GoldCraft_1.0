async function loadTreasury() {
  const el = document.getElementById('page-treasury');
  el.innerHTML = `
    <div class="page-header"><div><h2>Treasury</h2><p>Gold stock management</p></div></div>
    <div id="tr-summary"></div>
    <div class="section-title">Recent Transactions</div>
    <div id="tr-table" class="table-wrap"></div>`;
  try {
    const [summary, txData] = await Promise.all([
      api.get('/treasury/summary'),
      api.get('/treasury/transactions'),
    ]);
    const t = summary;
    document.getElementById('tr-summary').innerHTML = `
      <div class="treasury-card">
        <h3>Gold Treasury</h3>
        <div class="big-num">${fmt(t.availableGoldGrams,1)}g <span style="font-size:16px;opacity:.6">available</span></div>
        <div class="treasury-progress"><div class="treasury-progress-bar" style="width:${Math.min(t.reserveRemainingPercent,100).toFixed(1)}%"></div></div>
        <div class="treasury-stats">
          <div class="treasury-stat"><label>Opening Reserve</label><span>${fmt(t.openingReserveGrams,1)}g</span></div>
          <div class="treasury-stat"><label>Issued</label><span>${fmt(t.issuedGoldGrams,1)}g</span></div>
          <div class="treasury-stat"><label>Returned</label><span>${fmt(t.returnedGoldGrams,1)}g</span></div>
        </div>
      </div>
      <div class="stats-grid" style="margin-bottom:24px">
        <div class="stat-card"><div class="stat-label">In Circulation</div><div class="stat-value">${fmt(t.inCirculationGrams,1)}g</div></div>
        <div class="stat-card"><div class="stat-label">Reserve Used</div><div class="stat-value">${fmt(100-t.reserveRemainingPercent,1)}%</div></div>
      </div>`;
    const txs = txData.items || [];
    if (!txs.length) {
      empty('tr-table', '&#127981;', 'No transactions yet');
    } else {
      document.getElementById('tr-table').innerHTML = `
        <table><thead><tr><th>Date</th><th>Type</th><th>Weight (g)</th><th>Notes</th></tr></thead>
        <tbody>${txs.map(tx => `
          <tr>
            <td>${fmtDate(tx.createdAt)}</td>
            <td>${badge(tx.type || tx.transactionType || '—', 'info')}</td>
            <td>${fmt(tx.weightGrams || tx.amountGrams || 0, 3)}</td>
            <td>${tx.notes || '—'}</td>
          </tr>`).join('')}
        </tbody></table>`;
    }
  } catch (e) {
    el.innerHTML += `<div class="alert alert-error">${e.message}</div>`;
  }
}

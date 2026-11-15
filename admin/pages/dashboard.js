async function loadDashboard() {
  const el = document.getElementById('page-dashboard');
  el.innerHTML = `
    <div class="page-header"><div><h2>Dashboard</h2><p>Workshop overview</p></div></div>
    <div id="dash-stats" class="stats-grid"></div>
    <div id="dash-treasury"></div>
    <div class="section-title">Recent Jobs</div>
    <div id="dash-jobs" class="table-wrap"></div>`;
  try {
    const [summary, jobs] = await Promise.all([
      api.get('/dashboard/summary'),
      api.get('/jobs?limit=5'),
    ]);
    const t = summary.treasury || {};
    document.getElementById('dash-stats').innerHTML = `
      <div class="stat-card"><div class="stat-icon" style="background:#fff0d9">&#128100;</div><div class="stat-label">Active Karagars</div><div class="stat-value">${summary.totalKaragars}</div></div>
      <div class="stat-card"><div class="stat-icon" style="background:#e8f3e8">&#9878;</div><div class="stat-label">Gold Issued</div><div class="stat-value">${fmt(summary.totalGoldIssuedGrams, 1)}g</div></div>
      <div class="stat-card"><div class="stat-icon" style="background:#e3f2fd">&#128176;</div><div class="stat-label">Total Advances</div><div class="stat-value">${fmtRs(summary.totalAdvancePaidRupees)}</div></div>
      <div class="stat-card"><div class="stat-icon" style="background:#f3e5f5">&#128203;</div><div class="stat-label">Total Salary</div><div class="stat-value">${fmtRs(summary.totalSalaryRupees)}</div></div>`;
    document.getElementById('dash-treasury').innerHTML = `
      <div class="treasury-card">
        <h3>Gold Treasury</h3>
        <div class="big-num">${fmt(t.availableGoldGrams, 1)}g <span style="font-size:16px;opacity:.6">available</span></div>
        <div class="treasury-progress"><div class="treasury-progress-bar" style="width:${Math.min(t.reserveRemainingPercent,100).toFixed(1)}%"></div></div>
        <div class="treasury-stats">
          <div class="treasury-stat"><label>Opening Reserve</label><span>${fmt(t.openingReserveGrams,1)}g</span></div>
          <div class="treasury-stat"><label>In Circulation</label><span>${fmt(t.inCirculationGrams,1)}g</span></div>
          <div class="treasury-stat"><label>Returned</label><span>${fmt(t.returnedGoldGrams,1)}g</span></div>
        </div>
      </div>`;
    const rows = (jobs.items || []).slice(0, 5).map(j => `
      <tr><td><strong>${j.jobNumber}</strong></td><td>${j.title}</td><td>${j.karagarName}</td>
      <td>${statusBadge(j.status)}</td><td>${fmtDate(j.dueDate)}</td></tr>`).join('');
    document.getElementById('dash-jobs').innerHTML = rows
      ? `<table><thead><tr><th>Job#</th><th>Title</th><th>Karagar</th><th>Status</th><th>Due</th></tr></thead><tbody>${rows}</tbody></table>`
      : `<div class="empty"><div class="empty-icon">&#128295;</div><h3>No jobs yet</h3></div>`;
  } catch (e) {
    el.innerHTML += `<div class="alert alert-error">${e.message}</div>`;
  }
}

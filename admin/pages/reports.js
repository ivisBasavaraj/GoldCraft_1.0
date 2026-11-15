async function loadReports() {
  const el = document.getElementById('page-reports');
  el.innerHTML = `
    <div class="page-header"><div><h2>Reports</h2><p>Analytics & insights</p></div></div>
    <div id="rp-stats" class="stats-grid"></div>
    <div class="section-title">Jobs by Status</div>
    <div id="rp-status" class="table-wrap" style="margin-bottom:24px"></div>
    <div class="section-title">Melting Groups</div>
    <div id="rp-groups" class="table-wrap"></div>`;
  try {
    const [dash, groups] = await Promise.all([
      api.get('/reports/dashboard'),
      api.get('/reports/melting-groups'),
    ]);
    document.getElementById('rp-stats').innerHTML = `
      <div class="stat-card"><div class="stat-label">Active Karagars</div><div class="stat-value">${dash.activeKaragars}</div></div>
      <div class="stat-card"><div class="stat-label">Total Jobs</div><div class="stat-value">${dash.jobs.total}</div></div>
      <div class="stat-card"><div class="stat-label">Gold In Circulation</div><div class="stat-value">${fmt(dash.gold.inCirculationGrams,1)}g</div></div>
      <div class="stat-card"><div class="stat-label">Outstanding Advances</div><div class="stat-value">${fmtRs(dash.advances.totalOutstandingRupees)}</div></div>
      <div class="stat-card"><div class="stat-label">Pending Payrolls</div><div class="stat-value">${dash.pendingPayrolls}</div></div>`;

    const byStatus = dash.jobs.byStatus || {};
    const statusRows = Object.entries(byStatus).map(([s, c]) =>
      `<tr><td>${statusBadge(s)}</td><td>${c}</td><td>${dash.jobs.total ? ((c/dash.jobs.total)*100).toFixed(1) : 0}%</td></tr>`
    ).join('');
    document.getElementById('rp-status').innerHTML = statusRows
      ? `<table><thead><tr><th>Status</th><th>Count</th><th>Share</th></tr></thead><tbody>${statusRows}</tbody></table>`
      : `<div class="empty"><div class="empty-icon">&#128202;</div><h3>No job data</h3></div>`;

    const gRows = (groups || []).map(g => `
      <tr>
        <td><strong>Group ${g._id}</strong></td>
        <td>${g.totalJobs}</td>
        <td>${g.activeJobs}</td>
        <td>${g.completedJobs}</td>
        <td>${fmt(g.totalIssuedGrams,2)}g</td>
        <td>${fmt(g.totalReturnedGrams,2)}g</td>
        <td>${fmt(g.totalIssuedGrams - g.totalReturnedGrams,2)}g</td>
      </tr>`).join('');
    document.getElementById('rp-groups').innerHTML = gRows
      ? `<table><thead><tr><th>Group</th><th>Total Jobs</th><th>Active</th><th>Completed</th><th>Issued</th><th>Returned</th><th>In Circulation</th></tr></thead><tbody>${gRows}</tbody></table>`
      : `<div class="empty"><div class="empty-icon">&#9878;</div><h3>No group data</h3></div>`;
  } catch (e) {
    el.innerHTML += `<div class="alert alert-error">${e.message}</div>`;
  }
}

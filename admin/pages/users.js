async function loadUsers() {
  const el = document.getElementById('page-users');
  el.innerHTML = `
    <div class="page-header">
      <div><h2>Users</h2><p>System access management</p></div>
      <button class="btn btn-outline" onclick="seedUsers()">Seed Demo Users</button>
    </div>
    <div id="usr-info" class="alert alert-success hidden">Demo users seeded successfully.</div>
    <div class="table-wrap">
      <div id="usr-table"></div>
    </div>`;

  // Show current user info from localStorage
  const user = JSON.parse(localStorage.getItem('gc_user') || 'null');
  const demoUsers = [
    { name: 'Workshop Manager', username: 'manager', role: 'manager', employeeCode: 'MGR-001' },
    { name: 'Admin User',       username: 'admin',   role: 'admin',   employeeCode: 'ADM-001' },
    { name: 'Raju Kumar',       username: 'karagar1',role: 'karagar', employeeCode: 'GC-001'  },
    { name: 'Suresh Patil',     username: 'karagar2',role: 'karagar', employeeCode: 'GC-002'  },
  ];
  const roleColor = { admin: 'error', manager: 'warning', karagar: 'info' };
  document.getElementById('usr-table').innerHTML = `
    <div style="padding:16px 20px;border-bottom:1px solid #eee8e2;font-size:13px;color:#6b6560">
      Logged in as: <strong>${user ? user.name : '—'}</strong> (${user ? user.role : '—'})
    </div>
    <table><thead><tr><th>Name</th><th>Username</th><th>Role</th><th>Employee Code</th><th>Default Password</th></tr></thead>
    <tbody>${demoUsers.map(u => `
      <tr>
        <td><strong>${u.name}</strong></td>
        <td><code>${u.username}</code></td>
        <td>${badge(u.role, roleColor[u.role] || 'neutral')}</td>
        <td>${u.employeeCode}</td>
        <td><code>demo1234</code></td>
      </tr>`).join('')}
    </tbody></table>`;
}

async function seedUsers() {
  if (!confirm('This will reset all users to demo defaults. Continue?')) return;
  try {
    await api.post('/auth/seed', {});
    document.getElementById('usr-info').classList.remove('hidden');
    setTimeout(() => document.getElementById('usr-info').classList.add('hidden'), 3000);
  } catch (e) { alert(e.message); }
}

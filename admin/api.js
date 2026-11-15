const BASE = 'https://gold-backend-ym0j.onrender.com/api/v1';

const api = {
  token: null,

  async req(method, path, body) {
    const headers = { 'Content-Type': 'application/json' };
    if (this.token) headers['Authorization'] = 'Bearer ' + this.token;
    const res = await fetch(BASE + path, {
      method,
      headers,
      body: body ? JSON.stringify(body) : undefined,
    });
    const data = await res.json();
    if (!res.ok) throw new Error(data.message || 'Request failed');
    return data.data !== undefined ? data.data : data;
  },

  get: (path) => api.req('GET', path),
  post: (path, body) => api.req('POST', path, body),
  patch: (path, body) => api.req('PATCH', path, body),
  delete: (path) => api.req('DELETE', path),
};

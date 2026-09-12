import { useState, useEffect } from 'react'
import { supabase } from './supabase'
import './App.css'

// ── Types ──────────────────────────────────────────────────────────────────
export interface Alumni {
  id?: number
  name: string
  course: string
  batch: string
  company: string
  status: 'Employed' | 'Freelance' | 'Seeking' | 'Studying'
  email?: string
}

// ── Fallback sample data ───────────────────────────────────────────────────
const SAMPLE_DATA: Omit<Alumni, 'id'>[] = [
  { name: 'Maria Santos',    course: 'BS Computer Science', batch: '2021', company: 'Accenture PH',     status: 'Employed',  email: 'maria.santos@gmail.com' },
  { name: 'Jose Reyes',      course: 'BS Information Tech', batch: '2022', company: 'Freelance Dev',    status: 'Freelance', email: 'jose.reyes@tech.io' },
  { name: 'Ana Cruz',        course: 'BS Accountancy',      batch: '2020', company: 'BDO Unibank',      status: 'Employed',  email: 'ana.cruz@bdo.com.ph' },
  { name: 'Marco Dela Vega', course: 'BS Nursing',          batch: '2023', company: 'PGH Manila',       status: 'Employed',  email: 'marco.dlv@pgh.gov.ph' },
  { name: 'Liza Flores',     course: 'BS Education',        batch: '2022', company: 'DepEd',            status: 'Employed',  email: 'liza.flores@deped.gov.ph' },
  { name: 'Ryan Bautista',   course: 'BS Engineering',      batch: '2021', company: 'DLSU Grad School', status: 'Studying',  email: 'ryan.bautista@dlsu.edu.ph' },
  { name: 'Claire Gomez',    course: 'BS Criminology',      batch: '2023', company: '—',                status: 'Seeking',   email: 'claire.gomez@yahoo.com' },
]

const STATUS_BADGE: Record<Alumni['status'], string> = {
  Employed:  'badge-success',
  Freelance: 'badge-info',
  Seeking:   'badge-warning',
  Studying:  'badge-warning',
}

// ── Clock ──────────────────────────────────────────────────────────────────
function Clock() {
  const [time, setTime] = useState('')
  useEffect(() => {
    const tick = () =>
      setTime(new Date().toLocaleTimeString('en-PH', { hour: '2-digit', minute: '2-digit', second: '2-digit', hour12: true }))
    tick()
    const id = setInterval(tick, 1000)
    return () => clearInterval(id)
  }, [])
  return <span className="topbar-clock">{time}</span>
}

// ── Stat Card ──────────────────────────────────────────────────────────────
function StatCard({ label, value, accent }: { label: string; value: number | string; accent?: string }) {
  return (
    <div className="stat-card" style={accent ? { borderLeftColor: accent } : {}}>
      <div className="stat-label">{label}</div>
      <div className="stat-value">{value}</div>
    </div>
  )
}

// ── Add Alumni Modal ───────────────────────────────────────────────────────
function AddAlumniModal({ isOpen, onClose, onAdd }: { isOpen: boolean; onClose: () => void; onAdd: (alumni: Omit<Alumni, 'id'>) => Promise<void> }) {
  const [name, setName] = useState('')
  const [course, setCourse] = useState('BS Information Technology')
  const [batch, setBatch] = useState('2024')
  const [company, setCompany] = useState('')
  const [status, setStatus] = useState<Alumni['status']>('Employed')
  const [email, setEmail] = useState('')
  const [saving, setSaving] = useState(false)

  if (!isOpen) return null

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    if (!name.trim()) return
    setSaving(true)
    await onAdd({ name, course, batch, company: company || '—', status, email })
    setSaving(false)
    setName('')
    setCompany('')
    setEmail('')
    onClose()
  }

  return (
    <div style={{
      position: 'fixed', top: 0, left: 0, right: 0, bottom: 0,
      background: 'rgba(0, 0, 0, 0.5)', display: 'flex', alignItems: 'center', justifyContent: 'center', zIndex: 1000
    }}>
      <div style={{ background: '#fff', padding: '24px 30px', borderRadius: '12px', width: '100%', maxWidth: '480px', boxShadow: '0 10px 30px rgba(0,0,0,0.2)' }}>
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '16px' }}>
          <h2 style={{ fontSize: '18px', margin: 0, color: 'var(--brand-primary)', display: 'flex', alignItems: 'center', gap: '8px' }}>
            <span className="material-symbols-outlined">person_add</span> Add New Alumni
          </h2>
          <button onClick={onClose} style={{ background: 'none', border: 'none', fontSize: '20px', cursor: 'pointer' }}>✕</button>
        </div>

        <form onSubmit={handleSubmit}>
          <div className="form-group">
            <label className="form-label">Full Name *</label>
            <input required className="form-control" placeholder="e.g. Juan Dela Cruz" value={name} onChange={e => setName(e.target.value)} />
          </div>

          <div className="form-group">
            <label className="form-label">Course / Degree</label>
            <select className="form-control" value={course} onChange={e => setCourse(e.target.value)} required>
              <option value="BS Information Technology">BS Information Technology</option>
              <option value="BS Tourism">BS Tourism</option>
              <option value="BS Hospitality Management">BS Hospitality Management</option>
              <option value="BS Computer Science">BS Computer Science</option>
              <option value="BS Business Administration">BS Business Administration</option>
              <option value="BS Criminology">BS Criminology</option>
              <option value="BS Accountancy">BS Accountancy</option>
              <option value="BS Education">BS Education</option>
              <option value="Other">Other / Not Listed</option>
            </select>
          </div>

          <div style={{ display: 'flex', gap: '12px' }}>
            <div className="form-group" style={{ flex: 1 }}>
              <label className="form-label">Batch Year</label>
              <input required className="form-control" placeholder="e.g. 2024" value={batch} onChange={e => setBatch(e.target.value)} />
            </div>
            <div className="form-group" style={{ flex: 1 }}>
              <label className="form-label">Status</label>
              <select className="form-control" value={status} onChange={e => setStatus(e.target.value as Alumni['status'])}>
                <option value="Employed">Employed</option>
                <option value="Freelance">Freelance</option>
                <option value="Seeking">Seeking</option>
                <option value="Studying">Studying</option>
              </select>
            </div>
          </div>

          <div className="form-group">
            <label className="form-label">Company / Current Affiliation</label>
            <input className="form-control" placeholder="e.g. Google PH or Freelance" value={company} onChange={e => setCompany(e.target.value)} />
          </div>

          <div className="form-group">
            <label className="form-label">Email Address</label>
            <input type="email" className="form-control" placeholder="e.g. juan@gmail.com" value={email} onChange={e => setEmail(e.target.value)} />
          </div>

          <div style={{ display: 'flex', gap: '10px', justifyContent: 'flex-end', marginTop: '20px' }}>
            <button type="button" className="btn btn-outline" onClick={onClose} disabled={saving}>Cancel</button>
            <button type="submit" className="btn btn-primary" disabled={saving}>
              {saving ? 'Saving...' : 'Save to Database'}
            </button>
          </div>
        </form>
      </div>
    </div>
  )
}

// ── Pages ──────────────────────────────────────────────────────────────────
function Dashboard({ alumni, onDelete, onOpenModal, onSeed }: { alumni: Alumni[]; onDelete: (id: number) => void; onOpenModal: () => void; onSeed: () => void }) {
  const employed  = alumni.filter(a => a.status === 'Employed').length
  const seeking   = alumni.filter(a => a.status === 'Seeking').length
  const freelance = alumni.filter(a => a.status === 'Freelance').length

  return (
    <>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '20px', flexWrap: 'wrap', gap: '12px' }}>
        <h1 className="page-title" style={{ margin: 0, display: 'flex', alignItems: 'center', gap: '8px' }}>
          <span className="material-symbols-outlined" style={{ fontSize: '1.6rem' }}>dashboard</span> Alumni Management Dashboard
        </h1>
        <div style={{ display: 'flex', gap: '10px' }}>
          {alumni.length === 0 && (
            <button className="btn btn-outline" onClick={onSeed} style={{ display: 'inline-flex', alignItems: 'center', gap: '6px' }}>
              <span className="material-symbols-outlined" style={{ fontSize: '1.1rem' }}>dataset</span> Populate Sample Data
            </button>
          )}
          <button className="btn btn-primary" onClick={onOpenModal} style={{ display: 'inline-flex', alignItems: 'center', gap: '6px' }}>
            <span className="material-symbols-outlined" style={{ fontSize: '1.1rem' }}>person_add</span> Add Alumni
          </button>
        </div>
      </div>

      <div className="stat-grid">
        <StatCard label="Total Alumni" value={alumni.length} />
        <StatCard label="Employed"     value={employed}   accent="var(--color-success)" />
        <StatCard label="Freelance"    value={freelance}  accent="var(--brand-accent)"  />
        <StatCard label="Job Seeking"  value={seeking}    accent="var(--color-warning)" />
      </div>

      <div className="card">
        <div className="card-header">
          <h3 style={{ display: 'flex', alignItems: 'center', gap: '6px' }}>
            <span className="material-symbols-outlined" style={{ fontSize: '1.2rem' }}>table_rows</span> Recent Alumni Records (Live from Supabase)
          </h3>
          <span className="badge badge-info">{alumni.length} Total</span>
        </div>
        <table className="data-table">
          <thead>
            <tr>
              <th>ID</th>
              <th>Name</th>
              <th>Course</th>
              <th>Batch</th>
              <th>Company</th>
              <th>Status</th>
              <th>Action</th>
            </tr>
          </thead>
          <tbody>
            {alumni.length === 0 ? (
              <tr className="empty-row">
                <td colSpan={7}>No records found in database. Click "Add Alumni" or "Populate Sample Data" above!</td>
              </tr>
            ) : (
              alumni.map(a => (
                <tr key={a.id}>
                  <td>#{a.id}</td>
                  <td><strong>{a.name}</strong></td>
                  <td>{a.course}</td>
                  <td>{a.batch}</td>
                  <td>{a.company}</td>
                  <td><span className={`badge ${STATUS_BADGE[a.status] || 'badge-info'}`}>{a.status}</span></td>
                  <td>
                    {a.id && (
                      <button 
                        onClick={() => onDelete(a.id!)} 
                        style={{ background: 'none', border: 'none', color: 'var(--color-danger)', cursor: 'pointer', fontWeight: 600, fontSize: '13px', display: 'inline-flex', alignItems: 'center', gap: '4px' }}
                      >
                        <span className="material-symbols-outlined" style={{ fontSize: '1.1rem' }}>delete</span> Delete
                      </button>
                    )}
                  </td>
                </tr>
              ))
            )}
          </tbody>
        </table>
      </div>
    </>
  )
}

function AlumniDirectory({ alumni, onOpenModal }: { alumni: Alumni[]; onOpenModal: () => void }) {
  const [query, setQuery] = useState('')
  const filtered = alumni.filter(a =>
    a.name.toLowerCase().includes(query.toLowerCase()) ||
    a.course.toLowerCase().includes(query.toLowerCase()) ||
    a.company.toLowerCase().includes(query.toLowerCase())
  )
  return (
    <>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '20px' }}>
        <h1 className="page-title" style={{ margin: 0, display: 'flex', alignItems: 'center', gap: '8px' }}>
          <span className="material-symbols-outlined" style={{ fontSize: '1.6rem' }}>group</span> Alumni Directory
        </h1>
        <button className="btn btn-primary" onClick={onOpenModal} style={{ display: 'inline-flex', alignItems: 'center', gap: '6px' }}>
          <span className="material-symbols-outlined" style={{ fontSize: '1.1rem' }}>person_add</span> Add Alumni
        </button>
      </div>

      <div className="card">
        <div className="card-header"><h3>Search Alumni</h3></div>
        <div className="form-group" style={{ marginBottom: 0 }}>
          <input
            id="alumni-search"
            className="form-control"
            placeholder="Search by name, course, or company…"
            value={query}
            onChange={e => setQuery(e.target.value)}
          />
        </div>
      </div>
      <div className="card">
        <div className="card-header">
          <h3>Results</h3>
          <span className="badge badge-info">{filtered.length} found</span>
        </div>
        <table className="data-table">
          <thead><tr><th>Name</th><th>Course</th><th>Batch</th><th>Company</th><th>Status</th><th>Email</th></tr></thead>
          <tbody>
            {filtered.length === 0
              ? <tr className="empty-row"><td colSpan={6}>No alumni found matching your query.</td></tr>
              : filtered.map(a => (
                  <tr key={a.id}>
                    <td><strong>{a.name}</strong></td>
                    <td>{a.course}</td>
                    <td>{a.batch}</td>
                    <td>{a.company}</td>
                    <td><span className={`badge ${STATUS_BADGE[a.status] || 'badge-info'}`}>{a.status}</span></td>
                    <td>{a.email || '—'}</td>
                  </tr>
                ))
            }
          </tbody>
        </table>
      </div>
    </>
  )
}

function Reports({ alumni }: { alumni: Alumni[] }) {
  const statuses: Alumni['status'][] = ['Employed', 'Freelance', 'Seeking', 'Studying']
  const total = alumni.length || 1
  const byStatus = statuses.map(s => {
    const count = alumni.filter(a => a.status === s).length
    return {
      label: s,
      count,
      pct: Math.round((count / total) * 100),
    }
  })
  const byBatch = [...new Set(alumni.map(a => a.batch))].filter(Boolean).sort().map(b => {
    const count = alumni.filter(a => a.batch === b).length
    return {
      batch: b,
      count,
      pct: Math.round((count / total) * 100),
    }
  })

  return (
    <>
      <h1 className="page-title" style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
        <span className="material-symbols-outlined" style={{ fontSize: '1.6rem' }}>analytics</span> Reports & Analytics
      </h1>
      <div className="stat-grid" style={{ gridTemplateColumns: 'repeat(auto-fit,minmax(240px,1fr))' }}>
        {byStatus.map(s => (
          <div className="card" key={s.label} style={{ marginBottom: 0 }}>
            <div className="stat-label">{s.label}</div>
            <div className="stat-value">{s.count}</div>
            <div style={{ marginTop: 10, background: 'var(--bg-page)', borderRadius: 6, height: 8 }}>
              <div style={{ width: `${s.pct}%`, background: 'var(--brand-accent)', height: 8, borderRadius: 6, transition: 'width .4s' }} />
            </div>
            <div style={{ fontSize: 12, color: 'var(--text-secondary)', marginTop: 4 }}>{s.pct}% of total</div>
          </div>
        ))}
      </div>
      <div className="card" style={{ marginTop: 22 }}>
        <div className="card-header"><h3>Alumni by Batch Year</h3></div>
        <table className="data-table">
          <thead><tr><th>Batch</th><th>Count</th><th>Distribution</th></tr></thead>
          <tbody>
            {byBatch.length === 0 ? (
              <tr className="empty-row"><td colSpan={3}>No data to display.</td></tr>
            ) : (
              byBatch.map(b => (
                <tr key={b.batch}>
                  <td><strong>{b.batch}</strong></td>
                  <td>{b.count}</td>
                  <td>
                    <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
                      <div style={{ flex: 1, background: 'var(--bg-page)', borderRadius: 4, height: 6 }}>
                        <div style={{ width: `${b.pct}%`, background: 'var(--brand-accent)', height: 6, borderRadius: 4 }} />
                      </div>
                      <span style={{ fontSize: 12, color: 'var(--text-secondary)' }}>{b.pct}%</span>
                    </div>
                  </td>
                </tr>
              ))
            )}
          </tbody>
        </table>
      </div>
    </>
  )
}

// ── Main App ────────────────────────────────────────────────────────────────
type Page = 'dashboard' | 'directory' | 'reports'

export default function App() {
  const [page, setPage]           = useState<Page>('dashboard')
  const [sidebarOpen, setSidebar] = useState(false)
  const [banner, setBanner]       = useState(true)
  const [modalOpen, setModalOpen] = useState(false)
  const [alumni, setAlumni]       = useState<Alumni[]>([])
  const [loading, setLoading]     = useState(true)
  const [dbError, setDbError]     = useState<string | null>(null)

  // Fetch alumni from Supabase
  const fetchAlumni = async () => {
    setLoading(true)
    setDbError(null)
    try {
      const { data, error } = await supabase
        .from('alumni')
        .select('*')

      if (error) {
        console.error('Supabase query error:', error)
        setDbError(error.message)
      } else if (data) {
        setAlumni(data)
      }
    } catch (err: any) {
      console.error('Failed to connect to Supabase:', err)
      setDbError(err.message || 'Connection error')
    } finally {
      setLoading(false)
    }
  }

  useEffect(() => {
    fetchAlumni()
  }, [])

  // Add new alumni to Supabase
  const handleAddAlumni = async (item: Omit<Alumni, 'id'>) => {
    const { data, error } = await supabase.from('alumni').insert([item]).select()
    if (error) {
      alert('Error saving alumni: ' + error.message)
    } else if (data) {
      setAlumni(prev => [data[0], ...prev])
    }
  }

  // Delete alumni
  const handleDelete = async (id: number) => {
    if (!confirm('Are you sure you want to delete this alumni record?')) return
    const { error } = await supabase.from('alumni').delete().eq('id', id)
    if (error) {
      alert('Error deleting: ' + error.message)
    } else {
      setAlumni(prev => prev.filter(a => a.id !== id))
    }
  }

  // Seed initial sample data
  const handleSeed = async () => {
    setLoading(true)
    const { data, error } = await supabase.from('alumni').insert(SAMPLE_DATA).select()
    if (error) {
      alert('Error seeding data: ' + error.message)
    } else if (data) {
      setAlumni(data)
    }
    setLoading(false)
  }

  const nav = (p: Page) => { setPage(p); setSidebar(false) }

  return (
    <>
      {/* Topbar */}
      <header className="topbar">
        <div className="topbar-left">
          <button className="topbar-icon-btn" id="sidebarToggle" title="Menu" onClick={() => setSidebar(o => !o)}>
            <span className="material-symbols-outlined" style={{ verticalAlign: 'middle' }}>menu</span>
          </button>
          <div className="topbar-brand">
            <img className="brand-mark-img" src="/assets/img/bcplogo.png" alt="BCP logo" />
            BCP Alumni System
          </div>
        </div>
        <div className="topbar-search">
          <span className="material-symbols-outlined" style={{ fontSize: '1.15rem', color: 'var(--text-secondary)' }}>search</span>
          <input type="text" placeholder="Search modules and pages…" />
        </div>
        <div className="topbar-right">
          <Clock />
          <button className="topbar-icon-btn" title="Notifications">
            <span className="material-symbols-outlined">notifications</span>
          </button>
          <button className="topbar-icon-btn" title="Messages">
            <span className="material-symbols-outlined">mail</span>
          </button>
          <div className="topbar-user">
            <div className="avatar">JD</div>
            <span>Juan Dela Cruz</span>
          </div>
        </div>
      </header>

      {/* Sidebar */}
      <aside className={`sidebar${sidebarOpen ? ' open' : ''}`} id="sidebar">
        <div className="sidebar-section-label">Dashboard</div>
        <a className={`sidebar-link${page === 'dashboard' ? ' active' : ''}`} href="#" onClick={e => { e.preventDefault(); nav('dashboard') }}>
          <span className="material-symbols-outlined icon">dashboard</span> Overview
        </a>
        <div className="sidebar-section-label">Alumni</div>
        <a className={`sidebar-link${page === 'directory' ? ' active' : ''}`} href="#" onClick={e => { e.preventDefault(); nav('directory') }}>
          <span className="material-symbols-outlined icon">group</span> Directory
        </a>
        <a className={`sidebar-link${page === 'reports' ? ' active' : ''}`} href="#" onClick={e => { e.preventDefault(); nav('reports') }}>
          <span className="material-symbols-outlined icon">analytics</span> Reports
        </a>
      </aside>

      {/* Main Content */}
      <main className="main-content">
        {dbError && (
          <div className="banner" style={{ background: 'var(--color-danger-bg)', borderColor: 'var(--color-danger)', color: 'var(--color-danger)' }}>
            <span style={{ display: 'inline-flex', alignItems: 'center', gap: '6px' }}>
              <span className="material-symbols-outlined">warning</span> Supabase Note: {dbError}. (Make sure table <code>alumni</code> exists in Supabase and RLS policies allow read/write).
            </span>
          </div>
        )}

        {banner && (
          <div className="banner" id="welcomeBanner">
            <span>
              Connected to <strong>Supabase PostgreSQL Database</strong>! {alumni.length} records loaded.
            </span>
            <button onClick={() => setBanner(false)}>✕</button>
          </div>
        )}

        {loading ? (
          <div style={{ textAlign: 'center', padding: '60px 0', color: 'var(--text-secondary)' }}>
            <div style={{ marginBottom: '8px' }}>
              <span className="material-symbols-outlined" style={{ fontSize: '28px', animation: 'spin 2s linear infinite' }}>hourglass_empty</span>
            </div>
            Loading alumni records from Supabase...
          </div>
        ) : (
          <>
            {page === 'dashboard' && <Dashboard alumni={alumni} onDelete={handleDelete} onOpenModal={() => setModalOpen(true)} onSeed={handleSeed} />}
            {page === 'directory' && <AlumniDirectory alumni={alumni} onOpenModal={() => setModalOpen(true)} />}
            {page === 'reports'   && <Reports alumni={alumni} />}
          </>
        )}
      </main>

      <AddAlumniModal isOpen={modalOpen} onClose={() => setModalOpen(false)} onAdd={handleAddAlumni} />
    </>
  )
}


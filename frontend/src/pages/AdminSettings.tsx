import { useEffect, useState } from 'react';
import {
  Bell, Brain, CheckCircle2, Database,
  Globe, Key, LockKeyhole, Palette, ScrollText
} from 'lucide-react';
import AdminBackButton from '../components/AdminBackButton';
import { api } from '../services/api';
import { useTheme } from '../hooks/useTheme';

type SettingsCategory =
  | 'security'
  | 'ai'
  | 'database'
  | 'notifications'
  | 'integrations'
  | 'retention'
  | 'appearance';

interface SystemHealth {
  api?: string;
  database?: string;
  ml_model?: string;
  model_version?: string | null;
  chromadb?: string;
  chromadb_vectors?: number | null;
  chromadb_expected_minimum?: number;
  embedding?: string;
  llm?: string;
}

export default function AdminSettings() {
  const [activeTab, setActiveTab] = useState<SettingsCategory>('security');
  const [health, setHealth] = useState<SystemHealth | null>(null);
  const { theme, toggleTheme } = useTheme();

  // Local preferences stored in localStorage
  const [defaultDays, setDefaultDays] = useState(() => {
    return Number(localStorage.getItem('scamshield_admin_default_days') || '30');
  });
  const [denseMode, setDenseMode] = useState(() => {
    return localStorage.getItem('scamshield_admin_dense_mode') === 'true';
  });
  const [saveNotice, setSaveNotice] = useState<string | null>(null);

  useEffect(() => {
    const fetchHealth = async () => {
      try {
        const res = await api.get('/admin/monitoring/health');
        setHealth(res.data);
      } catch (e) {
        console.error('Failed to ping health for settings', e);
      }
    };
    void fetchHealth();
  }, []);

  const handleSavePreferences = () => {
    localStorage.setItem('scamshield_admin_default_days', String(defaultDays));
    localStorage.setItem('scamshield_admin_dense_mode', String(denseMode));
    setSaveNotice('Portal preferences saved successfully.');
    setTimeout(() => setSaveNotice(null), 3000);
  };

  const categories: Array<{ id: SettingsCategory; label: string; icon: any; count?: string }> = [
    { id: 'security', label: 'Security & Access', icon: LockKeyhole },
    { id: 'ai', label: 'AI & Detection Models', icon: Brain, count: 'v5' },
    { id: 'database', label: 'Database & Knowledge Store', icon: Database, count: '972 vec' },
    { id: 'notifications', label: 'Alerts & Notifications', icon: Bell },
    { id: 'integrations', label: 'Integrations & External APIs', icon: Globe },
    { id: 'retention', label: 'Retention & Compliance', icon: ScrollText },
    { id: 'appearance', label: 'Portal Appearance', icon: Palette },
  ];

  return (
    <div className="mx-auto max-w-7xl space-y-6 pb-12">
      {/* Header */}
      <header className="flex flex-col gap-4 @content-sm:flex-row @content-sm:items-center @content-sm:justify-between">
        <div>
          <div className="flex items-center gap-2">
            <span className="text-xs font-semibold uppercase tracking-wider text-primary">System Administration</span>
            <span className="inline-flex items-center gap-1 rounded-full bg-success/10 px-2 py-0.5 text-[10px] font-bold text-success">
              <span className="h-1.5 w-1.5 rounded-full bg-success" />
              RBAC Enforced
            </span>
          </div>
          <h1 className="mt-1 text-3xl font-bold tracking-tight text-text-main">System Settings & Controls</h1>
          <p className="mt-1 text-sm text-text-muted">
            Configure system parameters, review active security configurations, inspect model thresholds, and adjust preferences.
          </p>
        </div>
        <AdminBackButton to="/admin" label="Back to Dashboard" />
      </header>

      {saveNotice && (
        <div role="status" className="rounded-xl border border-success/30 bg-success/10 px-4 py-3 text-sm font-semibold text-success flex items-center gap-2">
          <CheckCircle2 size={16} />
          {saveNotice}
        </div>
      )}

      {/* Main Settings Tabs & Content Layout */}
      <div className="grid grid-cols-1 gap-6 @content-lg:grid-cols-4">
        {/* Navigation Sidebar */}
        <nav aria-label="Settings Categories" className="space-y-1.5 @content-lg:col-span-1">
          {categories.map(({ id, label, icon: Icon, count }) => {
            const active = activeTab === id;
            return (
              <button
                key={id}
                type="button"
                onClick={() => setActiveTab(id)}
                className={`flex w-full items-center justify-between rounded-xl px-3.5 py-3 text-sm font-medium transition-all ${
                  active
                    ? 'border border-primary/20 bg-primary/10 font-bold text-primary shadow-xs'
                    : 'text-text-secondary hover:bg-card hover:text-text-main'
                }`}
              >
                <div className="flex items-center gap-3">
                  <Icon size={18} className={active ? 'text-primary' : 'text-text-muted'} />
                  <span>{label}</span>
                </div>
                {count && (
                  <span className={`rounded-md px-1.5 py-0.5 text-[10px] font-bold ${
                    active ? 'bg-primary text-white' : 'bg-background text-text-muted'
                  }`}>
                    {count}
                  </span>
                )}
              </button>
            );
          })}
        </nav>

        {/* Category Details Panel */}
        <div className="space-y-6 @content-lg:col-span-3">
          {/* TAB 1: Security & Access */}
          {activeTab === 'security' && (
            <div className="space-y-6">
              <section className="rounded-2xl border border-border-light bg-card p-6 shadow-sm">
                <div className="mb-4 flex items-center justify-between border-b border-border-light pb-4">
                  <div className="flex items-center gap-2.5">
                    <span className="grid h-9 w-9 place-items-center rounded-lg bg-primary/10 text-primary">
                      <LockKeyhole size={20} />
                    </span>
                    <div>
                      <h2 className="text-lg font-bold text-text-main">Authentication & Role-Based Access</h2>
                      <p className="text-xs text-text-muted">Session security, token lifetimes, and administrative privileges</p>
                    </div>
                  </div>
                  <span className="rounded-md bg-success/10 px-2.5 py-1 text-xs font-bold text-success">
                    Strict Mode
                  </span>
                </div>

                <div className="grid grid-cols-1 gap-4 @content-sm:grid-cols-2">
                  <div className="rounded-xl border border-border-light bg-background p-4">
                    <span className="text-xs font-semibold text-text-muted">Authentication Scheme</span>
                    <p className="mt-1 font-bold text-text-main">JWT Bearer (HS256)</p>
                    <p className="mt-1 text-xs text-text-muted">Cryptographically signed access tokens validated per request.</p>
                  </div>

                  <div className="rounded-xl border border-border-light bg-background p-4">
                    <span className="text-xs font-semibold text-text-muted">Session Access Token Lifetime</span>
                    <p className="mt-1 font-bold text-text-main">60 Minutes</p>
                    <p className="mt-1 text-xs text-text-muted">Expired tokens require re-authentication. Configured via SECRET_KEY.</p>
                  </div>

                  <div className="rounded-xl border border-border-light bg-background p-4">
                    <span className="text-xs font-semibold text-text-muted">RBAC Hierarchy</span>
                    <p className="mt-1 font-bold text-text-main">Admin vs Regular User</p>
                    <p className="mt-1 text-xs text-text-muted">Admin routes require role="admin" and is_active=true enforced at API layer.</p>
                  </div>

                  <div className="rounded-xl border border-border-light bg-background p-4">
                    <span className="text-xs font-semibold text-text-muted">Credential Security</span>
                    <p className="mt-1 font-bold text-text-main">Argon2 / BCrypt Hash</p>
                    <p className="mt-1 text-xs text-text-muted">Salted hashes stored in database. Passwords never kept in plaintext.</p>
                  </div>
                </div>

                <div className="mt-5 rounded-xl border border-warning/20 bg-warning/5 p-4 text-xs text-text-secondary leading-relaxed">
                  <strong className="text-text-main block mb-1">Administrative Privilege Guardrail</strong>
                  Administrators cannot demote their own account or deactivate the last surviving administrator account. All privilege updates are logged to the immutable audit trail.
                </div>
              </section>
            </div>
          )}

          {/* TAB 2: AI & Detection Models */}
          {activeTab === 'ai' && (
            <div className="space-y-6">
              <section className="rounded-2xl border border-border-light bg-card p-6 shadow-sm">
                <div className="mb-4 flex items-center justify-between border-b border-border-light pb-4">
                  <div className="flex items-center gap-2.5">
                    <span className="grid h-9 w-9 place-items-center rounded-lg bg-primary/10 text-primary">
                      <Brain size={20} />
                    </span>
                    <div>
                      <h2 className="text-lg font-bold text-text-main">AI Model & Threat Classification</h2>
                      <p className="text-xs text-text-muted">Classifier architecture, risk thresholds, and reasoning pipeline</p>
                    </div>
                  </div>
                  <span className="rounded-md bg-primary/10 px-2.5 py-1 text-xs font-bold text-primary">
                    {health?.model_version || 'scamshield-classifier-v5'}
                  </span>
                </div>

                <div className="space-y-4">
                  <div className="grid grid-cols-1 gap-4 @content-sm:grid-cols-3">
                    <div className="rounded-xl border border-border-light bg-background p-4">
                      <span className="text-xs font-semibold text-text-muted">Primary Classifier</span>
                      <p className="mt-1 font-bold text-text-main">DistilBERT / v5 Pipeline</p>
                      <p className="mt-1 text-xs text-text-muted">Fine-tuned on multimodal scam communication corpora.</p>
                    </div>

                    <div className="rounded-xl border border-border-light bg-background p-4">
                      <span className="text-xs font-semibold text-text-muted">LLM Provider</span>
                      <p className="mt-1 font-bold text-text-main">Groq (Llama-3.3-70b)</p>
                      <p className="mt-1 text-xs text-text-muted">High-speed inference for structural risk analysis and advice.</p>
                    </div>

                    <div className="rounded-xl border border-border-light bg-background p-4">
                      <span className="text-xs font-semibold text-text-muted">Semantic Retrieval (RAG)</span>
                      <p className="mt-1 font-bold text-text-main">Top-3 Neighbors (Hit@3)</p>
                      <p className="mt-1 text-xs text-text-muted">Cosine similarity over all-MiniLM-L6-v2 embeddings.</p>
                    </div>
                  </div>

                  {/* Risk Thresholds Visualization */}
                  <div className="rounded-xl border border-border-light bg-background p-5">
                    <h3 className="text-sm font-bold text-text-main mb-3">Risk Tier Scoring Cutoffs</h3>
                    <div className="grid grid-cols-1 gap-3 @content-sm:grid-cols-4">
                      <div className="rounded-lg border border-danger/30 bg-danger/10 p-3">
                        <span className="text-[11px] font-bold text-danger uppercase">Critical Risk</span>
                        <p className="text-xl font-extrabold text-danger mt-1">&ge; 0.85</p>
                        <p className="text-[11px] text-text-muted mt-0.5">Auto-escalates to review</p>
                      </div>
                      <div className="rounded-lg border border-orange-500/30 bg-orange-500/10 p-3">
                        <span className="text-[11px] font-bold text-orange-600 uppercase">High Risk</span>
                        <p className="text-xl font-extrabold text-orange-600 mt-1">&ge; 0.70</p>
                        <p className="text-[11px] text-text-muted mt-0.5">Severe warning flags</p>
                      </div>
                      <div className="rounded-lg border border-warning/30 bg-warning/10 p-3">
                        <span className="text-[11px] font-bold text-warning uppercase">Medium Risk</span>
                        <p className="text-xl font-extrabold text-warning mt-1">&ge; 0.40</p>
                        <p className="text-[11px] text-text-muted mt-0.5">Suspicious signals</p>
                      </div>
                      <div className="rounded-lg border border-success/30 bg-success/10 p-3">
                        <span className="text-[11px] font-bold text-success uppercase">Low Risk</span>
                        <p className="text-xl font-extrabold text-success mt-1">&lt; 0.40</p>
                        <p className="text-[11px] text-text-muted mt-0.5">Clean / genuine communication</p>
                      </div>
                    </div>
                  </div>
                </div>
              </section>
            </div>
          )}

          {/* TAB 3: Database & Knowledge Store */}
          {activeTab === 'database' && (
            <div className="space-y-6">
              <section className="rounded-2xl border border-border-light bg-card p-6 shadow-sm">
                <div className="mb-4 flex items-center justify-between border-b border-border-light pb-4">
                  <div className="flex items-center gap-2.5">
                    <span className="grid h-9 w-9 place-items-center rounded-lg bg-primary/10 text-primary">
                      <Database size={20} />
                    </span>
                    <div>
                      <h2 className="text-lg font-bold text-text-main">Database & Knowledge Vector Store</h2>
                      <p className="text-xs text-text-muted">PostgreSQL persistence, migrations, and ChromaDB vector indexing</p>
                    </div>
                  </div>
                  <span className="rounded-md bg-success/10 px-2.5 py-1 text-xs font-bold text-success">
                    {health?.database === 'healthy' ? 'Database Healthy' : 'Online'}
                  </span>
                </div>

                <div className="grid grid-cols-1 gap-4 @content-sm:grid-cols-2">
                  <div className="rounded-xl border border-border-light bg-background p-4">
                    <span className="text-xs font-semibold text-text-muted">Relational Database Engine</span>
                    <p className="mt-1 font-bold text-text-main">PostgreSQL 16 (Alembic)</p>
                    <p className="mt-1 text-xs text-text-muted">Stores users, analyses, audit logs, reviews, and community reports.</p>
                  </div>

                  <div className="rounded-xl border border-border-light bg-background p-4">
                    <span className="text-xs font-semibold text-text-muted">Vector Store (Semantic Search)</span>
                    <p className="mt-1 font-bold text-text-main">ChromaDB ({health?.chromadb_vectors ?? 972} Vectors)</p>
                    <p className="mt-1 text-xs text-text-muted">
                      Indexed threat pattern chunks from verified knowledge articles (Target: &ge;430).
                    </p>
                  </div>
                </div>

                {/* Explanation of Entry Count vs Vector Count */}
                <div className="mt-4 rounded-xl border border-primary/20 bg-primary/5 p-4 text-xs text-text-secondary leading-relaxed">
                  <div className="flex items-start gap-2.5">
                    <CheckCircle2 size={16} className="text-primary mt-0.5 shrink-0" />
                    <div>
                      <strong className="text-text-main font-semibold">SQL Knowledge Articles vs Vector Chunks:</strong>
                      <p className="mt-1">
                        The relational database currently stores <strong>430 verified knowledge base entries</strong>.
                        When indexed into ChromaDB, longer patterns, distinct scam indicators, and phrasing variations are split into
                        semantic chunks resulting in <strong>972 vector embeddings</strong>. This is expected architecture behavior ensuring
                        optimal retrieval precision during RAG matching.
                      </p>
                    </div>
                  </div>
                </div>
              </section>
            </div>
          )}

          {/* TAB 4: Notifications & Alerting */}
          {activeTab === 'notifications' && (
            <div className="space-y-6">
              <section className="rounded-2xl border border-border-light bg-card p-6 shadow-sm">
                <div className="mb-4 flex items-center justify-between border-b border-border-light pb-4">
                  <div className="flex items-center gap-2.5">
                    <span className="grid h-9 w-9 place-items-center rounded-lg bg-primary/10 text-primary">
                      <Bell size={20} />
                    </span>
                    <div>
                      <h2 className="text-lg font-bold text-text-main">Alerts & Escalation Policies</h2>
                      <p className="text-xs text-text-muted">Automated notification channels for security events</p>
                    </div>
                  </div>
                </div>

                <div className="space-y-4">
                  <div className="rounded-xl border border-border-light bg-background p-4 flex items-center justify-between">
                    <div>
                      <p className="font-bold text-text-main text-sm">Critical Scam Auto-Escalation</p>
                      <p className="text-xs text-text-muted">Automatically queues analyses with score &ge; 0.85 into human review.</p>
                    </div>
                    <span className="rounded-full bg-success/15 px-3 py-1 text-xs font-bold text-success">
                      ENABLED
                    </span>
                  </div>

                  <div className="rounded-xl border border-border-light bg-background p-4 flex items-center justify-between">
                    <div>
                      <p className="font-bold text-text-main text-sm">Review Assignment Alerts</p>
                      <p className="text-xs text-text-muted">Notifies administrators when a new review case is escalated.</p>
                    </div>
                    <span className="rounded-full bg-primary/15 px-3 py-1 text-xs font-bold text-primary">
                      ACTIVE
                    </span>
                  </div>

                  <div className="rounded-xl border border-border-light bg-background p-4 flex items-center justify-between">
                    <div>
                      <p className="font-bold text-text-main text-sm">Daily Digest Summary</p>
                      <p className="text-xs text-text-muted">Aggregates 24-hour volume, critical detections, and community flags.</p>
                    </div>
                    <span className="rounded-full bg-background px-3 py-1 text-xs font-bold text-text-secondary border border-border-light">
                      CONFIGURED ON SERVER
                    </span>
                  </div>
                </div>
              </section>
            </div>
          )}

          {/* TAB 5: Third-Party Integrations */}
          {activeTab === 'integrations' && (
            <div className="space-y-6">
              <section className="rounded-2xl border border-border-light bg-card p-6 shadow-sm">
                <div className="mb-4 flex items-center justify-between border-b border-border-light pb-4">
                  <div className="flex items-center gap-2.5">
                    <span className="grid h-9 w-9 place-items-center rounded-lg bg-primary/10 text-primary">
                      <Globe size={20} />
                    </span>
                    <div>
                      <h2 className="text-lg font-bold text-text-main">External Integrations & APIs</h2>
                      <p className="text-xs text-text-muted">Jira issue tracking, LLM cloud endpoints, and threat intelligence feeds</p>
                    </div>
                  </div>
                </div>

                <div className="space-y-4">
                  {/* Jira Card */}
                  <div className="rounded-xl border border-border-light bg-background p-5">
                    <div className="flex items-center justify-between">
                      <div className="flex items-center gap-2">
                        <span className="font-bold text-text-main">Atlassian Jira Service Desk</span>
                        <span className="rounded bg-primary/10 px-2 py-0.5 text-[10px] font-bold text-primary">
                          Escalations Only
                        </span>
                      </div>
                      <span className="text-xs font-semibold text-text-muted">Server Configured</span>
                    </div>
                    <p className="mt-2 text-xs text-text-secondary leading-relaxed">
                      Creates Jira tracking issues specifically for automatically escalated critical threats.
                      User-requested reviews are kept strictly internal to the ScamShield Trust & Safety portal.
                    </p>
                    <div className="mt-3 rounded-lg bg-card p-3 border border-border-light text-xs font-mono text-text-muted">
                      JIRA_PROJECT_KEY=SCAM · JIRA_ENABLED=true
                    </div>
                  </div>

                  {/* Groq Card */}
                  <div className="rounded-xl border border-border-light bg-background p-5">
                    <div className="flex items-center justify-between">
                      <div className="flex items-center gap-2">
                        <span className="font-bold text-text-main">Groq Cloud AI (Llama-3.3)</span>
                        <span className="rounded bg-success/10 px-2 py-0.5 text-[10px] font-bold text-success">
                          Connected
                        </span>
                      </div>
                    </div>
                    <p className="mt-2 text-xs text-text-secondary leading-relaxed">
                      Ultra-low latency LLM inference provider powering explainable threat signals and user-facing protective guidance.
                    </p>
                  </div>
                </div>

                <div className="mt-5 rounded-xl border border-warning/30 bg-warning/5 p-4 text-xs text-text-secondary">
                  <div className="flex items-start gap-2.5">
                    <Key size={16} className="text-warning mt-0.5 shrink-0" />
                    <div>
                      <strong className="text-text-main font-semibold">Security Policy on API Secrets:</strong>
                      <p className="mt-0.5">
                        Third-party API keys (e.g. <code>GROQ_API_KEY</code>, <code>JIRA_API_TOKEN</code>) are loaded strictly from the server-side environment (<code>backend/.env</code>).
                        They are never transmitted to or editable from the browser client to protect operational credentials.
                      </p>
                    </div>
                  </div>
                </div>
              </section>
            </div>
          )}

          {/* TAB 6: Retention & Compliance */}
          {activeTab === 'retention' && (
            <div className="space-y-6">
              <section className="rounded-2xl border border-border-light bg-card p-6 shadow-sm">
                <div className="mb-4 flex items-center justify-between border-b border-border-light pb-4">
                  <div className="flex items-center gap-2.5">
                    <span className="grid h-9 w-9 place-items-center rounded-lg bg-primary/10 text-primary">
                      <ScrollText size={20} />
                    </span>
                    <div>
                      <h2 className="text-lg font-bold text-text-main">Data Retention & PII Scrubbing</h2>
                      <p className="text-xs text-text-muted">Compliance lifecycles, user privacy, and automated redaction</p>
                    </div>
                  </div>
                </div>

                <div className="grid grid-cols-1 gap-4 @content-sm:grid-cols-2">
                  <div className="rounded-xl border border-border-light bg-background p-4">
                    <span className="text-xs font-semibold text-text-muted">Analysis Records Retention</span>
                    <p className="mt-1 font-bold text-text-main">365 Days</p>
                    <p className="mt-1 text-xs text-text-muted">Historical content analyses are archived after 1 year unless flagged.</p>
                  </div>

                  <div className="rounded-xl border border-border-light bg-background p-4">
                    <span className="text-xs font-semibold text-text-muted">Audit Log Retention</span>
                    <p className="mt-1 font-bold text-text-main">90 Days (Immutable)</p>
                    <p className="mt-1 text-xs text-text-muted">Administrative actions are preserved for forensic review.</p>
                  </div>

                  <div className="rounded-xl border border-border-light bg-background p-4">
                    <span className="text-xs font-semibold text-text-muted">Automated PII Scrubbing</span>
                    <p className="mt-1 font-bold text-text-main">Enabled (Pre-Embedding)</p>
                    <p className="mt-1 text-xs text-text-muted">Phone numbers, credit card numbers, and SSNs are masked prior to vectorization.</p>
                  </div>

                  <div className="rounded-xl border border-border-light bg-background p-4">
                    <span className="text-xs font-semibold text-text-muted">Right to Deletion (GDPR)</span>
                    <p className="mt-1 font-bold text-text-main">Cascade Deletion Supported</p>
                    <p className="mt-1 text-xs text-text-muted">Deactivating or removing an account purges associated telemetry.</p>
                  </div>
                </div>
              </section>
            </div>
          )}

          {/* TAB 7: Appearance & Preferences */}
          {activeTab === 'appearance' && (
            <div className="space-y-6">
              <section className="rounded-2xl border border-border-light bg-card p-6 shadow-sm">
                <div className="mb-4 flex items-center justify-between border-b border-border-light pb-4">
                  <div className="flex items-center gap-2.5">
                    <span className="grid h-9 w-9 place-items-center rounded-lg bg-primary/10 text-primary">
                      <Palette size={20} />
                    </span>
                    <div>
                      <h2 className="text-lg font-bold text-text-main">Portal Appearance & Display Preferences</h2>
                      <p className="text-xs text-text-muted">Theme styling, default dashboard windows, and density preferences</p>
                    </div>
                  </div>
                </div>

                <div className="space-y-5">
                  {/* Theme Switcher */}
                  <div className="flex items-center justify-between rounded-xl border border-border-light bg-background p-4">
                    <div>
                      <p className="font-bold text-text-main text-sm">Theme Mode</p>
                      <p className="text-xs text-text-muted">Current theme: <span className="font-semibold text-primary capitalize">{theme}</span></p>
                    </div>
                    <button
                      type="button"
                      onClick={toggleTheme}
                      className="rounded-lg border border-border-light bg-card px-4 py-2 text-xs font-bold text-text-main shadow-xs hover:bg-background transition-colors"
                    >
                      Toggle Light / Dark Mode
                    </button>
                  </div>

                  {/* Default Dashboard Days */}
                  <div className="flex items-center justify-between rounded-xl border border-border-light bg-background p-4">
                    <div>
                      <p className="font-bold text-text-main text-sm">Default Analytics Date Window</p>
                      <p className="text-xs text-text-muted">Pre-selects the telemetry window when loading the dashboard</p>
                    </div>
                    <select
                      value={defaultDays}
                      onChange={(e) => setDefaultDays(Number(e.target.value))}
                      className="rounded-lg border border-border-light bg-card px-3 py-1.5 text-xs font-semibold text-text-main"
                    >
                      <option value={7}>7 Days</option>
                      <option value={30}>30 Days</option>
                      <option value={90}>90 Days</option>
                    </select>
                  </div>

                  {/* Dense Mode */}
                  <div className="flex items-center justify-between rounded-xl border border-border-light bg-background p-4">
                    <div>
                      <p className="font-bold text-text-main text-sm">Compact / Dense Table Rows</p>
                      <p className="text-xs text-text-muted">Reduces table row padding in Analyses, Reviews, and Logs</p>
                    </div>
                    <input
                      type="checkbox"
                      checked={denseMode}
                      onChange={(e) => setDenseMode(e.target.checked)}
                      className="h-4 w-4 rounded border-border-light text-primary focus:ring-primary"
                    />
                  </div>

                  <div className="border-t border-border-light pt-4 flex justify-end">
                    <button
                      type="button"
                      onClick={handleSavePreferences}
                      className="rounded-lg bg-primary px-5 py-2.5 text-xs font-bold text-white shadow-sm hover:bg-primary-hover transition-colors"
                    >
                      Save Preferences
                    </button>
                  </div>
                </div>
              </section>
            </div>
          )}
        </div>
      </div>
    </div>
  );
}

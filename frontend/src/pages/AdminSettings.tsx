import { Database, Key, LockKeyhole, ScrollText, Settings, ShieldCheck } from 'lucide-react';
import AdminBackButton from '../components/AdminBackButton';

export default function AdminSettings() {
  return (
    <div className="mx-auto max-w-5xl space-y-6 pb-10">
      <header className="flex flex-wrap items-end justify-between gap-4">
        <div>
          <p className="text-xs font-semibold uppercase tracking-wider text-primary">Administration</p>
          <h1 className="mb-1 text-3xl font-bold text-text-main">System Settings</h1>
          <p className="text-text-muted">Configuration guidance and security information for administrators.</p>
        </div>
        <AdminBackButton to="/admin" label="Back to Dashboard" />
      </header>

      <section aria-label="System configuration guidance" className="grid gap-4 @content-sm:grid-cols-2">
        <article className="rounded-xl border border-border-light bg-card p-5 shadow-sm">
          <div className="flex items-start gap-3">
            <span className="grid h-10 w-10 shrink-0 place-items-center rounded-xl bg-primary/10 text-primary"><Database size={19} /></span>
            <div>
              <h2 className="font-bold text-text-main">Database and records</h2>
              <p className="mt-1 text-sm leading-relaxed text-text-secondary">User accounts, analyses, community reports, reviews, and knowledge entries are stored through the backend database. Schema changes are managed with Alembic migrations.</p>
            </div>
          </div>
        </article>
        <article className="rounded-xl border border-border-light bg-card p-5 shadow-sm">
          <div className="flex items-start gap-3">
            <span className="grid h-10 w-10 shrink-0 place-items-center rounded-xl bg-success/10 text-success"><LockKeyhole size={19} /></span>
            <div>
              <h2 className="font-bold text-text-main">Access and credentials</h2>
              <p className="mt-1 text-sm leading-relaxed text-text-secondary">Admin access is role-checked by the API. Integration credentials belong in the backend environment only; this page does not expose or store secrets in the browser.</p>
            </div>
          </div>
        </article>
        <article className="rounded-xl border border-border-light bg-card p-5 shadow-sm @content-sm:col-span-2">
          <div className="flex items-start gap-3">
            <span className="grid h-10 w-10 shrink-0 place-items-center rounded-xl bg-warning/10 text-warning"><ScrollText size={19} /></span>
            <div>
              <h2 className="font-bold text-text-main">Auditability</h2>
              <p className="mt-1 text-sm leading-relaxed text-text-secondary">Administrative actions such as account access changes and knowledge-base moderation are recorded in the audit log. Use the Audit Log navigation entry to inspect recorded events.</p>
            </div>
          </div>
        </article>
      </section>

      <section className="rounded-2xl border border-border-light bg-card p-6 shadow-sm">
        <div className="mb-5 flex items-center gap-2 border-b border-border-light pb-4">
          <Settings className="h-5 w-5 text-primary" />
          <h2 className="text-lg font-bold text-text-main">Jira Integration</h2>
        </div>

        <p className="mb-5 text-sm leading-relaxed text-text-secondary">
          Configure Jira on the backend to create tickets only for automatically escalated cases in the
          ScamShield project. User-requested reviews are not sent to Jira. The API token stays server-side.
        </p>

        <div className="rounded-xl border border-warning/30 bg-warning/5 p-4">
          <div className="flex items-start gap-3">
            <Key className="mt-0.5 h-5 w-5 shrink-0 text-warning" />
            <div>
              <h3 className="font-semibold text-text-main">Configuration is managed by the server</h3>
              <p className="mt-1 text-sm text-text-secondary">
                Set <code className="rounded bg-card px-1.5 py-0.5">JIRA_ENABLED=true</code>,
                {' '}<code className="rounded bg-card px-1.5 py-0.5">JIRA_URL</code>,
                {' '}<code className="rounded bg-card px-1.5 py-0.5">JIRA_EMAIL</code>,
                {' '}<code className="rounded bg-card px-1.5 py-0.5">JIRA_API_TOKEN</code> and
                {' '}<code className="rounded bg-card px-1.5 py-0.5">JIRA_PROJECT_KEY</code> in
                <code className="rounded bg-card px-1.5 py-0.5">backend/.env</code>. Use only the
                dedicated ScamShield Jira project key, then restart the
                backend service. Do not paste API tokens into chat or source control.
              </p>
            </div>
          </div>
        </div>

        <div className="mt-5 flex items-center gap-2 text-xs text-text-muted">
          <ShieldCheck className="h-4 w-4 text-success" />
          Integration secrets are not editable or exposed in the browser.
        </div>
      </section>
    </div>
  );
}

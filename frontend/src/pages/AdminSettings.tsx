import { Key, Settings, ShieldCheck } from 'lucide-react';

export default function AdminSettings() {
  return (
    <div className="mx-auto max-w-4xl space-y-6 pb-10">
      <header>
        <h1 className="mb-1 text-3xl font-bold text-text-main">System Settings</h1>
        <p className="text-text-muted">View the configuration required for external integrations.</p>
      </header>

      <section className="rounded-2xl border border-border-light bg-card p-6 shadow-sm">
        <div className="mb-5 flex items-center gap-2 border-b border-border-light pb-4">
          <Settings className="h-5 w-5 text-primary" />
          <h2 className="text-lg font-bold text-text-main">Jira Integration</h2>
        </div>

        <p className="mb-5 text-sm leading-relaxed text-text-secondary">
          Configure Jira on the backend to create tickets for human-review cases. The API token is kept
          server-side and is never displayed in this portal.
        </p>

        <div className="rounded-xl border border-warning/30 bg-warning/5 p-4">
          <div className="flex items-start gap-3">
            <Key className="mt-0.5 h-5 w-5 shrink-0 text-warning" />
            <div>
              <h3 className="font-semibold text-text-main">Configuration is managed by the server</h3>
              <p className="mt-1 text-sm text-text-secondary">
                Set <code className="rounded bg-card px-1.5 py-0.5">JIRA_ENABLED=true</code>,
                {' '}<code className="rounded bg-card px-1.5 py-0.5">JIRA_BASE_URL</code>,
                {' '}<code className="rounded bg-card px-1.5 py-0.5">JIRA_EMAIL</code>,
                {' '}<code className="rounded bg-card px-1.5 py-0.5">JIRA_API_TOKEN</code> and
                {' '}<code className="rounded bg-card px-1.5 py-0.5">JIRA_PROJECT_KEY</code> in
                the backend environment, then restart the backend service.
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

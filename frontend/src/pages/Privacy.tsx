import { ShieldCheck, ArrowLeft } from 'lucide-react';
import { Link } from 'react-router-dom';

export default function Privacy() {
  return (
    <div className="min-h-screen bg-[#f4f7fb] font-sans">
      <header className="bg-background p-6 shadow-md flex items-center justify-between">
        <Link to="/" className="flex items-center space-x-2 group">
          <ShieldCheck className="w-8 h-8 text-primary group-hover:text-primary transition" />
          <span className="text-xl font-bold text-white tracking-wider">ScamShield</span>
        </Link>
        <Link to="/signup" className="text-text-muted hover:text-white flex items-center space-x-2 text-sm transition">
          <ArrowLeft className="w-4 h-4" />
          <span>Back</span>
        </Link>
      </header>

      <main className="max-w-4xl mx-auto py-12 px-6">
        <div className="bg-card rounded-2xl shadow-sm border border-border-light p-8 md:p-12">
          <h1 className="text-3xl font-bold text-text-main mb-6">Privacy Policy</h1>
          <p className="text-text-muted mb-8">Last updated: September 2026</p>
          
          <div className="space-y-6 text-text-secondary leading-relaxed">
            <section>
              <h2 className="text-xl font-bold text-text-main mb-3">1. Information Collection</h2>
              <p>We collect information you provide directly to us when you create an account, submit content for analysis, or communicate with us. This may include your name, email address, and the specific text, documents, or media you submit for scam detection.</p>
            </section>
            
            <section>
              <h2 className="text-xl font-bold text-text-main mb-3">2. Use of Information</h2>
              <p>We use the information we collect to:</p>
              <ul className="list-disc pl-5 mt-2 space-y-1">
                <li>Provide, maintain, and improve our services.</li>
                <li>Process your content submissions through our AI analysis engines.</li>
                <li>Send you technical notices, updates, security alerts, and support messages.</li>
              </ul>
            </section>

            <section>
              <h2 className="text-xl font-bold text-text-main mb-3">3. Data Security</h2>
              <p>We implement reasonable security measures to protect the security of your personal information and analysis history. However, despite our efforts, no security measures are completely impenetrable.</p>
            </section>

            <section>
              <h2 className="text-xl font-bold text-text-main mb-3">4. Data Retention</h2>
              <p>Your analysis history is stored securely in our database to provide you with historical insights. You may request deletion of your account and associated data by contacting support.</p>
            </section>
          </div>
        </div>
      </main>
    </div>
  );
}

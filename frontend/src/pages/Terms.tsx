import { ShieldCheck, ArrowLeft } from 'lucide-react';
import { Link } from 'react-router-dom';

export default function Terms() {
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
          <h1 className="text-3xl font-bold text-text-main mb-6">Terms of Service</h1>
          <p className="text-text-muted mb-8">Last updated: September 2026</p>
          
          <div className="space-y-6 text-text-secondary leading-relaxed">
            <section>
              <h2 className="text-xl font-bold text-text-main mb-3">1. Acceptance of Terms</h2>
              <p>By accessing and using ScamShield, you accept and agree to be bound by the terms and provision of this agreement. In addition, when using these particular services, you shall be subject to any posted guidelines or rules applicable to such services.</p>
            </section>
            
            <section>
              <h2 className="text-xl font-bold text-text-main mb-3">2. Description of Service</h2>
              <p>ScamShield provides users with AI-driven analysis tools for detecting potential scams and fraudulent content. The analysis provided is for informational purposes only and does not constitute legal or financial advice.</p>
            </section>

            <section>
              <h2 className="text-xl font-bold text-text-main mb-3">3. User Conduct</h2>
              <p>You agree to not use the service to:</p>
              <ul className="list-disc pl-5 mt-2 space-y-1">
                <li>Upload or transmit any content that you do not have a right to transmit.</li>
                <li>Interfere with or disrupt the service or servers connected to the service.</li>
                <li>Intentionally or unintentionally violate any applicable local, state, national, or international law.</li>
              </ul>
            </section>

            <section>
              <h2 className="text-xl font-bold text-text-main mb-3">4. Disclaimer of Warranties</h2>
              <p>Your use of the service is at your sole risk. The service is provided on an "as is" and "as available" basis. ScamShield expressly disclaims all warranties of any kind, whether express or implied.</p>
            </section>
          </div>
        </div>
      </main>
    </div>
  );
}

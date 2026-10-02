import AuthPage from '../components/AuthPage';

export default function Login({ adminOnly = false }: { adminOnly?: boolean }) {
  return <AuthPage initialMode="login" adminOnly={adminOnly} />;
}

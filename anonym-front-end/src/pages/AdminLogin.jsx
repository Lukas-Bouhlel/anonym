import { useState } from 'react';
import { Navigate } from 'react-router-dom';
import Login from '../components/Access/Login/Login';
import PasswordReset from '../components/Access/Reset/PasswordReset';
import twitterLogo from '../assets/images/icons/twitter.svg';
import { useUser } from '../context/UserContext';

const AdminLogin = () => {
  const [statusForm, setStatusForm] = useState('login');
  const { user } = useUser();

  if (user) {
    return <Navigate to="/admin" replace />;
  }

  return (
    <section className="admin-login-page">
      <div className="admin-login-card">
        <div className="admin-login-form">
          {statusForm === 'login' ? (
            <Login setStatusForm={setStatusForm} />
          ) : (
            <PasswordReset setStatusForm={setStatusForm} />
          )}
        </div>
        <aside className="admin-login-presentation">
          <h1>Anonym Admin</h1>
          <p>
            Espace prive reserve aux admins du projet Anonym. Le reseau
            social public reste disponible via nos canaux officiels.
          </p>
          <a href="https://x.com/Anonym_Tech" target="_blank" rel="noopener noreferrer" className="admin-login-social-link">
            <img src={twitterLogo} alt="" />
            <span>Rejoindre le reseau social</span>
          </a>
        </aside>
      </div>
    </section>
  );
};

export default AdminLogin;

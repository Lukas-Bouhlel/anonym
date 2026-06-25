import { BrowserRouter, Routes, Route } from "react-router-dom";
import { ApiProvider } from "../context/ApiContext";
import { UserProvider } from '../context/UserContext.jsx';
import { PopupProvider } from "../context/PopupContext.jsx";
import PrivateRoute from '../router/PrivateRoute';
import Home from "../pages/Home";
import Discover from "../pages/Discover";
import LegalNotices from "../pages/Legal-notices";
import Support from "../pages/Support";
import PrivacyPolicy from "../pages/Privacy-policy";
import TermsConditions from "../pages/TermsConditions";
import Layout from "../components/layout/Layout.jsx";
import Profile from "../pages/Profile.jsx";
import Reset from "../components/Access/Reset/Reset.jsx";
import Admin from "../pages/Admin.jsx";
import AdminLogin from "../pages/AdminLogin.jsx";

const ADMIN_LOGIN_PATH = "/admin-portal-a7f49c2e";

/**
 * Composant Router qui gère les routes de l'application avec `react-router-dom`.
 * Utilise des contextes pour gérer l'authentification, les utilisateurs, les API et les popups.
 * Définit des routes publiques et privées. Les routes privées sont protégées par le composant `PrivateRoute`.
 * 
 * @component
 */
const Router = () => {
  return (
    <BrowserRouter future={{ v7_relativeSplatPath: true, v7_startTransition: true }}>
      <ApiProvider>
        <PopupProvider>
          <UserProvider>
              <Layout>
                <Routes>
                  {/* Routes publique */} 
                  <Route path="/" element={<Home />} />
                  <Route path="/discover" element={<Discover />} />
                  <Route path="/support" element={<Support />} />
                  <Route path="/legal-notices" element={<LegalNotices />} />
                  <Route path="/privacy-policy" element={<PrivacyPolicy />} />
                  <Route path="/terms-conditions" element={<TermsConditions />} />
                  <Route path="/reset" element={<Reset />} />
                  <Route path={ADMIN_LOGIN_PATH} element={<AdminLogin />} />
                  {/* Routes privées */}
                  <Route path="/admin" element={<PrivateRoute allowedRoles={['ADMIN', 'SUPER_ADMIN']}><Admin/></PrivateRoute>} />
                  <Route path="/profile" element={<PrivateRoute allowedRoles={[]}><Profile /></PrivateRoute>} />
                  <Route path="*" element={<Home />} />
                </Routes>
              </Layout>
          </UserProvider>
        </PopupProvider>
      </ApiProvider>
    </BrowserRouter>
  );
};
export default Router;

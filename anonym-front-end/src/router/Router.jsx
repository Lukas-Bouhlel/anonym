import { BrowserRouter, Routes, Route } from "react-router-dom";
import { AuthProvider } from "../context/AuthContext";
import { ApiProvider } from "../context/ApiContext";
import { UserProvider } from '../context/UserContext.jsx';
import PrivateRoute from '../router/PrivateRoute';
import Home from "../pages/Home";
import Discover from "../pages/Discover";
import LegalNotices from "../pages/Legal-notices";
import Reputation from "../pages/Reputation";
import Support from "../pages/Support";
import PrivacyPolicy from "../pages/Privacy-policy";
import TermsConditions from "../pages/TermsConditions";
import Layout from "../components/layout/Layout.jsx";
import App from "../pages/App";
import Profile from "../pages/Profile.jsx";
import Success from "../pages/Success.jsx";
import Reset from "../components/Access/Reset/Reset.jsx";
import Admin from "../pages/Admin.jsx";
import { PopupProvider } from "../context/PopupContext.jsx";

const Router = () => {
  return (
    <BrowserRouter>
      <ApiProvider>
        <PopupProvider>
          <AuthProvider>
            <UserProvider>
              <Layout>
                <Routes>
                  <Route path="/" element={<Home />} />
                  <Route path="/discover" element={<Discover />} />
                  <Route path="/reputation" element={<Reputation />} />
                  <Route path="/support" element={<Support />} />
                  <Route path="/legal-notices" element={<LegalNotices />} />
                  <Route path="/privacy-policy" element={<PrivacyPolicy />} />
                  <Route path="/terms-conditions" element={<TermsConditions />} />
                  <Route path="/reset" element={<Reset />} />
                  {/* Routes privées */}
                  <Route path="/admin" element={<PrivateRoute><Admin/></PrivateRoute>} />
                  <Route path="/profile" element={<PrivateRoute><Profile /></PrivateRoute>} />
                  <Route path="/app/success" element={<PrivateRoute><Success /></PrivateRoute>} />
                  <Route path="/app" element={<PrivateRoute><App /></PrivateRoute>} />
                </Routes>
              </Layout>
            </UserProvider>
          </AuthProvider>
        </PopupProvider>
      </ApiProvider>
    </BrowserRouter>
  );
};
export default Router;
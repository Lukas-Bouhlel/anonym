import { BrowserRouter, Routes, Route } from "react-router-dom";
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
import { AuthProvider } from "../context/AuthContext";
import { ApiProvider } from "../context/ApiContext";
import { UserProvider } from '../context/UserContext.jsx';
import PrivateRoute from '../router/PrivateRoute';

const Router = () => {
  return (
    <BrowserRouter>
      <ApiProvider>
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
                {/* Routes privées */}
                <Route path="/app" element={<PrivateRoute><App /></PrivateRoute>}></Route>
                <Route path="/profile" element={<PrivateRoute><Profile/></PrivateRoute>} />
              </Routes>
            </Layout>
          </UserProvider>
        </AuthProvider>
      </ApiProvider>
    </BrowserRouter>
  );
};
export default Router;

import { BrowserRouter, Routes, Route } from "react-router-dom";
import Navbar from "../components/layout/Navbar";
import Home from "../pages/Home";
import Discover from "../pages/Discover";
import LegalNotices from "../pages/Legal-notices";
import Reputation from "../pages/Reputation";
import Support from "../pages/Support";
import PrivacyPolicy from "../pages/Privacy-policy";
import TermsConditions from "../pages/TermsConditions";
import Footer from "../components/layout/Footer";
import { AuthProvider } from "../context/AuthContext";
import { ApiProvider } from "../context/ApiContext";

const Router = () => {
  return (
    <BrowserRouter>
      <ApiProvider>
        <AuthProvider>
          <Navbar/>
          <Routes>
            <Route path="/" element={<Home />}/>
            <Route path="/discover" element={<Discover />}/>
            <Route path="/reputation" element={<Reputation />}/>
            <Route path="/support" element={<Support />}/>
            <Route path="/legal-notices" element={<LegalNotices/>}/>
            <Route path="/privacy-policy" element={<PrivacyPolicy/>}/>
            <Route path="/terms-conditions" element={<TermsConditions/>}/>
          </Routes>
          <Footer/>
        </AuthProvider>
      </ApiProvider>
    </BrowserRouter>
  );
};
export default Router;

import { BrowserRouter, Routes, Route } from "react-router-dom";
import Navbar from "../components/layout/Navbar";
import Home from "../pages/Home";
import Discover from "../pages/Discover";
import { AuthProvider } from "../context/AuthContext";
import { ApiProvider } from "../context/ApiContext";

const Router = () => {
  return (
    <BrowserRouter>
      <ApiProvider>
        <AuthProvider>
          <Navbar />
          <Routes>
            <Route path="/" element={<Home />} />
            <Route path="/discover" element={<Discover />} />
          </Routes>
        </AuthProvider>
      </ApiProvider>
    </BrowserRouter>
  );
};
export default Router;

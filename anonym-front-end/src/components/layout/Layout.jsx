import { useLocation, Navigate } from "react-router-dom";
import Navbar from "./Navbar";
import Footer from "./Footer";
import Access from '../Access/Access';
import { useUser } from '../../context/UserContext';

// Composant qui conditionne l'affichage des éléments
const Layout = ({ children }) => {
  const privateRoutes = ["/app", "/profile", "/app/success"];
  const location = useLocation();
  const isPrivateRoute = privateRoutes.includes(location.pathname);
  const { user, isLoading } = useUser(); // Récupère l'utilisateur du contexte
  // Si l'utilisateur est connecté, on affiche la page protégée
  // Redirection vers /app si l'utilisateur est connecté et essaie d'accéder à une route publique
  //  if (user && !isPrivateRoute && !isLoading) {
  //   return <Navigate to="/app" />;
  // }
  // Gestion du chargement
  if (isLoading) {
    return <div>Chargement...</div>; // Affiche un message ou un spinner pendant le chargement
  }

  // Redirection vers / si l'utilisateur n'est pas connecté et essaie d'accéder à une route privée
  if (!user && isPrivateRoute && !isLoading) {
    return <Navigate to="/" />;
  }
  
  return (
    <>
      {/* Affiche Navbar et Access si ce n'est pas une route privée */}
      {!isPrivateRoute && <Navbar />}
      {!isPrivateRoute && <Access />}

      {/* Le contenu principal */}
      <div id="content">
        {children}
      </div>

      {/* Affiche Footer si ce n'est pas une route privée */}
      {!isPrivateRoute && <Footer />}
    </>
  );
};

export default Layout;
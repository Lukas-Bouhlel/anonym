import PropTypes from 'prop-types';
import { useLocation, Navigate } from "react-router-dom";
import Navbar from "./Navbar";
import Footer from "./Footer";
import { useUser } from '../../context/UserContext';

/**
 * Composant Layout qui conditionne l'affichage des éléments selon l'authentification de l'utilisateur.
 *
 * Ce composant gère la navigation entre les routes publiques et privées,
 * ainsi que les rôles d'utilisateur pour les routes d'administration.
 *
 * @component
 * @param {Object} props - Propriétés du composant.
 * @param {React.ReactNode} props.children - Le contenu à afficher dans le layout.
 * @example
 * return (
 *   <Layout>
 *     <YourComponent />
 *   </Layout>
 * )
 */
const Layout = ({ children }) => {
  const privateRoutes = ["/profile", "/admin"];
  const noChromeRoutes = ["/admin-portal-a7f49c2e"];
  const adminRoute = ['/admin'];
  const location = useLocation();
  const isPrivateRoute = privateRoutes.includes(location.pathname);
  const isNoChromeRoute = noChromeRoutes.includes(location.pathname);
  const isAdminRoute = adminRoute.includes(location.pathname);
  const { user, isLoading } = useUser(); // Récupère l'utilisateur du context

  // Gestion du chargement
  if (isLoading) {
    return <div>Chargement...</div>; // Affiche un message pendant le chargement des données
  }

  // Redirection vers la page home si l'utilisateur n'est pas connecté et essaie d'accéder à une route privée
  if (!user && isPrivateRoute && !isLoading) {
    return <Navigate to="/" />;
  }

  if(isAdminRoute) {
    const roles = ["ADMIN", "SUPER_ADMIN"];
    const hasRole = roles.includes(user.roles);
    if (!hasRole) {
      return <Navigate to="/" />;
    }
  }
  
  return (
    <>
      {/* Affiche Navbar et Access si ce n'est pas une route privée */}
      {!isPrivateRoute && !isNoChromeRoute && <Navbar />}

      {/* Le contenu principal */}
      <div id="content">
        {children}
      </div>

      {/* Affiche Footer si ce n'est pas une route privée */}
      {!isPrivateRoute && !isNoChromeRoute && <Footer />}
    </>
  );
};

Layout.propTypes = {
  children: PropTypes.node.isRequired,
};

export default Layout;

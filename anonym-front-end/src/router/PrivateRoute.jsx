import PropTypes from 'prop-types';
import { Navigate } from 'react-router-dom';
import { useUser } from '../context/UserContext';
import { SocketProvider } from "../context/SocketContext.jsx";

/**
 * Composant de route privée qui protège les pages nécessitant une authentification.
 * Si l'utilisateur est connecté, le contenu protégé est affiché.
 * Si l'utilisateur n'est pas connecté, il est redirigé vers la page d'accueil.
 * Pendant le chargement des informations de l'utilisateur, un indicateur de chargement est affiché.
 * 
 * @component
 * @param {Object} props - Les propriétés du composant.
 * @param {React.ReactNode} props.children - Le contenu protégé à afficher si l'utilisateur est connecté.
 * @returns {React.ReactNode} - Le contenu protégé ou une redirection vers la page d'accueil.
 */
const PrivateRoute = ({ children }) => {
  const { user, isLoading } = useUser(); // Récupère l'utilisateur

  // Gestion du chargement
  if (isLoading) {
    return <div>Chargement...</div>; 
  }

  // Si l'utilisateur n'est pas connecté après chargement, on redirige sur la home
  if (!isLoading && !user) {
    return <Navigate to="/" />;
  }

  // Si tout est bon, on affiche le contenu protégé
  return (
    <SocketProvider>
        {children}
    </SocketProvider>
  )
};

PrivateRoute.propTypes = {
  children: PropTypes.node.isRequired,
};

export default PrivateRoute;
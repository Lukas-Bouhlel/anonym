import React from 'react';
import { Navigate } from 'react-router-dom';
import { useUser } from '../context/UserContext'; // Utiliser le contexte utilisateur
import { SocketProvider } from "../context/SocketContext.jsx";

const PrivateRoute = ({ children }) => {
  const { user, isLoading } = useUser(); // Récupère l'utilisateur du contexte

  // Gestion du chargement
  if (isLoading) {
    return <div>Chargement...</div>; // Affiche un message ou un spinner pendant le chargement
  }

  // Si l'utilisateur n'est pas connecté après chargement, on redirige
  if (!isLoading && !user) {
    return <Navigate to="/" />;
  }

  // Si tout est bon, on affiche les enfants (le contenu protégé)
  return (
    <SocketProvider>
        {children}
    </SocketProvider>
  )
};

export default PrivateRoute;
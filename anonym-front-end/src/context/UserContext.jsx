import { createContext, useEffect, useState, useContext } from 'react';
import PropTypes from 'prop-types'; 
import axios from 'axios';
import { useApi } from '../context/ApiContext';
import { useQuery } from '@tanstack/react-query';
import { usePopup } from './PopupContext';

// Créez le context
const UserContext = createContext();

/**
 * Hook personnalisé pour accéder facilement au contexte utilisateur.
 * @returns {Object} - L'objet contenant les informations de l'utilisateur et les fonctions associées.
 */
export const useUser = () => useContext(UserContext);

/**
 * Fournisseur de contexte pour les utilisateurs.
 * Gère la connexion, l'inscription et la déconnexion des utilisateurs.
 *
 * @param {Object} props - Les propriétés du composant.
 * @param {React.ReactNode} props.children - Les enfants à rendre.
 * @returns {React.ReactElement} - Le fournisseur de contexte.
 */
export const UserProvider = ({ children }) => {
    const [user, setUser] = useState(null); // Stocke les informations de l'utilisateur connecté
    const { setTextPopup, setOpenPopup, setState } = usePopup();
    const { api_url } = useApi();
    /**
     * Fonction pour récupérer les informations de l'utilisateur.
     * @returns {Promise<Object>} - Les données de l'utilisateur.
     */
    const fetchUser = async () => {
          const response = await axios.get(`${api_url}/api/account`, {
            withCredentials: true,
          });
          setUser(response.data);
          return response.data;
      };

    // Utilisation de react-query pour la récupération de l'utilisateur
    const { data, error, isLoading, isError } = useQuery({
        queryKey: ['user'], // Clé de la requête pour le caching
        queryFn: fetchUser, // Fonction de récupération de l'utilisateur
        enabled: !user, // Active la requête si l'utilisateur n'est pas défini
        retry: false, // Désactive la tentative automatique en cas d'erreur
    });
    
    // Met à jour l'utilisateur lorsque les données sont récupérées
    useEffect(() => {
        if (data) {
            setUser(data); // Mise à jour de l'utilisateur avec les données de l'API
        }
    }, [data]);

    /**
     * Fonction pour mettre à jour les informations de l'utilisateur après login.
     * @param {Object} userData - Les données de l'utilisateur.
     */
    const login = (userData) => {
        setUser(userData);
    };

    /**
     * Fonction pour gérer l'inscription d'un nouvel utilisateur.
     * @param {Object} userData - Les données de l'utilisateur enregistré.
     */
    const registered = (userData) => {
        setUser(userData);
        setOpenPopup(true);
        setState('success');
        setTextPopup('Votre compte a été créé avec succès. Vous trouverez une confirmation envoyée par e-mail !');
    };

     /**
     * Fonction pour déconnecter l'utilisateur.
     * @returns {Promise<void>}
     */
    const logout = async () => {
        await axios.post(`${api_url}/api/auth/logout`, {}, { withCredentials: true });
        setUser(null);
    };

    return (
        <UserContext.Provider value={{ user, setUser, registered, login, logout, isLoading, isError, error }}>
            {children}
        </UserContext.Provider>
    );
};

UserProvider.propTypes = {
    children: PropTypes.node.isRequired,
};
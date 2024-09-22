import React, { createContext, useEffect, useState, useContext } from 'react';
import axios from 'axios';
import { useApi } from '../context/ApiContext';
import { useQuery } from '@tanstack/react-query';

// Créez le contexte
const UserContext = createContext();

// Hook personnalisé pour accéder facilement au contexte utilisateur
export const useUser = () => useContext(UserContext);

// Fournisseur de contexte utilisateur
export const UserProvider = ({ children }) => {
    const [user, setUser] = useState(null); // Stocke les informations de l'utilisateur connecté
    const { api_url } = useApi();

    const fetchUser = async () => {
        try {
          const response = await axios.get(`${api_url}/api/account`, {
            withCredentials: true,
          });
          setUser(response.data);
          return response.data;
        } catch (error) {
          console.error('Erreur lors de la récupération de l\'utilisateur:', error);
          return null;
        }
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

    // Fonction pour mettre à jour les informations de l'utilisateur
    const login = (userData) => {
        setUser(userData);
    };

    const registered = (userData) => {
        setUser(userData);
    };

    // Fonction pour déconnecter l'utilisateur
    const logout = async () => {
        try {
            await axios.post(`${api_url}/api/auth/logout`, {}, { withCredentials: true });
            setUser(null); // Supprime les informations de l'utilisateur du contexte
            console.log('déconnexion réussi')
        } catch (error) {
            console.error("Erreur lors de la déconnexion:", error);
        }
    };

    return (
        <UserContext.Provider value={{ user, setUser, registered, login, logout, isLoading, isError, error  }}>
            {children}
        </UserContext.Provider>
    );
};

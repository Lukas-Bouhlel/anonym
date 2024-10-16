import { createContext, useContext, useState } from "react";
import PropTypes from 'prop-types'; 

// Créez le context
const AuthContext = createContext();

/**
 * Hook personnalisé pour accéder facilement au contexte d'authentification.
 * @returns {Object} - L'objet contenant l'état et les fonctions d'authentification.
 */
export const useAuth = () => { return useContext(AuthContext); };

/**
 * Fournisseur de contexte pour l'authentification.
 * Il enveloppe l'application et fournit l'état d'ouverture du formulaire d'accès.
 *
 * @param {Object} props - Les propriétés du composant.
 * @param {React.ReactNode} props.children - Les enfants à rendre.
 * @returns {React.ReactElement} - Le fournisseur de contexte.
 */
export const AuthProvider = ({ children }) => {
    const [isAnonymOpen, setIsAnonymOpen] = useState(false);// Status du formulaire

     /**
     * Fonction pour ouvrir le formulaire d'accès.
     */
    const AnonymIsOpen = () => {
        setIsAnonymOpen(true);
    };

    /**
     * Fonction pour fermer le formulaire d'accès.
     */
    const AnonymIsClose = () => {
        setIsAnonymOpen(false);
    };

    return (
        <AuthContext.Provider value={{isAnonymOpen, AnonymIsOpen, AnonymIsClose }}>
            { children }
        </AuthContext.Provider>
    );
};

AuthProvider.propTypes = {
    children: PropTypes.node.isRequired,
};
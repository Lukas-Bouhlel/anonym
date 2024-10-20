import { createContext, useContext } from "react";
import PropTypes from 'prop-types'; 

// Créez le context
const ApiContext = createContext();

/**
 * Hook personnalisé pour accéder facilement au contexte de l'API URL.
 * @returns {Object} - L'objet contenant l'URL de l'API.
 */
export const useApi = () => useContext(ApiContext);

/**
 * Fournisseur de contexte pour l'API.
 * Il enveloppe l'application et fournit l'URL de l'API à ses enfants.
 *
 * @param {Object} props - Les propriétés du composant.
 * @param {React.ReactNode} props.children - Les enfants à rendre.
 * @returns {React.ReactElement} - Le fournisseur de contexte.
 */
export const ApiProvider = ({ children }) => {
    const api_url = import.meta.env.VITE_API_URL;

    return (
        <ApiContext.Provider value={{api_url}}>
            { children }
        </ApiContext.Provider>
    );
};

ApiProvider.propTypes = {
    children: PropTypes.node.isRequired,
};
import { createContext, useContext, useState } from "react";
import PropTypes from 'prop-types'; 

// Créez le context
const PopupContext = createContext();

/**
 * Hook personnalisé pour accéder facilement au contexte des popups.
 * @returns {Object} - L'objet contenant l'état et les fonctions des popups.
 */
export const usePopup = () => useContext(PopupContext);

/**
 * Fournisseur de contexte pour les popups.
 * Il enveloppe l'application et fournit l'état et les fonctions pour gérer les popups.
 *
 * @param {Object} props - Les propriétés du composant.
 * @param {React.ReactNode} props.children - Les enfants à rendre.
 * @returns {React.ReactElement} - Le fournisseur de contexte.
 */
export const PopupProvider = ({ children }) => {
    const [openPopup, setOpenPopup] = useState(false);
    const [textPopup, setTextPopup] = useState('');
    const [state, setState] = useState('');

    return (
        <PopupContext.Provider value={{ openPopup, setOpenPopup, textPopup, setTextPopup, state, setState }}>
            { children } 
        </PopupContext.Provider>
    );
};

PopupProvider.propTypes = {
    children: PropTypes.node.isRequired,
};
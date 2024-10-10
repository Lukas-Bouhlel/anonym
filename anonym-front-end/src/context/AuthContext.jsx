import { createContext, useContext, useState } from "react";
import PropTypes from 'prop-types'; 

const AuthContext = createContext();

export const useAuth = () => { return useContext(AuthContext); };

export const AuthProvider = ({ children }) => {
    const [isAnonymOpen, setIsAnonymOpen] = useState(false);

    const AnonymIsOpen = () => {
        setIsAnonymOpen(true);
    };

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
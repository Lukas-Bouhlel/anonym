import { createContext, useContext, useState } from "react";

const AuthContext = createContext();

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

export const useAuth = () => {
  return useContext(AuthContext);
};

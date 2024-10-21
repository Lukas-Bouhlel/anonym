import { createContext, useEffect, useState, useContext } from 'react';
import PropTypes from 'prop-types'; 
import { useApi } from './ApiContext';
import { io } from 'socket.io-client';

// Créez le context
const SocketContext = createContext();

/**
 * Hook personnalisé pour accéder facilement au contexte Socket.
 * @returns {Object} - L'objet contenant le socket.
 */
export const useSocket = () =>  useContext(SocketContext);

/**
 * Fournisseur de contexte pour les sockets.
 * Il gère la connexion au serveur via Socket.IO et fournit le socket aux composants enfants.
 *
 * @param {Object} props - Les propriétés du composant.
 * @param {React.ReactNode} props.children - Les enfants à rendre.
 * @returns {React.ReactElement} - Le fournisseur de contexte.
 */
export const SocketProvider = ({ children }) => {
    const { api_url } = useApi();// api url venant du context d'api
    const [socket, setSocket] = useState(null); // Stocke les informations du socket
    console.log(socket)
    useEffect(() => {
        const newSocket = io(api_url, {
            withCredentials: true
        });

        setSocket(newSocket);

        return () => {
            newSocket.disconnect();
        };
    }, [api_url]);

    return (
        <SocketContext.Provider value={{ socket }}>
            {children}
        </SocketContext.Provider>
    );
};

SocketProvider.propTypes = {
    children: PropTypes.node.isRequired,
};
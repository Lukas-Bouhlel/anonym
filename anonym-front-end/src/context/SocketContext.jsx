import { createContext, useEffect, useState, useContext } from 'react';
import PropTypes from 'prop-types'; 
import { useApi } from './ApiContext';
import { io } from 'socket.io-client';

const SocketContext = createContext();

export const useSocket = () =>  useContext(SocketContext);

export const SocketProvider = ({ children }) => {
    const { api_url } = useApi();
    const [socket, setSocket] = useState(null);

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
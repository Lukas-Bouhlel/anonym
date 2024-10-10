import { createContext, useContext } from "react";
import PropTypes from 'prop-types'; 

const ApiContext = createContext();

export const useApi = () => useContext(ApiContext);

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
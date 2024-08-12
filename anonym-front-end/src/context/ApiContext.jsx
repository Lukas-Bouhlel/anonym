import { createContext, useContext } from "react";

const ApiContext = createContext();

export const ApiProvider = ({ children }) => {
    const api_url = import.meta.env.VITE_API_URL;

    return (
        <ApiContext.Provider value={{api_url}}>
            { children }
        </ApiContext.Provider>
    );
};

export const useApi = () => {
  return useContext(ApiContext);
};

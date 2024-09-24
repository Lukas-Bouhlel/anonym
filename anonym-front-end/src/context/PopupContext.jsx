import { createContext, useContext, useState } from "react";

const PopupContext = createContext();

export const usePopup = () => useContext(PopupContext);

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


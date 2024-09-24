import React, { useEffect, useState } from "react";

const Popup = ({ showPopup, setShowPopup, text, setTextPopup, state, setState }) => {
    const [popupClass, setPopupClass] = useState('hidden');

    // Utilisation de useEffect pour masquer la pop-up après 5 secondes
    useEffect(() => {
        if (showPopup) {
            setTimeout(() => {
                // Afficher la pop-up
                setPopupClass('active'); 
                const timer = setTimeout(() => {
                    setPopupClass('hidden'); // Active l'animation de sortie (repartir vers -50px)
                    setTimeout(() => {
                        setShowPopup(false)
                        setTextPopup(''); // Cache la pop-up après l'animation de sortie
                        setState('');
                    }, 500); // Correspond à la durée de l'animation CSS (0.5s)
                }, 5000); // La pop-up reste visible 5 secondes
    
                return () => clearTimeout(timer); // Nettoie le timer lorsque le composant est démonté
            }, 50);
        }
    }, [showPopup]);

    return (
        <div id="popup">
            {/* Affichage de la pop-up de confirmation */}
            {showPopup && (
                <div className={`popup-confirm-update ${popupClass}`}>
                    <p className={`popup-confirm-update-${state}`}>{text}</p>
                </div>
            )}
        </div>
    )
}

export default Popup;
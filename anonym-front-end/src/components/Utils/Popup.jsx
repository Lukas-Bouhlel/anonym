import { useEffect, useState } from "react";
import PropTypes from 'prop-types';

/**
 * Composant Popup qui affiche un message contextuel pour une durée déterminée.
 *
 * @param {Object} props - Les propriétés du composant.
 * @param {boolean} props.showPopup - Indique si la pop-up doit être affichée.
 * @param {function} props.setShowPopup - Fonction pour mettre à jour l'état d'affichage de la pop-up.
 * @param {string} props.text - Le texte à afficher dans la pop-up.
 * @param {function} props.setTextPopup - Fonction pour mettre à jour le texte de la pop-up.
 * @param {any} props.state - L'état pour déterminer le style ou le type de message de la pop-up.
 * @param {function} props.setState - Fonction pour mettre à jour l'état.
 * @returns {JSX.Element} - Le rendu du composant Popup.
 */
const Popup = ({ showPopup, setShowPopup, text, setTextPopup, state, setState }) => {
    const [popupClass, setPopupClass] = useState('hidden');

    // Utilisation de useEffect pour masquer la pop-up après 5 secondes
    useEffect(() => {
        if (showPopup) {
            setTimeout(() => {
                setPopupClass('active'); 
                const timer = setTimeout(() => {
                    setPopupClass('hidden');// Active l'animation de sortie (repartir vers -50px)
                    setTimeout(() => {
                        setShowPopup(false)
                        setTextPopup('');// Cache la pop-up après l'animation de sortie
                        setState('');
                    }, 500);// Correspond à la durée de l'animation CSS (0.5s)
                }, 5000);// La pop-up reste visible 5 secondes
                return () => clearTimeout(timer);// Nettoie le timer lorsque le composant est démonté
            }, 50);
        }
    }, [showPopup, setShowPopup, setTextPopup, setState]);

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

Popup.propTypes = {
    showPopup: PropTypes.bool, 
    setShowPopup: PropTypes.func,
    text: PropTypes.string, 
    setTextPopup: PropTypes.func, 
    state: PropTypes.any, 
    setState: PropTypes.func, 
};

export default Popup;
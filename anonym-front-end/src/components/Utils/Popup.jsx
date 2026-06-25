import { useEffect, useState } from "react";
import PropTypes from 'prop-types';

/**
 * Composant Popup qui affiche un message contextuel pour une duree determinee.
 *
 * @param {Object} props - Les proprietes du composant.
 * @param {boolean} props.showPopup - Indique si la pop-up doit etre affichee.
 * @param {function} props.setShowPopup - Fonction pour mettre a jour l'etat d'affichage de la pop-up.
 * @param {string} props.text - Le texte a afficher dans la pop-up.
 * @param {function} props.setTextPopup - Fonction pour mettre a jour le texte de la pop-up.
 * @param {any} props.state - Etat pour determiner le style ou le type de message de la pop-up.
 * @param {function} props.setState - Fonction pour mettre a jour l'etat.
 * @returns {JSX.Element} - Le rendu du composant Popup.
 */
const Popup = ({ showPopup, setShowPopup, text, setTextPopup, state, setState }) => {
    const [popupClass, setPopupClass] = useState('hidden');

    // Masquer la pop-up automatiquement apres un delai.
    useEffect(() => {
        if (!showPopup) {
            return;
        }

        const enterTimeout = setTimeout(() => {
            setPopupClass('active');
        }, 50);

        const hideTimeout = setTimeout(() => {
            setPopupClass('hidden');
        }, 5050);

        const closeTimeout = setTimeout(() => {
            if (typeof setShowPopup === 'function') setShowPopup(false);
            if (typeof setTextPopup === 'function') setTextPopup('');
            if (typeof setState === 'function') setState('');
        }, 5550);

        return () => {
            clearTimeout(enterTimeout);
            clearTimeout(hideTimeout);
            clearTimeout(closeTimeout);
        };
    }, [showPopup, setShowPopup, setTextPopup, setState]);

    return (
        <div id="popup">
            {showPopup && (
                <div className={`popup-confirm-update ${popupClass}`}>
                    <p className={`popup-confirm-update-${state}`}>{text}</p>
                </div>
            )}
        </div>
    );
};

Popup.propTypes = {
    showPopup: PropTypes.bool,
    setShowPopup: PropTypes.func,
    text: PropTypes.string,
    setTextPopup: PropTypes.func,
    state: PropTypes.any,
    setState: PropTypes.func,
};

export default Popup;

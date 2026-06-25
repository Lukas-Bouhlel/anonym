import { useState } from "react";
import { Link } from "react-router-dom";
import { FontAwesomeIcon } from '@fortawesome/react-fontawesome';
import {useApi} from '../../context/ApiContext';
import { faGlobe, faBars, faInfo, faUserGear } from '@fortawesome/free-solid-svg-icons';
import logo from '../../assets/images/logos/anonym-logo-white.svg';

/**
 * Composant Sidebar affichant un menu latéral pour la navigation.
 * Permet de naviguer vers différentes sections de l'application et d'accéder à la documentation de l'API.
 * 
 * @returns {JSX.Element} Le composant Sidebar.
 */
const Sidebar = () => {
    const [isOpen, setIsOpen] = useState(true);
    const {api_url} = useApi();// Utilise le contexte pour obtenir l'URL de l'API

    /**
     * Gère l'ouverture et la fermeture de la barre latérale.
     */
    const toggleSidebar = () => {
        setIsOpen(!isOpen);
    };

    /**
     * Ouvre la documentation de l'API dans un nouvel onglet.
     * @param {Event} event - L'événement de clic sur le lien de la documentation.
     */
    const handleLinkClick = (event) => {
        event.preventDefault();
        window.open(api_url + '/api/admin/api-docs', '_blank', 'noopener,noreferrer');
    };

    return (
        <>
         <div className={`sidebar ${isOpen ? "open" : "closed"}`}>
                <div className={`content-toggle-btn-logo ${!isOpen && 'togglable'}`}>
                    <div className="toggle-btn" onClick={toggleSidebar}>
                        <FontAwesomeIcon icon={faBars} />
                    </div>
                    {isOpen && 
                        <Link to='/admin' className='logo-anonym'>
                            <img src={logo} alt='logo-anonym' />nonym
                        </Link>
                    }
                </div>
                <div className="sidebar-content">
                    <ul className="nav flex-column">
                        <li className="nav-item">
                            <Link to="/admin" className={`nav-link ${!isOpen && 'togglable'} active-link`}>
                                <FontAwesomeIcon icon={faGlobe} />
                                {isOpen && <span className="ms-3">Dashboard</span>}
                            </Link>
                        </li>
                        <li className="nav-item">
                            <Link to="/profile" className={`nav-link ${!isOpen && 'togglable'}`}>
                                <FontAwesomeIcon icon={faUserGear} />
                                {isOpen && <span className="ms-3">Paramètres utilisateur</span>}
                            </Link>
                        </li>
                        <li className="nav-item">
                            <Link onClick={handleLinkClick} className={`nav-link ${!isOpen && 'togglable'}`}>
                                <FontAwesomeIcon icon={faInfo} />
                                {isOpen && <span className="ms-3">Api</span>}
                            </Link>
                        </li>
                    </ul>
                </div>
            </div>
        </>
    )
}

export default Sidebar;

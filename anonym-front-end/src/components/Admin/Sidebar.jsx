import { useState } from "react";
import { Link } from "react-router-dom";
import { FontAwesomeIcon } from '@fortawesome/react-fontawesome';
import {useApi} from '../../context/ApiContext';
import { faGlobe, faChartLine, faBars, faInfo } from '@fortawesome/free-solid-svg-icons';
import logo from '../../assets/images/logos/anonym-logo-white.svg';

const Sidebar = () => {
    const [isOpen, setIsOpen] = useState(true);  // State to track sidebar open/close
    const {api_url} = useApi();

    const toggleSidebar = () => {
        setIsOpen(!isOpen);  // Toggle the sidebar state
    };

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
                        <Link to='/app' className='logo-anonym'>
                            <img src={logo} alt='logo-anonym' />nonym
                        </Link>
                    }
                </div>
                <div className="sidebar-content">
                    <ul className="nav flex-column">
                        <li className="nav-item">
                            <Link  className={`nav-link ${!isOpen && 'togglable'} active-link`}>
                                <FontAwesomeIcon icon={faGlobe} />
                                {isOpen && <span className="ms-3">Dashboard</span>}
                            </Link>
                        </li>
                        <li className="nav-item">
                            <Link onClick={handleLinkClick} className={`nav-link ${!isOpen && 'togglable'}`}>
                                <FontAwesomeIcon icon={faInfo} />
                                {isOpen && <span className="ms-3">Api</span>}
                            </Link>
                        </li>
                        <li className="nav-item">
                            <Link  className={`nav-link ${!isOpen && 'togglable'}`}>
                                <FontAwesomeIcon icon={faChartLine} />
                                {isOpen && <span className="ms-3">Analyse</span>}
                            </Link>
                        </li>
                    </ul>
                </div>
            </div>
        </>
    )
}

export default Sidebar;
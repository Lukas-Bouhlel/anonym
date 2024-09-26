import React, { useState } from "react";
import { Link } from "react-router-dom";
import { FontAwesomeIcon } from '@fortawesome/react-fontawesome';
import { faUser, faShop, faBars } from '@fortawesome/free-solid-svg-icons';
import logo from '../../assets/images/logos/anonym-logo-white.svg';

const Sidebar = ({ }) => {
    const [isOpen, setIsOpen] = useState(true);  // State to track sidebar open/close

    const toggleSidebar = () => {
        setIsOpen(!isOpen);  // Toggle the sidebar state
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
                            <Link to="/admin/friends" className={`nav-link ${!isOpen && 'togglable'}`}>
                                <FontAwesomeIcon icon={faUser} />
                                {isOpen && <span className="ms-3">Admin Dashboard</span>}
                            </Link>
                        </li>
                        <li className="nav-item">
                            <Link to="/admin/friends" className={`nav-link ${!isOpen && 'togglable'}`}>
                                <FontAwesomeIcon icon={faUser} />
                                {isOpen && <span className="ms-3">Support</span>}
                            </Link>
                        </li>
                        <li className="nav-item">
                            <Link to="/admin/shop" className={`nav-link ${!isOpen && 'togglable'}`}>
                                <FontAwesomeIcon icon={faShop} />
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
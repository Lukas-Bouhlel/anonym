import React, { useState, useEffect } from 'react';
import { useLocation, useNavigate } from 'react-router-dom';
import { Link } from 'react-router-dom';
import { useAuth } from '../../context/AuthContext';
import { Squash as Hamburger } from 'hamburger-react';
import '../../assets/styles/navbar/navbar.scss';
import { useUser } from '../../context/UserContext';
import logo from '../../assets/images/logos/anonym-logo-white.svg';
import { usePopup } from '../../context/PopupContext';
import Popup from '../Utils/Popup';

const Navbar = () => {
    const { AnonymIsOpen } = useAuth();
    const { user } = useUser();
    const { openPopup, setOpenPopup, textPopup, setTextPopup, state, setState } = usePopup();
    const location = useLocation();
    const navigate = useNavigate();
    const [isOpenMenu, setIsOpenMenu] = useState();

    useEffect(() => {
        const contentContainer = document.getElementById('content');
        const logo = document.getElementById('navbar-mobile-logo');
        if (isOpenMenu === true) {
            contentContainer.classList.remove('animate-left');
            contentContainer.classList.add('animate-right');
            document.body.classList.add('body-animating');
            logo.classList.remove('animate-left');
            logo.classList.add('animate-right');
        } else if (isOpenMenu === false) {
            contentContainer.classList.remove('animate-right');
            contentContainer.classList.add('animate-left');
            logo.classList.remove('animate-right');
            logo.classList.add('animate-left');
            document.body.classList.remove('body-animating');
        }
    }, [isOpenMenu]);

    // Gérer le clic du bouton pour ouvrir Anonym ou rediriger vers /app
    const handleOpenAnonym = () => {
        if (user) {
            navigate('/app'); // Redirige vers /app si l'utilisateur est connecté
        } else {
            AnonymIsOpen(); // Appel de la fonction AnonymIsOpen si non connecté
        }
    };

    return (
        <>
            {openPopup && (
                <Popup showPopup={openPopup} setShowPopup={setOpenPopup} text={textPopup} setTextPopup={setTextPopup} state={state} setState={setState}/>
            )}
            <div id='navbar' className={`${location.pathname.substring(1)}`}>
                <Link to='/' className='navbar-items-links logo-anonym'>
                    <img src={logo} alt='logo-anonym' />nonym
                </Link>
                <div id='navbar-items'>
                    <Link to='/discover' className='navbar-items-links'>Découvrir</Link>
                    {/* <Link to='/reputation' className='navbar-items-links'>Reputation</Link> */}
                    <Link to='/support' className='navbar-items-links'>Support</Link>
                </div>
                <button className='navbar-items-links open-anonym' onClick={handleOpenAnonym}>Ouvrir Anonym</button>
            </div>
            <div id='navbar-mobile' className={`${location.pathname.substring(1)}`}>
                <Hamburger toggled={isOpenMenu} toggle={setIsOpenMenu} direction={'right'} color='#FFF9F4' size={23} />
            </div>
            <div id='navbar-mobile-logo'>
                <Link to='/' className='navbar-items-links logo-anonym'>
                    <img src={logo} alt='logo-anonym' />nonym
                </Link>
            </div>
            <div className={`side-menu${isOpenMenu ? ' open' : ''}`}>
                <nav>
                    <Link to='/discover' onClick={() => setIsOpenMenu(false)} className='side-menu-link'>Découvrir</Link>
                    {/* <Link to='/reputation' onClick={() => setIsOpenMenu(false)} className='side-menu-link'>Reputation</Link> */}
                    <Link to='/support' onClick={() => setIsOpenMenu(false)} className='side-menu-link'>Support</Link>
                    <span className='side-menu-link pe-auto' onClick={() => {setIsOpenMenu(false); handleOpenAnonym();}} >Ouvrir Anonym</span>
                </nav>
            </div>
        </>

    )
}
export default Navbar;
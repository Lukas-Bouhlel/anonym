import { useState, useEffect } from 'react';
import { useLocation } from 'react-router-dom';
import { Link } from 'react-router-dom';
import { Squash as Hamburger } from 'hamburger-react';
import '../../assets/styles/navbar/navbar.scss';
import logo from '../../assets/images/logos/anonym-logo-white.svg';
import { usePopup } from '../../context/PopupContext';
import Popup from '../Utils/Popup';

/**
 * Composant Navbar pour l'application.
 *
 * Ce composant rend la barre de navigation avec des liens vers différentes sections de l'application.
 * Il gère l'authentification de l'utilisateur et affiche une popup si nécessaire.
 *
 * @component
 * @example
 * return (
 *   <Navbar />
 * )
 */
const Navbar = () => {
    const { openPopup, setOpenPopup, textPopup, setTextPopup, state, setState } = usePopup();
    const location = useLocation();
    const [isOpenMenu, setIsOpenMenu] = useState();

    //Animation sidebar mobile
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
                    <Link to='/support' className='navbar-items-links'>Support</Link>
                </div>
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
                    <Link to='/support' onClick={() => setIsOpenMenu(false)} className='side-menu-link'>Support</Link>
                </nav>
            </div>
        </>

    )
}
export default Navbar;

import { useLocation  } from 'react-router-dom';
import { Link } from 'react-router-dom';
import { useAuth } from '../../context/AuthContext';
import '../../assets/styles/navbar/navbar.scss';
import logo from '../../assets/images/logos/anonym-logo-white.svg';

const Navbar = () => {
    const { AnonymIsOpen } = useAuth();
    const location = useLocation();

    return ( 
        <div id='navbar' className={`${location.pathname.substring(1)}`}>
            <Link to='/' className='navbar-items-links logo-anonym'>
                <img src={logo} alt='logo-anonym'/>nonym
            </Link>
            <div id='navbar-items'>
                <Link to='/discover' className='navbar-items-links'>Découvrir</Link>
                <Link to='/support' className='navbar-items-links'>Assistance</Link>
                <Link to='/donation' className='navbar-items-links'>Donation</Link>
            </div>
            <button className='navbar-items-links open-anonym' onClick={AnonymIsOpen}>Ouvrir Anonym</button>
        </div>
     )
}
export default Navbar;
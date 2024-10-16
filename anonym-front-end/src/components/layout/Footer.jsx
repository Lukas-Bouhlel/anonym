import { useLocation  } from 'react-router-dom';
import { Link } from 'react-router-dom';
import '../../assets/styles/footer/footer.scss';

/**
 * Composant Footer qui affiche des liens vers des pages importantes.
 *
 * Ce composant utilise le chemin de l'emplacement actuel pour appliquer
 * des styles conditionnels au footer.
 *
 * @component
 * @example
 * return (
 *   <Footer />
 * )
 */
const Footer = () => {
    const location = useLocation();

    return ( 
        <div id='footer' className={`${location.pathname.substring(1) ? location.pathname.substring(1) : 'home'}`}>
            <div id='footer-items'>
                <Link to='/legal-notices' className='footer-items-links'>Mentions légales</Link>
                <Link to='/privacy-policy' className='footer-items-links'>Confidentialité</Link>
                <Link to='/terms-conditions' className='footer-items-links'>CGV-CGU</Link>
            </div>
        </div>
     )
}
export default Footer;
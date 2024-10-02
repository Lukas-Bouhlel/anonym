import { useAuth } from '../context/AuthContext';
import logo from '../assets/images/logos/anonym-logo-white.svg';
import persona from '../assets/images/icons/persona.svg';
import tel from '../assets/images/icons/tel.svg';

const Discover = () => {
  const { AnonymIsOpen } = useAuth();

  return (
    <section className='page-discover'>
        <div className='page-discover-content'>
          <h1 className='page-reputation-title'>Découvrir</h1>
          <p>Anonym est idéal pour jouer à des jeux et se détendre entre amis.</p>
        </div>
        <div className='content-image-text'>
          <div className='content-image-text-paragraph'>
            <h2>Discute en toute sécurité</h2>
            <p>Des discussions fluides et sécurisées t'attendent. </p>
            <p>Profite d'une plateforme de confiance, épurée et agréable.</p>
            <p>N'hésite plus, rejoins-nous dès maintenant !</p>
          </div>
          <img className="icon-tel" src={tel} alt='icon-tel'/>
        </div>
        <div className='content-image-text'>
            <img src={persona} alt='icon-persona'/>
          <div className='content-image-text-paragraph'>
            <h2>Rends tes conversations plus amusantes</h2>
            <p>Utilise des émojis, autocollants et bien plus encore pour que ta personnalité transparaisse dans tes discussions.</p>
            <p>Définis ton avatar et ton propre profil pour apparaître dans le chat comme tu le souhaites.</p>
          </div>
        </div>
        <div className='page-discover-container'>
            <div className='page-discover-container-content'>
              <div className='page-discover-container-content-title'>
                <h1>RETROUVEZ-VOUS ENTRE AMIS SUR ANONYM</h1>
              </div>
              <button className='page-discover-container-content-open-anonym' onClick={AnonymIsOpen}>Ouvrez Anonym dans votre navigateur</button>
            </div>
        </div>
    </section>
  );
};

export default Discover;
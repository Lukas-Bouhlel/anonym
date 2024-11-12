import SphereSvg from "../assets/images/icons/sphere.svg?react";
import useSphereAnimation  from '../components/Animation/useSphereAnimation';
import { Helmet } from 'react-helmet-async';

/**
 * Composant Home qui représente la page d'accueil de l'application.
 * Il affiche une animation de sphère et des informations sur le réseau social.
 *
 * @component
 * @returns {React.ReactElement} - L'interface de la page d'accueil.
 */
const Home = () => {
  // Animation de la sphere pour la Home page
  useSphereAnimation ();

  return (
    <section className='page-home'>
      <Helmet>
        <meta name="description" content="Bienvenue sur ano-nym.fr ! Découvrez une plateforme innovante et conviviale. Profitez d'une expérience unique et rejoignez notre communauté dès maintenant." />
      </Helmet>
      <div className='page-home-icons'>
        <div className='sphere-animation'>
          <SphereSvg />
        </div>
      </div>
      <div className='page-home-content'>
        <h1 className='page-home-title'>Le réseau social...</h1>
        <p className='page-home-paragraph'>...qui protège tes données ainsi que celles de tes amis, un système de messagerie privée sans aucune rémanence, associé à un mécanisme de modération rigoureux pour les communautés, un lieu favorisant des discussions quotidiennes et des rencontres plus fréquentes.</p>
      </div>
    </section>
  );
};

export default Home;
import { useEffect } from 'react';
import SphereSvg from "../assets/images/icons/sphere.svg?react";
import Access from '../components/Access/Access';
import sphereAnimation from '../components/Animation/sphereAnimation';

const Home = () => {
  useEffect(() => {
    window.axeptioSettings = {
      clientId: "66c87e40923684660f8565de",
      cookiesVersion: "anonym-fr-EU",
      googleConsentMode: {
        default: {
          analytics_storage: "denied",
          ad_storage: "denied",
          ad_user_data: "denied",
          ad_personalization: "denied",
          wait_for_update: 500
        }
      }
    };

    // Charger le script Axeptio
    const script = document.createElement("script");
    script.async = true;
    script.src = "//static.axept.io/sdk.js";
    document.body.appendChild(script);

    // Cleanup pour retirer le script si nécessaire
    return () => {
      if (script) {
        document.body.removeChild(script);
      }
    };
  }, []);

  sphereAnimation();

  return (
    <section className='page-home'>
      <div className='page-home-icons'>
        <div className='sphere-animation'>
          <SphereSvg />
        </div>
      </div>
      <div className='page-home-content'>
        <Access/>
        <h1 className='page-home-title'>Le réseau social...</h1>
        <p className='page-home-paragraph'>...qui protège tes données ainsi que celles de tes amis, un système de messagerie privée sans aucune rémanence, associé à un mécanisme de modération rigoureux pour les communautés, un lieu favorisant des discussions quotidiennes et des rencontres plus fréquentes.</p>
      </div>
    </section>
  );
};

export default Home;
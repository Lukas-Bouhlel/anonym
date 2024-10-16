import { useEffect } from 'react';
import Router from './router/Router.jsx';
import './assets/styles/index.scss';
import './assets/styles/base.scss';
import 'bootstrap/dist/css/bootstrap.css';

/**
 * Composant App qui gère la logique principale de l'application et le routage.
 * Inclut un useEffect pour charger et initialiser le script de gestion de consentement Axeptio.
 * 
 * @component
 */
const App = () => {
  
  /**
   * Hook useEffect qui charge le script de gestion de consentement Axeptio lors du montage du composant.
   * Axeptio est utilisé pour gérer le consentement aux cookies de l'application.
   *
   * @function
   */
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
  
    /**
     * Crée dynamiquement et ajoute la balise de script Axeptio dans le body du document.
     * Gère les erreurs de chargement du script en les enregistrant dans la console.
     */
    const script = document.createElement("script");
    script.async = true;
    script.src = "https://static.axept.io/sdk.js";
    document.body.appendChild(script);
    window.axeptioSettings.debug = true;
    script.onerror = () => {
      console.error("Error loading Axeptio script");
    };
    return () => {
      document.body.removeChild(script);
    };
  }, []);

  /**
   * Rend le composant Router qui gère les routes de l'application.
   *
   * @returns {JSX.Element} Composant Router
   */
  return (
      <Router/>
  )
}
export default App
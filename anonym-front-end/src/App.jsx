import { useEffect } from 'react';
import Router from './router/Router.jsx';
import ReactGA from "react-ga4";
import './assets/styles/index.scss';
import './assets/styles/base.scss';
import 'bootstrap/dist/css/bootstrap.css';
import { Helmet } from 'react-helmet-async';


ReactGA.initialize("G-S6QML510VW", {
  gaOptions: {
    anonymizeIp: true,
  }
});

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
    // Paramètres de configuration Axeptio
    window.axeptioSettings = {
      clientId: "66c87e40923684660f8565de",
      cookiesVersion: "anonym-fr-EU",
      googleConsentMode: {
        default: {
          analytics_storage: "denied",
          ad_storage: "denied",
          ad_user_data: "denied",
          ad_personalization: "denied",
          wait_for_update: 500,
        },
      },
    };

    // Chargement dynamique du script Axeptio uniquement s'il n'est pas encore chargé
    if (!window.AxeptioSDKLoaded) {
      if (!document.querySelector('script[src="https://static.axept.io/sdk.js"]')) {
        const script = document.createElement("script");
        script.async = true;
        script.src = "https://static.axept.io/sdk.js";
        script.onload = () => {
          console.log("Axeptio SDK loaded successfully");
        };
        script.onerror = () => {
          console.error("Failed to load Axeptio SDK");
        };
        document.body.appendChild(script);
        window.AxeptioSDKLoaded = true;
      }
    }
  }, []);

  /**
   * Rend le composant Router qui gère les routes de l'application.
   *
   * @returns {JSX.Element} Composant Router
   */
  return (
    <>
      <Helmet>
        <meta name="google-site-verification" content="i5ppM2zWvLg1vGLBwXg5beniqRJvRjc-t8Iczu5UVSQ" />
      </Helmet>
      <Router/>
    </>
  )
}
export default App
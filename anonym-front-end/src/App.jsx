import { useEffect } from 'react';
import Router from './router/Router.jsx';
import * as ReactGAModule from "react-ga4";
import './assets/styles/index.scss';
import './assets/styles/base.scss';
import 'bootstrap/dist/css/bootstrap.css';
import { Helmet } from 'react-helmet-async';

const ReactGA =
  ReactGAModule?.default?.default ??
  ReactGAModule?.default ??
  ReactGAModule;

/**
 * Composant App qui gère la logique principale de l'application et le routage.
 * Inclut un useEffect pour charger et initialiser le script de gestion de consentement Axeptio.
 * 
 * @component
 */
const App = () => {
  useEffect(() => {
    if (!window.__ANONYM_GA_INITIALIZED__ && typeof ReactGA?.initialize === "function") {
      ReactGA.initialize("G-S6QML510VW", {
        gaOptions: {
          anonymizeIp: true,
        },
      });
      window.__ANONYM_GA_INITIALIZED__ = true;
    }
  }, []);

  useEffect(() => {
    if (!import.meta.env.PROD || window.__ANONYM_GTM_LOADED__) {
      return;
    }

    window.dataLayer = window.dataLayer || [];
    window.dataLayer.push({
      "gtm.start": new Date().getTime(),
      event: "gtm.js",
    });

    const gtmScript = document.createElement("script");
    gtmScript.async = true;
    gtmScript.src = "https://www.googletagmanager.com/gtm.js?id=GTM-N3KGJBCM";
    document.head.appendChild(gtmScript);

    window.__ANONYM_GTM_LOADED__ = true;
  }, []);

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
    // Le SDK Axeptio est chargé via GTM (index.html). Ne pas le charger ici.
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

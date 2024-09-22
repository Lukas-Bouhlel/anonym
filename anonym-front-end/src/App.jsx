import React, { useEffect } from 'react';
import Router from './router/Router.jsx';
import './assets/styles/index.scss';
import './assets/styles/base.scss';
import 'bootstrap/dist/css/bootstrap.css';

const App = () => {
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
    window.axeptioSettings.debug = true;
    script.onerror = () => {
      console.error("Error loading Axeptio script");
    };
    return () => {
      document.body.removeChild(script);
    };
  }, []);

  return (
      <Router/>
  )
}
export default App
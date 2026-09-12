import SphereSvg from "../assets/images/icons/sphere.svg?react";
import useSphereAnimation  from '../components/Animation/useSphereAnimation';
import { Helmet } from 'react-helmet-async';
import { useState } from 'react';
import { QRCodeSVG } from 'qrcode.react';
import googlePlayLogo from '../assets/images/icons/google_play_logo.png';

const ANDROID_APK_URL = 'https://www.ano-nym.fr/downloads/anonym.apk';
const GOOGLE_PLAY_LOGO_SRC = typeof googlePlayLogo === 'string'
  ? googlePlayLogo
  : googlePlayLogo?.default;

/**
 * Composant Home qui représente la page d'accueil de l'application.
 * Il affiche une animation de sphère et des informations sur le réseau social.
 *
 * @component
 * @returns {React.ReactElement} - L'interface de la page d'accueil.
 */
const Home = () => {
  const [isDownloadOpen, setIsDownloadOpen] = useState(false);

  // Animation de la sphere pour la Home page
  useSphereAnimation ();

  const closeDownload = () => setIsDownloadOpen(false);

  const handleBackdropClick = (event) => {
    if (event.target === event.currentTarget) {
      closeDownload();
    }
  };

  return (
    <section className='page-home'>
      <Helmet>
        <title>Anonym</title>
        <meta name="description" content="Bienvenue sur ano-nym.fr ! Découvrez une plateforme innovante et conviviale. Profitez d'une expérience unique et rejoignez notre communauté dès maintenant." />
        <link rel="canonical" href={`https://www.ano-nym.fr`} />
      </Helmet>
      <div className='page-home-icons'>
        <div className='sphere-animation'>
          <SphereSvg />
        </div>
      </div>
      <div className='page-home-content'>
        <h1 className='page-home-title'>Le réseau social...</h1>
        <p className='page-home-paragraph'>...qui protège tes données ainsi que celles de tes amis, un système de messagerie privée sans aucune rémanence, associé à un mécanisme de modération rigoureux pour les communautés, un lieu favorisant des discussions quotidiennes et des rencontres plus fréquentes.</p>
        <button
          className="page-home-download-trigger"
          type="button"
          onClick={() => setIsDownloadOpen(true)}
          aria-haspopup="dialog"
        >
          <img src={GOOGLE_PLAY_LOGO_SRC} alt="" aria-hidden="true" />
          Application Android
        </button>
      </div>

      {isDownloadOpen && (
        <div
          className="android-download-backdrop"
          role="presentation"
          onClick={handleBackdropClick}
          onKeyDown={(event) => event.key === 'Escape' && closeDownload()}
        >
          <div
            className="android-download-card"
            role="dialog"
            aria-modal="true"
            aria-labelledby="android-download-title"
          >
            <button
              className="android-download-close"
              type="button"
              onClick={closeDownload}
              aria-label="Fermer"
              autoFocus
            >
              ×
            </button>

            <div className="android-download-qr" aria-label="QR code de téléchargement Android">
              <QRCodeSVG
                value={ANDROID_APK_URL}
                size={168}
                level="H"
                marginSize={2}
                bgColor="#FFF9F4"
                fgColor="#252525"
                title="Télécharger l’APK Android officiel d’Anonym"
              />
            </div>

            <div className="android-download-content">
              <div className="android-download-platform">
                <img src={GOOGLE_PLAY_LOGO_SRC} alt="Logo Google Play" />
                <h2 id="android-download-title">Application&nbsp;Anonym</h2>
              </div>
              <p>
                Scannez le QR code avec votre téléphone Android pour télécharger et installer
                l’application.
              </p>
              <small>APK officiel signé · Android</small>
            </div>
          </div>
        </div>
      )}
    </section>
  );
};

export default Home;

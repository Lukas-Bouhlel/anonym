import { useEffect, useRef } from 'react';
import anime from 'animejs';

/**
 * Hook personnalisé pour gérer l'animation d'une sphère avec la bibliothèque anime.js.
 * 
 * @returns {Object} Référence aux animations en cours, permettant un accès direct si nécessaire.
 */
const useSphereAnimation  = () => {
  const animationsRef = useRef([]);
  
  useEffect(() => {
    const sphereEl = document.querySelector('.sphere-animation');
    const spherePathEls = sphereEl?.querySelectorAll('.sphere path') || [];
    const pathLength = spherePathEls.length;

    /**
     * Ajuste la taille de l'élément à son parent en fonction du padding.
     * 
     * @param {HTMLElement} el - L'élément à ajuster.
     * @param {number} [padding=0] - Le padding à appliquer lors de l'ajustement.
     */
    function fitElementToParent(el, padding = 0) {
      let timeout = null;
      // Fonction de redimensionnement
      function resize() {
        if (timeout) clearTimeout(timeout);
        anime.set(el, { scale: 1 });
        const pad = padding || 0;
        const parentEl = el.parentNode;
        const elOffsetWidth = el.offsetWidth - pad;
        const parentOffsetWidth = parentEl.offsetWidth;
        const ratio = parentOffsetWidth / elOffsetWidth;
        timeout = setTimeout(() => anime.set(el, { scale: ratio }), 10);
      }

      resize();
      // Retourne la fonction resize pour pouvoir l'utiliser dans le nettoyage
      return resize;
    }

    // Appel à fitElementToParent et récupération de la fonction resize
    const resizeListener = fitElementToParent(sphereEl);
    // Ajout de l'écouteur d'événements
    window.addEventListener('resize', resizeListener);

    const breathAnimation = anime({
      begin: () => {
        animationsRef.current = Array.from({ length: pathLength }, (_, i) =>
          anime({
            targets: spherePathEls[i],
            stroke: {
              value: ['#FFF9F4', 'rgba(80,80,80,.35)'],
              duration: 500,
            },
            translateX: [2, -4],
            translateY: [2, -4],
            easing: 'easeOutQuad',
            autoplay: false,
          })
        );
      },
      update: (ins) => {
        animationsRef.current.forEach((animation, i) => {
          const percent =
            (1 - Math.sin(i * 0.35 + 0.0022 * ins.currentTime)) / 2;
          animation.seek(animation.duration * percent);
        });
      },
      duration: Infinity,
      autoplay: false,
    });

    const introAnimation = anime.timeline({
      autoplay: false,
    }).add(
      {
        targets: spherePathEls,
        strokeDashoffset: {
          value: [anime.setDashoffset, 0],
          duration: 3900,
          easing: 'easeInOutCirc',
          delay: anime.stagger(190, { direction: 'reverse' }),
        },
        duration: 2000,
        delay: anime.stagger(60, { direction: 'reverse' }),
        easing: 'linear',
      },
      0
    );

    const shadowAnimation = anime({
      targets: '#sphereGradient',
      x1: '25%',
      x2: '25%',
      y1: '0%',
      y2: '75%',
      duration: 30000,
      easing: 'easeOutQuint',
      autoplay: false,
    }, 0);

    function init() {
      introAnimation.play();
      breathAnimation.play();
      shadowAnimation.play();
    }
    init();

    // Cleanup: remove the event listener on unmount
    return () => {
      window.removeEventListener('resize', resizeListener);
    };
  }, []); // Empty dependency array ensures effect runs only once on mount/unmount

  return animationsRef;
};

export default useSphereAnimation;
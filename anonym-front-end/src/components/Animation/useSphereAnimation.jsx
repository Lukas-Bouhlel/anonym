import { useEffect, useRef } from 'react';
import anime from 'animejs';

const useSphereAnimation  = () => {
  const animationsRef = useRef([]);

  useEffect(() => {
    const sphereEl = document.querySelector('.sphere-animation');
    const spherePathEls = sphereEl?.querySelectorAll('.sphere path') || [];
    const pathLength = spherePathEls.length;

    function fitElementToParent(el, padding) {
      let timeout = null;
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
      window.addEventListener('resize', resize);
    }

    fitElementToParent(sphereEl);

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

    return () => {
      window.removeEventListener('resize', fitElementToParent);
    };
  }, []);

  return animationsRef;
};

export default useSphereAnimation ;
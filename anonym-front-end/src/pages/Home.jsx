import SphereSvg from "../assets/images/icons/sphere.svg?react";
import Access from '../components/Access/Access';
import sphereAnimation from '../components/Animation/sphereAnimation';

const Home = () => {
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
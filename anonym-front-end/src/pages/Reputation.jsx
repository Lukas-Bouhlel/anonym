import React from "react";
import { Avatar, Badge } from 'rsuite';

const Reputation = () => {

  return (
    <section className='page-reputation'>
      <div className="page-reputation-content">
        <h1 className='page-reputation-title'>Réputation</h1>
        <p>Ici, chaque interaction compte !</p>
      </div>
      <div className='page-reputation-container'>
        <div className="page-reputation-container-paragraph">
        <p>💬 Votre participation ne passe pas inaperçue : </p>
          <p>chaque fois que vous interagissez, partagez, ou aidez les autres membres, vous bâtissez votre réputation sur notre plateforme. 🌟</p>
        </div>
        <div className="page-reputation-container-content">
          <div className="page-reputation-container-content-avatars">
            <div className="page-reputation-container-content-avatars-element">
              <Badge content="1" color="yellow">
                <Avatar color="yellow" bordered circle src="https://i.pravatar.cc/150?u=1" />
              </Badge>
              <p>Azelya</p>
              <p>1932</p>
            </div>
            {/* --rs-ring-shadow: #0088ff 0 0 0 4px; */}
            <div className="page-reputation-container-content-avatars-element">
              <Badge className="top2-badge" content="2">
                <Avatar className="top2" bordered circle src="https://i.pravatar.cc/150?u=1" />
              </Badge>
              <p>ReiJuzo</p>
              <p>1932</p>
            </div>
            <div className="page-reputation-container-content-avatars-element">
              <Badge content="3" color="orange">
                <Avatar color="orange" bordered circle src="https://i.pravatar.cc/150?u=1" />
              </Badge>
              <p>Nenmakuen</p>
              <p>1932</p>
            </div>
            <div className="page-reputation-container-content-avatars-element">
              <Badge className="reputation-color-badge" content="4" color="yellow">
                <Avatar className="reputation-color-avatar" bordered circle src="https://i.pravatar.cc/150?u=1" />
              </Badge>
              <p>Lukas</p>
              <p>1932</p>
            </div>
            <div className="page-reputation-container-content-avatars-element">
              <Badge className="reputation-color-badge" content="1" color="yellow">
                <Avatar className="reputation-color-avatar" bordered circle src="https://i.pravatar.cc/150?u=1" />
              </Badge>
              <p>ZeroEmiya</p>
              <p>1932</p>
            </div>
          </div>
          <span className="page-reputation-container-content-line"></span>
          <div className="page-reputation-container-content-avatars">
            <div className="page-reputation-container-content-avatars-element">
              <Badge className="reputation-color-badge" content="1" color="yellow">
                <Avatar className="reputation-color-avatar" bordered circle src="https://i.pravatar.cc/150?u=1" />
              </Badge>
              <p>Cobra</p>
              <p>1932</p>
            </div>
            <div className="page-reputation-container-content-avatars-element">
              <Badge className="reputation-color-badge" content="1" color="yellow">
                <Avatar className="reputation-color-avatar" bordered circle src="https://i.pravatar.cc/150?u=1" />
              </Badge>
              <p>Kenza</p>
              <p>1932</p>
            </div>
            <div className="page-reputation-container-content-avatars-element">
              <Badge className="reputation-color-badge" content="1" color="yellow">
                <Avatar className="reputation-color-avatar" circle bordered src="https://i.pravatar.cc/150?u=1" />
              </Badge>
              <p>Victor</p>
              <p>1932</p>
            </div>
            <div className="page-reputation-container-content-avatars-element">
              <Badge className="reputation-color-badge" content="1" color="yellow">
                <Avatar className="reputation-color-avatar" circle bordered src="https://i.pravatar.cc/150?u=1" />
              </Badge>
              <p>Toto</p>
              <p>1932</p>
            </div>
            <div className="page-reputation-container-content-avatars-element">
              <Badge className="reputation-color-badge" content="10" color="blue">
                <Avatar className="reputation-color-avatar" circle bordered src="https://i.pravatar.cc/150?u=1" />
              </Badge>
              <p>Test</p>
              <p>1932</p>
            </div>
          </div>
        </div>
      </div>
    </section>
  );
};

export default Reputation;
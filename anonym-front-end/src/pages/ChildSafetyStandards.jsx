import { Helmet } from 'react-helmet-async';
import { Link } from 'react-router-dom';

const ChildSafetyStandards = () => {
  return (
    <section className="page-child-safety-standards">
      <Helmet>
        <title>Normes liées à la sécurité des enfants - Anonym</title>
        <meta
          name="description"
          content="Normes d’Anonym relatives à la prévention de l’exploitation et des abus sexuels sur mineurs."
        />
        <link rel="canonical" href="https://www.ano-nym.fr/child-safety-standards" />
      </Helmet>

      <div className="page-child-safety-standards-content">
        <h1 className="page-child-safety-standards-title">
          Normes liées à la sécurité des enfants
        </h1>
        <p>Dernière mise à jour : 12/09/2026</p>

        <p>
          Anonym accorde une importance prioritaire à la sécurité des enfants. Les présentes
          normes décrivent nos règles et nos pratiques pour prévenir l’exploitation et les
          abus sexuels sur mineurs (EASM), y compris les contenus montrant des abus sexuels
          sur mineurs (CSAM).
        </p>

        <h2>1. Tolérance zéro</h2>
        <p>
          Anonym interdit strictement tout contenu ou comportement qui exploite, sexualise,
          met en danger ou sollicite des personnes mineures. Cette interdiction couvre
          notamment la création, la publication, l’envoi, la demande, la promotion ou la
          conservation de contenus d’abus sexuels sur mineurs, ainsi que le grooming, la
          sextorsion et toute autre forme d’exploitation sexuelle d’un enfant.
        </p>

        <h2>2. Signalement dans Anonym</h2>
        <p>
          Les utilisateurs peuvent signaler un profil ou un comportement directement depuis
          le profil concerné en sélectionnant « Signaler ». Ils peuvent également transmettre
          un signalement depuis l’écran d’assistance de l’application ou au moyen de notre{' '}
          <Link to="/support">formulaire d’assistance en ligne</Link>.
        </p>
        <p>
          Pour nous permettre d’agir rapidement, le signalement doit contenir autant
          d’informations utiles que possible, sans télécharger, copier ni partager davantage
          de contenu potentiellement illégal.
        </p>

        <h2>3. Traitement des signalements et mesures prises</h2>
        <p>
          Nous examinons les signalements liés à la sécurité des enfants et prenons les mesures
          appropriées. Selon la situation, celles-ci peuvent comprendre le retrait du contenu,
          la restriction ou la suppression du compte concerné, la conservation des informations
          requises par la loi et le signalement aux autorités compétentes.
        </p>
        <p>
          Toute violation avérée de ces normes peut entraîner la suspension ou la suppression
          définitive du compte, sans préavis lorsque la gravité de la situation le justifie.
        </p>

        <h2>4. Respect de la législation et coopération</h2>
        <p>
          Anonym respecte les lois applicables en matière de sécurité des enfants. Lorsque cela
          est requis, nous signalons les cas présumés d’exploitation ou d’abus sexuels sur
          mineurs aux autorités régionales ou nationales compétentes et coopérons avec leurs
          demandes légales.
        </p>

        <h2>5. Contact dédié</h2>
        <p>
          Pour toute question ou tout signalement concernant la sécurité des enfants et la
          conformité d’Anonym à ces normes, contactez notre interlocuteur désigné à l’adresse{' '}
          <a href="mailto:dpo.anonym@gmail.com">dpo.anonym@gmail.com</a>.
        </p>
        <p className="emergency-contact">
          Si un enfant est en danger immédiat, contactez sans attendre les services d’urgence
          ou les autorités compétentes de votre pays.
        </p>
      </div>
    </section>
  );
};

export default ChildSafetyStandards;

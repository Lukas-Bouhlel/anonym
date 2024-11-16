import { Helmet } from 'react-helmet-async';

const LegalNotices = () => {
  /**
   * Composant LegalNotices qui représente la page des mentions légales de l'application.
   * Il fournit des informations sur le propriétaire du site, l'hébergement, la propriété intellectuelle, 
   * la responsabilité, les données personnelles, et d'autres informations légales.
   *
   * @component
   * @returns {React.ReactElement} - L'interface de la page des mentions légales.
   */
  return (
    <section className='page-legal-notices'>
      <Helmet>
        <title>Mentions légales - Anonym</title>
        <meta name="description" content="Mentions légales" />
        <link rel="canonical" href={`https://www.ano-nym.fr/legal-notices`} />
      </Helmet>
      <div className="page-legal-notices-content">
        <h1 className='page-legal-notices-title'>Mentions légales</h1>
        <p>Dernière mise à jour : 23/08/2024</p>
        <h2>1. Informations légales</h2>
        <p>Conformément aux dispositions des articles 6-III et 19 de la Loi n°2004-575 du 21 juin 2004 pour la Confiance dans l&apos;Économie Numérique (LCEN), nous informons les utilisateurs et visiteurs du site Anonym des informations suivantes :</p>
        <h3>Propriétaire du site :</h3>
        <ul>
          <li>Nom de la société : Anonym</li>
          <li>Forme juridique : Entrepreneur individuel</li>
          <li>Capital social : 100 000$</li>
          <li>Adresse du siège social : 18 rue professeur Joseph Nicolas</li>
          <li>Numéro d&apos;immatriculation au Registre du Commerce et des Sociétés (RCS) : 1092838</li>
          <li>Numéro de TVA intracommunautaire : 3920323</li>
        </ul>
        <h3>Directeur de la publication :</h3>
        <p>Bouhlel Lukas</p>
        <p>Email : dpo@anonym-tech.fr</p>
        <h2>2. Hébergement du site</h2>
        <h3>Hébergeur du site :</h3>
        <ul>
          <li>Nom de l&apos;hébergeur : OVHcloud</li>
          <li>Adresse de l&apos;hébergeur : 2, rue Kellermann, 59100 Roubaix</li>
          <li>Téléphone : 09 72 20 20 20</li>
          <li>Site web : https://www.ovhcloud.com/</li>
        </ul>
        <h2>3. Propriété intellectuelle</h2>
        <p>L&apos;ensemble du contenu présent sur le site Anonym, incluant, de façon non limitative, les graphismes, images, textes, vidéos, animations, sons, logos, gifs et icônes ainsi que leur mise en forme, sont la propriété exclusive de Anonym, à l&apos;exception des marques, logos ou contenus appartenant à d&apos;autres sociétés partenaires ou auteurs.</p>
        <p>Toute reproduction, distribution, modification, adaptation, retransmission ou publication, même partielle, de ces différents éléments est strictement interdite sans l&apos;accord exprès par écrit de Anonym. </p>
        <p>Cette représentation ou reproduction, par quelque procédé que ce soit, constitue une contrefaçon sanctionnée par les articles L.335-2 et suivants du Code de la propriété intellectuelle. Le non-respect de cette interdiction constitue une contrefaçon pouvant engager la responsabilité civile et pénale du contrefacteur.</p>
        <h2>4. Responsabilité</h2>
        <p>Le site Anonym s&apos;efforce de fournir une information aussi précise que possible. </p>
        <p>Toutefois, Anonym ne pourra être tenue responsable des omissions, des inexactitudes et des carences dans la mise à jour, qu&apos;elles soient de son fait ou du fait des tiers partenaires qui lui fournissent ces informations.</p>
        <p>L&apos;utilisateur est seul responsable de l&apos;utilisation qu&apos;il fait du contenu du site Anonym.</p>
        <p> Tout contenu téléchargé se fait aux risques et périls de l&apos;utilisateur et sous sa seule responsabilité.</p>
        <p>En conséquence, Anonym ne saurait être tenu responsable d&apos;un quelconque dommage subi par l&apos;ordinateur de l&apos;utilisateur ou d&apos;une quelconque perte de données consécutives au téléchargement.</p>
        <h2>5. Données personnelles</h2>
        <p>Les informations collectées sur ce site sont destinées à Anonym. </p>
        <p>Elles sont exploitées dans le cadre de la gestion des relations avec les clients, la connexion, et la gestion des commandes, ainsi que pour des fins commerciales, de communication ou de statistiques.</p>
        <p>Ces données sont conservées pour la durée nécessaire aux finalités pour lesquelles elles sont collectées et traitées de manière sécurisée.</p>
        <p>Les mots de passe sont hachés pour garantir la sécurité de vos informations sensibles.</p>
        <p>Conformément à la loi &quot;Informatique et Libertés&quot; du 6 janvier 1978 modifiée, vous bénéficiez d&apos;un droit d&apos;accès, de rectification et d&apos;opposition aux données vous concernant.</p>
        <p>Pour exercer ce droit, il vous suffit d&apos;envoyer un mail à l&apos;adresse suivante : dpo@anonym.fr.</p>
        <p>Nous vous informons que vos données ne sont pas partagées avec des tiers, sauf pour des raisons légales ou pour la sous-traitance dans le cadre de l&apos;exécution de nos services, et toujours sous réserve de la protection de ces données.</p>
        <h2>6. Liens hypertextes</h2>
        <p>Il est possible de créer un lien vers la page de présentation de ce site sans autorisation expresse de Anonym.</p>
        <p>Aucune autorisation ou demande d&apos;information préalable ne peut être exigée par le site à l&apos;égard d&apos;un site qui souhaite établir un lien vers le site de Anonym.</p>
        <p>Enfin, pour plus de détails sur la manière dont nous traitons vos données personnelles, nous vous invitons à consulter notre <a href="/privacy-policy">Politique de Confidentialité</a>.</p>
        <h2>7. Droit applicable</h2>
        <p>Les présentes conditions du site Anonym sont régies par les lois françaises et tout litige ou différend qui pourrait naître de l&apos;interprétation ou de l&apos;exécution de celles-ci sera de la compétence exclusive des tribunaux dont dépend le siège social de Anonym.</p>
      </div>
    </section>
  );
};

export default LegalNotices;
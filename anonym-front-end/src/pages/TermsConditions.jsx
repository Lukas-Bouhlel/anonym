import { Helmet } from 'react-helmet-async';

const TermsConditions = () => {

    /**
     * Composant représentant les Conditions Générales de Vente (CGV) et d'Utilisation (CGU).
     * Ce composant affiche les termes juridiques régissant l'utilisation du site Anonym.
     *
     * @component
     * @returns {React.ReactElement} - Le composant des conditions générales.
     */
    return (
        <section className='page-terms-conditions'>
            <Helmet>
                <title>Conditions Générales de Vente (CGV) et d&apos;Utilisation (CGU) - Anonym</title>
                <meta name="description" content="Conditions Générales de Vente (CGV) et d&apos;Utilisation (CGU)" />
                <link rel="canonical" href={`https://www.ano-nym.fr/terms-conditions`} />
            </Helmet>
            <div className="page-terms-conditions-content">
                <h1 className="page-terms-conditions-title">Conditions Générales de Vente (CGV) et d&apos;Utilisation (CGU)</h1>
                <p>Dernière mise à jour : 21/08/2024</p>
                <h2>1. Préambule</h2>
                <p>
                    Les présentes Conditions Générales de Vente (CGV) et d&apos;Utilisation (CGU) régissent les relations entre Anonym et toute personne physique ou morale (ci-après « le Client ») visitant ou effectuant un achat sur le site Anonym.
                </p>
                <h2>2. Acceptation des conditions</h2>
                <p>
                    L&apos;utilisation du site Anonym implique l&apos;acceptation pleine et entière des présentes CGV-CGU. Ces dernières sont accessibles à tout moment sur le site et peuvent être modifiées sans préavis. Le Client est donc invité à les consulter régulièrement.
                </p>
                <h2>3. Produits et services</h2>
                <p>
                    Anonym s&apos;efforce de présenter aussi précisément que possible les caractéristiques essentielles des produits et services proposés. Les descriptions, informations, et photographies sont fournies à titre indicatif et ne sauraient constituer un engagement contractuel.
                    Nous vendons des personnalisation de profils vertuel.
                </p>
                <h2>4. Prix</h2>
                <p>
                    Les prix des produits et services sont indiqués en euros, toutes taxes comprises (TTC). Anonym se réserve le droit de modifier ses prix à tout moment, mais les produits ou services seront facturés sur la base des tarifs en vigueur au moment de la validation de la commande par le Client.
                </p>
                <h2>5. Commande</h2>
                <p>
                    La commande est validée lorsque le Client a rempli le formulaire de commande en ligne et confirmé celle-ci après avoir vérifié les détails de sa commande.
                </p>
                <h2>6. Paiement</h2>
                <p>
                    Le paiement s&apos;effectue par les moyens proposés sur le site via Stripe. Le paiement est exigible immédiatement à la commande, y compris pour les produits en précommande. Le traitement de la commande commence à réception du paiement.
                </p>
                <h2>7. Droit de rétractation</h2>
                <p>
                    Conformément à la législation en vigueur, le Client dispose d&apos;un délai de 14 jours à compter de la réception du produit pour exercer son droit de rétractation sans avoir à fournir de justification ni à supporter de frais. Toutefois, une fois que l&apos;article a été ajouté à l&apos;inventaire de l&apos;utilisateur, ce droit de rétractation de 14 jours n&apos;est plus applicable.
                </p>
                <h2>8. Utilisation du site</h2>
                <p>
                    L&apos;utilisation du site Anonym est soumise aux présentes CGU. Le Client s&apos;engage à ne pas utiliser le site de manière frauduleuse, à ne pas accéder de manière non autorisée aux systèmes informatiques, et à ne pas diffuser de contenu illégal ou préjudiciable.
                </p>
                <h2>9. Propriété intellectuelle</h2>
                <p>
                    Tous les éléments du site Anonym sont protégés par des droits d&apos;auteur. Toute reproduction totale ou partielle du site est strictement interdite sans accord préalable de Anonym.
                </p>
                <h2>10. Données personnelles</h2>
                <p>
                    Anonym s&apos;engage à protéger les données personnelles du Client conformément à sa <a href="/privacy-policy">Politique de Confidentialité</a>. Les informations collectées sont nécessaires à la gestion des commandes et à l&apos;amélioration des services proposés.
                </p>
                <h2>11. Service client</h2>
                <p>
                    Pour toute question ou réclamation, le Client peut contacter le service client de Anonym à l&apos;adresse e-mail suivante : service.client@anonym.fr, ou par téléphone au 0192833921.
                </p>
                <h2>12. Droit applicable et juridiction compétente</h2>
                <p>
                    Les présentes CGV-CGU sont régies par le droit français. En cas de litige ou de réclamation, le Client s&apos;adressera en priorité à Anonym pour obtenir une solution amiable. À défaut, les tribunaux français seront seuls compétents.
                </p>
            </div>
        </section>
    );
};

export default TermsConditions;
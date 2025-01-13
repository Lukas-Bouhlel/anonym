import { useState } from "react";
import PropTypes from "prop-types";
import axios from "axios";
import { Modal, Button } from "rsuite";
import { useApi } from "../../context/ApiContext";
import { usePopup } from "../../context/PopupContext";

/**
 * Composant Shop qui gère l'affichage, la création, la modification et la suppression
 * d'articles dans un magasin pour les admins.
 *
 * @component
 * @param {Object} shop - Les données du magasin.
 * @param {Function} refetch - Fonction pour rafraîchir les données après une modification.
 * @example
 * const shopData = {
 *   data: [
 *     { article_id: 1, title: "Article 1", amount: 100, type: "CADRE", createdAt: "2024-01-01", updatedAt: "2024-01-01", content: "image_url" }
 *   ]
 * };
 * <Shop shop={shopData} refetch={fetchShopData} />
 */
const Shop = ({ shop, refetch }) => {
  const data = shop.data || []; 
  const { api_url } = useApi();// Utilise le contexte pour obtenir l'URL de l'API
  const [selectedArticle, setSelectedArticle] = useState({});
  const [open, setOpen] = useState(false);
  const [createOpen, setCreateOpen] = useState(false);
  const [errorMessage, setErrorMessage] = useState("");
  const [showDeleteConfirmation, setShowDeleteConfirmation] = useState(false);
  const { setOpenPopup, setTextPopup, setState } = usePopup();
  const [newArticle, setNewArticle] = useState({
    title: "",
    amount: "",
    type: "CADRE",
    image: null, // Ajout de l'image pour la création
  });
  const [selectedImage, setSelectedImage] = useState(null); // Pour les images modifiées

  /**
   * Gère le changement d'image lors de l'édition ou de la création d'un article.
   * @param {Event} e - L'événement de changement d'image.
   */
  const handleImageChange = (e) => {
    const file = e.target.files[0];
    if (open) {
      // Pour la modification
      setSelectedImage(file);
    } else {
      // Pour la création
      setNewArticle({
        ...newArticle,
        image: file,
      });
    }
  };

  /**
   * Ouvre le modal pour éditer un article sélectionné.
   * @param {Object} article - L'article à éditer.
   */
  const handleOpen = (article) => {
    setSelectedArticle(article);
    setOpen(true);
  };

  /**
   * Ferme le modal d'édition ou de création et réinitialise les champs.
   */
  const handleClose = () => {
    setSelectedArticle({});
    setOpen(false);
    setShowDeleteConfirmation(false);
    setErrorMessage("");
    setNewArticle({ title: "", amount: "", type: "CADRE", image: null }); // Réinitialise pour la création
    setSelectedImage(null); // Réinitialise l'image sélectionnée
  };

  /**
   * Soumet l'édition d'un article.
   * @param {Event} e - L'événement de soumission du formulaire.
   * @returns {Promise<void>} - Retourne une promesse.
   */
  const handleSubmit = async (e) => {
    e.preventDefault();
    const formData = new FormData();
    formData.append(
      "datas",
      JSON.stringify({
        title: selectedArticle.title,
        amount: selectedArticle.amount,
        type: selectedArticle.type,
      })
    );

    if (selectedImage) {
      formData.append("image", selectedImage);
    }

    // Appel api pour modifier un article
    try {
        await axios.put(`${api_url}/api/shop/admin/${selectedArticle.article_id}`, formData, {
          withCredentials: true,
          headers: {
            "Content-Type": "multipart/form-data",
          },
        }
      );
      setOpenPopup(true);
      setTextPopup("L'article à bien été modifier");
      setState("update");
      handleClose();
      refetch();
    } catch (error) {
      setErrorMessage(
        error.response?.data?.message || "Une erreur est survenue."
      );
    }
  };

  /**
   * Crée un nouvel article via une requête API.
   * @param {Event} e - L'événement de soumission du formulaire.
   * @returns {Promise<void>} - Retourne une promesse.
   */
  const handleCreateArticle = async (e) => {
    e.preventDefault();
    const formData = new FormData();
    formData.append(
      "datas",
      JSON.stringify({
        title: newArticle.title,
        amount: newArticle.amount,
        type: newArticle.type,
      })
    );

    formData.append("image", newArticle.image);

    try {
      await axios.post(`${api_url}/api/shop/admin`, formData, {
        withCredentials: true,
        headers: {
          "Content-Type": "multipart/form-data",
        },
      });
      setOpenPopup(true);
      setTextPopup("L'article à bien été créer");
      setState("success");
      setCreateOpen(false);
      handleClose();
      refetch();
    } catch (error) {
      setErrorMessage(
        error.response?.data?.message ||
          "Une erreur est survenue lors de la création."
      );
    }
  };

  /**
   * Gère le changement des champs d'édition et de création d'article.
   * @param {Event} e - L'événement de changement de champ.
   */
  const handleChange = (e) => {
    const { name, value } = e.target;
    if (createOpen) {
      setNewArticle({
        ...newArticle,
        [name]: value,
      });
    } else {
      setSelectedArticle({
        ...selectedArticle,
        [name]: value,
      });
    }
  };

  /**
   * Supprime un article via une requête API.
   * @returns {Promise<void>} - Retourne une promesse.
   */
  const handleDeleteArticle = async () => {
    try {
      await axios.delete(
        `${api_url}/api/shop/admin/${selectedArticle.article_id}`,
        {
          withCredentials: true,
        }
      );
      setOpenPopup(true);
      setTextPopup("L'article à bien été supprimer");
      setState("success");
      handleClose();
      refetch();
    } catch (error) {
      setErrorMessage(
        error.response?.data?.message ||
          "Une erreur est survenue lors de la suppression."
      );
    }
  };

  return (
    <div className="content-admin-container-item">
      <div className="content-admin-container-item-head">
        <h1>Articles</h1>
        <Button onClick={() => setCreateOpen(true)} className="mb-3">
          Créer un article
        </Button>
      </div>
      {data.length > 0 ? (
        <div className="table-responsive-scroll">
          <table className="table align-middle mb-0 bg-white">
            <thead className="bg-light">
              <tr>
                <th>id</th>
                <th>contenu</th>
                <th>titre</th>
                <th>Montant</th>
                <th>createdAt</th>
                <th>updatedAt</th>
                <th>type</th>
                <th>Actions</th>
              </tr>
            </thead>
            <tbody>
              {data.map((article, index) => (
                <tr key={index}>
                  <td>{article.article_id}</td>
                  <td>
                    <div className="d-flex align-items-center">
                      <img
                        src={article.content}
                        alt=""
                        className="rounded-circle"
                        style={{ width: "50px", height: "50px" }}
                      />
                    </div>
                  </td>
                  <td>{article.title}</td>
                  <td>{article.amount}</td>
                  <td>{new Date(article.createdAt).toLocaleDateString()}</td>
                  <td>{new Date(article.updatedAt).toLocaleDateString()}</td>
                  <td>{article.type}</td>
                  <td>
                    <button
                      onClick={() => handleOpen(article)}
                      type="button"
                      className="btn btn-link btn-sm btn-rounded"
                    >
                      Edit
                    </button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      ) : (
        <p>Chargement...</p>
      )}
      {/* Modal pour éditer l'article */}
      <Modal open={open} onClose={handleClose}>
        <Modal.Header>
          <Modal.Title>Editer l&apos;article</Modal.Title>
        </Modal.Header>
        <Modal.Body>
          {errorMessage && (
            <div className="error-message" style={{ color: "red" }}>
              {errorMessage}
            </div>
          )}
          <form onSubmit={handleSubmit}>
            <div className="mb-3">
              <label htmlFor="title" className="form-label">
                Nom de l&apos;article
              </label>
              <input
                aria-required="true"
                aria-label="Nom de l'article"
                type="text"
                className="form-control"
                id="title"
                name="title"
                value={selectedArticle.title || ""}
                onChange={handleChange}
              />
            </div>
            <div className="mb-3">
              <label htmlFor="amount" className="form-label">
                Montant
              </label>
              <input
                aria-required="true"
                aria-label="Montant"
                type="number"
                className="form-control"
                id="amount"
                name="amount"
                value={selectedArticle.amount || ""}
                onChange={handleChange}
              />
            </div>
            <div className="mb-3">
              <label htmlFor="type" className="form-label">
                Type
              </label>
              <select
                aria-label="Type"
                className="form-select"
                id="type"
                name="type"
                value={selectedArticle.type || "CADRE"}
                onChange={handleChange}
              >
                <option value="CADRE">CADRE</option>
                <option value="SUBSCRIPTION">SUBSCRIPTION</option>
                <option value="COLOR">COLOR</option>
              </select>
            </div>
            <div className="mb-3">
              <label htmlFor="image" className="form-label">
                Télécharger une image
              </label>
              <input
                aria-label="Télécharger une image"
                type="file"
                className="form-control"
                id="image"
                name="image"
                accept="image/*"
                onChange={handleImageChange}
              />
            </div>
            <Modal.Footer>
              <Button onClick={handleClose} appearance="subtle">
                Annuler
              </Button>
              <Button type="submit" className="btn btn-primary">
                Enregistrer
              </Button>
              <Button
                color="red"
                appearance="subtle"
                onClick={() => setShowDeleteConfirmation(true)}
              >
                Supprimer l&apos;article
              </Button>
            </Modal.Footer>
          </form>
        </Modal.Body>
      </Modal>

      {/* Modal de création d'article */}
      <Modal open={createOpen} onClose={() => setCreateOpen(false)}>
        <Modal.Header>
          <Modal.Title>Créer un nouvel article</Modal.Title>
        </Modal.Header>
        <Modal.Body>
          {errorMessage && (
            <div className="error-message" style={{ color: "red" }}>
              {errorMessage}
            </div>
          )}
          <form onSubmit={handleCreateArticle}>
            <div className="mb-3">
              <label htmlFor="title" className="form-label">
                Nom de l&apos;article
              </label>
              <input
                type="text"
                className="form-control"
                id="title"
                name="title"
                value={newArticle.title}
                onChange={handleChange}
                required
              />
            </div>
            <div className="mb-3">
              <label htmlFor="amount" className="form-label">
                Montant
              </label>
              <input
                type="number"
                className="form-control"
                id="amount"
                name="amount"
                value={newArticle.amount}
                onChange={handleChange}
                required
              />
            </div>
            <div className="mb-3">
              <label htmlFor="type" className="form-label">
                Type
              </label>
              <select
                className="form-select"
                id="type"
                name="type"
                value={newArticle.type}
                onChange={handleChange}
              >
                <option value="CADRE">CADRE</option>
                <option value="SUBSCRIPTION">SUBSCRIPTION</option>
                <option value="COLOR">COLOR</option>
              </select>
            </div>
            <div className="mb-3">
              <label htmlFor="image" className="form-label">
                Télécharger une image
              </label>
              <input
                type="file"
                className="form-control"
                id="image"
                name="image"
                accept="image/*"
                onChange={handleImageChange}
              />
            </div>
            <Modal.Footer>
              <Button onClick={() => setCreateOpen(false)} appearance="subtle">
                Annuler
              </Button>
              <Button type="submit" className="btn btn-primary">
                Créer
              </Button>
            </Modal.Footer>
          </form>
        </Modal.Body>
      </Modal>

      {/* Modal de confirmation de suppression */}
      {showDeleteConfirmation && (
        <Modal
          open={showDeleteConfirmation}
          onClose={() => setShowDeleteConfirmation(false)}
        >
          <Modal.Header>
            <Modal.Title>Confirmation de Suppression</Modal.Title>
          </Modal.Header>
          <Modal.Body>
            Êtes-vous sûr de vouloir supprimer cet article ? Cette action est
            irréversible.
          </Modal.Body>
          <Modal.Footer>
            <Button
              onClick={() => setShowDeleteConfirmation(false)}
              appearance="subtle"
            >
              Annuler
            </Button>
            <Button
              color="red"
              appearance="subtle"
              onClick={handleDeleteArticle}
            >
              Supprimer
            </Button>
          </Modal.Footer>
        </Modal>
      )}
    </div>
  );
};

Shop.propTypes = {
  shop: PropTypes.shape({
    data: PropTypes.array, // Expecting data to be an array
  }).isRequired, // shop is required
  refetch: PropTypes.func.isRequired, // refetch is required and should be a function
};

export default Shop;

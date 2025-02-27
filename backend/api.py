from flask import Flask, request, jsonify
from flask_cors import CORS
import csv
import json

app = Flask(__name__)
CORS(app)

CSV_FILE = "data/Legumes_par_mois.csv"
notifications = []

class BasketInfos:
    def __init__(self, mois_souhaite):
        self.csv_file = CSV_FILE
        self.mois_souhaite = mois_souhaite
        self.prix_petit_panier = 10
        self.prix_moyen_panier = 15
        self.prix_grand_panier = 20
        self.data_pour_mois = []
        self.petit_panier = []
        self.moyen_panier = []
        self.grand_panier = []
        self.prix_petit_panier_tot = 0
        self.prix_moyen_panier_tot = 0
        self.prix_grand_panier_tot = 0
        self.nb_petit_panier_pour_mois = 0
        self.nb_moyen_panier_pour_mois = 0
        self.nb_grand_panier_pour_mois = 0

    def set_data_from_csv(self):
        try:
            with open(self.csv_file, mode='r', encoding='utf-8') as file:
                reader = csv.reader(file)
                headers = next(reader)
                mois_headers = headers[3:]  # Extraction des mois
                if self.mois_souhaite not in mois_headers:
                    raise ValueError(f"Le mois spécifié ({self.mois_souhaite}) n'existe pas dans le fichier CSV.")
                index_mois = mois_headers.index(self.mois_souhaite)
                for row in reader:
                    try:
                        quantite = float(row[0].replace(',', '.'))
                        prix = float(row[1].replace(',', '.'))
                        legume = row[2]
                        disponibilites = row[3:]
                        if disponibilites[index_mois]:
                            self.data_pour_mois.append({
                                'Legume': legume,
                                'Quantite': quantite,
                                'Prix': prix,
                            })
                    except ValueError:
                        print(f"Erreur de conversion pour la ligne : {row}")
        except FileNotFoundError:
            raise FileNotFoundError(f"Fichier CSV introuvable : {self.csv_file}")

    def calculate_infos(self):
        for legume_info in self.data_pour_mois:
            quantite_tot = legume_info['Quantite']
            prix_marge = round(legume_info['Prix'] * 1.2, 2)
            self.prix_petit_panier_tot += round(quantite_tot * 0.2 * prix_marge, 2)
            self.prix_moyen_panier_tot += round(quantite_tot * 0.35 * prix_marge, 2)
            self.prix_grand_panier_tot += round(quantite_tot * 0.45 * prix_marge, 2)

    def set_basket_number(self):
        self.nb_petit_panier_pour_mois = round(self.prix_petit_panier_tot / self.prix_petit_panier, 0)
        self.nb_moyen_panier_pour_mois = round(self.prix_moyen_panier_tot / self.prix_moyen_panier, 0)
        self.nb_grand_panier_pour_mois = round(self.prix_grand_panier_tot / self.prix_grand_panier, 0)

    def basket_distribution(self):
        for legume_info in self.data_pour_mois:
            legume = legume_info['Legume']
            quantite_tot = legume_info['Quantite']
            prix_marge = round(legume_info['Prix'] * 1.2, 2)
            self.petit_panier.append({
                'Legume': legume,
                'Quantite': round(quantite_tot * 0.2 / max(1, self.nb_petit_panier_pour_mois), 2),
                'Prix': prix_marge
            })
            self.moyen_panier.append({
                'Legume': legume,
                'Quantite': round(quantite_tot * 0.35 / max(1, self.nb_moyen_panier_pour_mois), 2),
                'Prix': prix_marge
            })
            self.grand_panier.append({
                'Legume': legume,
                'Quantite': round(quantite_tot * 0.45 / max(1, self.nb_grand_panier_pour_mois), 2),
                'Prix': prix_marge
            })

    def init(self):
        self.set_data_from_csv()
        self.calculate_infos()
        self.set_basket_number()
        self.basket_distribution()

@app.route('/', methods=['GET'])
def home():
    return "Bienvenue sur l'api des paniers !"

@app.route('/basket', methods=['GET'])
def get_basket_via_get():
    try:
        mois = request.args.get('mois')
        if not mois:
            return json.dumps({"error": "Paramètres requis manquants. basket?mois=..."}, ensure_ascii=False), 400
        basket = BasketInfos(mois)
        basket.init()
        if not basket.data_pour_mois:
            return json.dumps({"error": f"Aucun légume disponible pour {mois}."}, ensure_ascii=False), 404
        response = {
            'moisSouhaite': mois,
            'prixPetitPanierTot': basket.prix_petit_panier_tot,
            'prixMoyenPanierTot': basket.prix_moyen_panier_tot,
            'prixGrandPanierTot': basket.prix_grand_panier_tot,
            'nombrePetitPanier': basket.nb_petit_panier_pour_mois,
            'nombreMoyenPanier': basket.nb_moyen_panier_pour_mois,
            'nombreGrandPanier': basket.nb_grand_panier_pour_mois,
            'petitPanier': basket.petit_panier,
            'moyenPanier': basket.moyen_panier,
            'grandPanier': basket.grand_panier
        }
        return app.response_class(
            response=json.dumps(response, ensure_ascii=False, indent=2, sort_keys=False),
            status=200,
            mimetype='application/json'
        )
    except FileNotFoundError as e:
        return json.dumps({"error": str(e)}, ensure_ascii=False), 500
    except ValueError as e:
        return json.dumps({"error": str(e)}, ensure_ascii=False), 400

@app.route('/notify_delivery', methods=['POST'])
def notify_delivery():
    try:
        data = request.get_json()
        if not data or 'delivery' not in data or 'status' not in data:
            return jsonify({"error": "Paramètres manquants"}), 400
        notifications.append(data)
        return jsonify({"message": "Notification enregistrée"}), 201
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route('/notifications', methods=['GET'])
def get_notifications():
    return jsonify(notifications), 200

if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0', port=5000)

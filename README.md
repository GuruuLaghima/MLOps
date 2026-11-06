
## **Présentation du projet**

Ce projet a pour objectif de déployer une chaîne complète **MLOps** en intégrant les pratiques **DevOps** pour le déploiement et le suivi d'un modèle de Machine Learning. L'architecture repose sur des outils modernes permettant l'automatisation, la versioning et le monitoring des modèles ML. Voici les principaux composants du projet :

1. **Infrastructure as Code (IaC)** avec **Terraform** pour provisionner les ressources cloud (AWS EC2).
2. **Configuration automatisée** des serveurs avec **Ansible** pour l'installation des outils nécessaires (Docker, Grafana, Prometheus).
3. **Containerisation** de l'application ML avec **Docker** pour garantir un déploiement portable et reproductible.
4. **CI/CD** avec **GitHub Actions** pour automatiser les tests, la construction des images Docker et le déploiement sur EC2.
5. **Monitoring** avec **Prometheus** pour la collecte des métriques et **Grafana** pour la visualisation.

L'application propose une **API Flask** qui permet d'effectuer des prédictions via un modèle de Machine Learning entraîné avec **XGBoost**.

---


## **1. Infrastructure**

### **1.1. Préparation de la clé `.pem` pour SSH**

Avant toute chose, une clé SSH est nécessaire pour se connecter à l'instance EC2. Voici comment la créer :

1. **Générer une paire de clés avec `ssh-keygen`** :
   ```bash
   ssh-keygen -t rsa -b 4096 -f ~/.ssh/myKey.pem
   ```

2. **Rendre la clé privée utilisable** :
   ```bash
   chmod 400 ~/.ssh/myKey.pem
   ```

3. **Ajouter la clé dans Terraform** :
   - Lors de la configuration de Terraform, spécifie la clé publique dans les paramètres EC2.

4. **Connexion SSH à l'instance** (plus tard) :
   ```bash
   ssh -i ~/.ssh/myKey.pem ec2-user@<PUBLIC_IP>
   ```
   Remplacez `<PUBLIC_IP>` par l’adresse IPv4 publique de l'instance.

---

### **1.2. Explication des outils : Terraform & Ansible**

- **Terraform** : Utilisé pour **provisionner l'infrastructure** ( instances EC2 sur AWS).  
   *Il permet de décrire l'infrastructure comme du code (IaC), facilitant la reproductibilité et l'automatisation.*  

- **Ansible** : Une fois l'infrastructure déployée, Ansible est utilisé pour **configurer les serveurs** (installer Docker, Grafana, Prometheus, etc.).  
   *Il exécute des "playbooks" contenant des tâches automatisées.*

---

### **1.3. Mise en place de l'infrastructure cloud via Terraform**

1. **Initialise Terraform** dans le répertoire `terraform` :
   ```bash
   cd terraform
   terraform init
   ```

2. **Planifie les modifications** :
   ```bash
   terraform plan
   ```

3. **Déploie l'infrastructure** :
   ```bash
   terraform apply
   ```
   - Confirme avec `yes`.

4. **Récupère l'IP de l'instance (Public IPv4 address)** :
   ```bash
   terraform output
   ```
	Egalement nous pouvons la retrouver sur la console AWS :
![image](https://github.com/user-attachments/assets/9dc34c97-0d89-4590-9a33-fedda8261297)

---

### **1.4. Configuration des serveurs via Ansible**

1. **Configure le fichier `hosts.ini`** dans `ansible/` :
   ```ini
   [docker_host]
   <PUBLIC_IP> ansible_user=ec2-user ansible_ssh_private_key_file=~/.ssh/myKey.pem
   ```

2. **Exécute le playbook Ansible pour installer Docker** :
   ```bash
   cd ansible
   ansible-playbook -i hosts.ini playbooks/setup_docker.yml
   ```

3. **Vérifie l'installation de Docker** :
   ```bash
   ssh -i ~/.ssh/myKey.pem ec2-user@<instance_ip>
   docker --version
   ```

---

### **1.5. Architecture containerisée avec Docker**

1. **Lancement des services Docker** :  
   Le fichier `docker-compose.yml` configure les services :
   - **Prometheus** (Service de collecte des métriques via `monitoring/prometheus/prometheus.yml`.)
   - **Grafana** (Plateforme de visualisation des métriques.)
   - **API ML** (API pour effectuer des prédictions à partir d'un modèle XGBoost.)

   Exécutez :
   ```bash
   cd docker
   docker-compose up -d
   ```


---

### **1.6. Test des services (post-déploiement)**

Pour vérifier que tout fonctionne correctement **après le déploiement de l'API** :

- **Tester l'API depuis l'instance** :

	Pull l'image Docker :
	```bash
	docker pull wiltch/xgboost-ml-api:latest
	```
	Run le container :
	```bash
	docker run -d -p 5001:5001 wiltch/xgboost-ml-api:latest
	```
	
   ```bash
   curl -X POST -H "Content-Type: application/json" \
   -d '{"features": [[8.3252, 41, 6.9841, 1.023810, 322, 2.5556, 37.88, -122.23]]}' \
   http://127.0.0.1:5001/predict
   ```

- **Tester l'API depuis le poste local** (HTTPS avec IP publique) :
   ```bash
   curl -k -X POST -H "Content-Type: application/json" \
   -d '{"features": [[8.3252, 41, 6.9841, 1.023810, 322, 2.5556, 37.88, -122.23]]}' \
   https://<instance_ip>/predict
   ```

- **Accéder aux interfaces Prometheus et Grafana** :
   - **Prometheus** : `http://<PUBLIC_IP>:9090`
   - **Grafana** : `http://<PUBLIC_IP>:3000`
   - Identifiants : `admin` / `admin`

---



### **2. Application ML**

Mise en place d'une **API ML** basée sur un modèle XGBoost et d'assurer le **versioning des modèles** avec **MLflow**. 

---

### **2.1 Entraînement du modèle avec MLflow**

1. **Description** :
   - Le modèle **XGBoost** est entraîné à partir d'un jeu de données pour effectuer des prédictions.
   - **MLflow** est utilisé pour le **suivi des expériences** et la **version des modèles**.

2. **Structure du projet** :
   Le code source de cette partie se trouve dans le dossier `ml/model/`.

   - `train_model.py` : Script d'entraînement du modèle.
   - `model.pkl` : Modèle entraîné, sauvegardé au format `.pkl` pour l'API.

3. **Exécution du script d'entraînement** :

   ```bash
   cd ml/model
   python train_model.py
   ```

   - Ce script :
     - Entraîne le modèle XGBoost.
     - Log les métriques (comme la RMSE) et sauvegarde le modèle avec MLflow.
   - Une fois terminé, un dossier `mlruns` est créé pour stocker les artefacts et les versions du modèle.

4. **Démarrage de l'interface MLflow** :

   Depuis le dossier `ml`, lancez MLflow pour voir les résultats et les modèles :

   ```bash
   mlflow ui
   ```
   <img width="732" alt="image" src="https://github.com/user-attachments/assets/bc8245c9-a6e0-4ca2-9d7d-72ac5dd90fe8" />


   Accédez à l'interface sur `http://127.0.0.1:5000` pour voir :
   - Les **expériences** enregistrées.
   - Les **modèles sauvegardés**.
   - Les métriques comme la RMSE.
<img width="1172" alt="image" src="https://github.com/user-attachments/assets/ff4333da-d5c0-475b-9ade-460fff4be988" />

---

### **2.2 Déploiement de l'API ML**

1. **Description** :
   - Une **API Flask** est créée pour servir le modèle ML.
   - L'API prend en entrée des **features** JSON et renvoie les **prédictions**.

2. **Structure du projet** :
   - **Code source** : `ml/api/app.py`
   - **Dépendances** : `ml/api/requirements.txt`
   - **Dockerfile** : Permet de containeriser l'API.

3. **Test de l'API en local** :

   Depuis le dossier `ml/api`, testez l'API :

   ```bash
   cd ml/api
   python app.py
   ```

   **Test des prédictions** avec `curl` :

   ```bash
   curl -X POST -H "Content-Type: application/json" \
   -d '{"features": [[8.3252, 41, 6.9841, 1.023810, 322, 2.5556, 37.88, -122.23]]}' \
   http://127.0.0.1:5001/predict
   ```

---


### **2.3 Versioning avec MLflow**

Une fois le modèle déployé et l'API fonctionnelle :

1. **Vérifiez les versions du modèle** :
   - Rendez-vous dans l'interface **MLflow UI** (`http://127.0.0.1:5000`) pour voir :
     - Les versions des modèles.
     - Les artefacts sauvegardés.
     - Les métriques d'entraînement.



---



### **4. Monitoring avec Prometheus et Grafana**

---

### **4.1. Objectif du monitoring**

Le monitoring permet de suivre les **performances de l'infrastructure** et de l'API ML :  
- **Prometheus** collecte et stocke les métriques.  
- **Grafana** permet de **visualiser les métriques** via des tableaux de bord interactifs.

---

### **4.2. Copie des fichiers de configuration dans l'instance**

1. **Copiez les fichiers de monitoring sur l'instance EC2** :
   Depuis votre poste local, exécutez :
   ```bash
   rsync -av --exclude=".DS_Store" -e "ssh -i ~/.ssh/myKey.pem" monitoring ec2-user@<PUBLIC_IP>:/home/ec2-user/
   ```

2. **Structure des dossiers après la copie** :
   - `/home/ec2-user/monitoring/prometheus/prometheus.yml`
   - `/home/ec2-user/monitoring/grafana/{datasources.yml}`

3. **Assurez-vous que les permissions sont correctes pour Grafana** :
   ```bash
   sudo chown -R 472:472 /home/ec2-user/monitoring/grafana
   ```

---

### **4.3. Configuration de Prometheus**

1. **Fichier `prometheus.yml`**  
   Le fichier de configuration se trouve dans `monitoring/prometheus/prometheus.yml` :
   ```yaml
   global:
     scrape_interval: 15s

   scrape_configs:
     - job_name: 'xgboost-api'
       static_configs:
         - targets: ['xgboost-api:5001']
   ```

   - **`scrape_interval`** : Intervalle pour collecter les métriques.  
   - **`targets`** : URL de l'API exposant les métriques via `/metrics`.

---

### **4.4. Configuration de Grafana**

1. **Volume pour persister les données Grafana** :  
   Le fichier `docker-compose.yml` dans `docker/` monte un volume pour sauvegarder les données :
   ```yaml
   grafana:
     image: grafana/grafana
     container_name: grafana
     ports:
       - "3000:3000"
     restart: always
     environment:
       - GF_SECURITY_ADMIN_USER=admin
       - GF_SECURITY_ADMIN_PASSWORD=admin
     volumes:
       - ../monitoring/grafana:/var/lib/grafana
   ```

2. **Configuration de la source de données** :
   - Le fichier `datasources.yml` est copié dans `monitoring/grafana/` :
   ```yaml
   apiVersion: 1
   datasources:
     - name: Prometheus
       type: prometheus
       access: proxy
       url: http://prometheus:9090
       isDefault: true
   ```

---

### **4.5. Démarrage des services de monitoring**

1. **Assurez-vous d'être dans le répertoire Docker** :
   ```bash
   cd docker
   ```

2. **Relancez Docker Compose** pour déployer Prometheus et Grafana :
   ```bash
   docker-compose down
   docker-compose up -d
   ```

3. **Vérifiez l'état des conteneurs** :
   ```bash
   docker ps
   ```

   Vous devriez voir les conteneurs suivants en cours d'exécution :
   - **prometheus** (port `9090`)
   - **grafana** (port `3000`)
   - **xgboost-api** (port `5001`)

---

### **4.6. Configuration de Grafana**

1. **Accédez à Grafana** :  
   URL : `http://<PUBLIC_IP>:3000`  
   Identifiants par défaut :  
   - **Utilisateur** : `admin`  
   - **Mot de passe** : `admin`

2. **Ajout de Prometheus comme source de données** :
   - Allez dans **Configuration > Data Sources > Add data source**.
   - Choisissez **Prometheus**.
   - Configurez l'URL suivante :  
     ```
     http://prometheus:9090
     ```
   - Cliquez sur **Save & Test** pour valider.

---

### **4.7. Visualisation des métriques dans Grafana**

1. **Importation d’un tableau de bord existant** :
   - Allez dans **Dashboards > Import**.
   - Utilisez un tableau de bord prédéfini depuis [Grafana Dashboards](https://grafana.com/grafana/dashboards/).  
   - Exemple : **ID 1860** (Node Exporter Full).
  
     <img width="610" alt="image" src="https://github.com/user-attachments/assets/6a3af744-f4e8-4855-a080-1dfbc27591c6" />


2. **Création de graphiques personnalisés** :
   - Accédez à **Dashboards > New Panel**.
   - Utilisez des requêtes PromQL pour afficher les métriques :  
     - **Nombre total de requêtes de prédiction** :  
       ```promql
       prediction_requests_total
       ```  
     - **Nombre d'erreurs de prédiction** :  
       ```promql
       prediction_errors_total
       ```  
     - **Métriques liées au garbage collector Python** :  
       ```promql
       python_gc_collections_total
       ```

---

### **4.8. Vérification finale**

1. **Prometheus** :
   - Allez sur :  
     ```
     http://<PUBLIC_IP>:9090
     ```
   - Vérifiez que le job **`xgboost-api`** apparaît dans **Status > Targets**.  
<img width="1435" alt="image" src="https://github.com/user-attachments/assets/458a93ec-2725-4ade-8a1c-96fdf420a300" />


2. **Grafana** :
   - Vérifiez que les **tableaux de bord** affichent correctement les métriques collectées par Prometheus.

---



### ** Dépannage : Problèmes de ports **

Si l'accès à certains services est bloqué (par exemple, Grafana, Prometheus ou l'API) :

1. **Vérifiez les règles de sécurité** configurées dans Terraform pour les ports requis.  

   - Exemple pour ouvrir le port **5001** utilisé par l'API :

   ```hcl
   ingress {
     from_port   = 5001
     to_port     = 5001
     protocol    = "tcp"
     cidr_blocks = ["0.0.0.0/0"]
   }
   ```

2. **Modifiez les règles directement dans la console AWS** :  
   - Allez dans **EC2 > Security Groups**.  
   - Sélectionnez le groupe de sécurité attaché à votre instance.  
   - Ajoutez une règle pour autoriser le port spécifique (exemple : TCP/5001, source : `0.0.0.0/0`).

3. **Redéployez les modifications avec Terraform** pour appliquer les nouvelles règles :  
   ```bash
   cd terraform
   terraform apply
   ```

4. **Redémarrez les services concernés** si nécessaire :  
   ```bash
   docker-compose restart
   ```

5. **Testez l'accès aux services** :  
   - **API** : `https://<PUBLIC_IP>:5001/predict`  
   - **Grafana** : `http://<PUBLIC_IP>:3000`  
   - **Prometheus** : `http://<PUBLIC_IP>:9090`  

---

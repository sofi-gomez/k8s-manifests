# Paso a paso para reproducir el entorno
Requisitos previos:

-Docker

-Minikube

-kubectl

-Git

Comenzamos:
1. Clonamos los repositorios necesarios en los directorios correspondientes.
   
git clone https://github.com/sofi-gomez/k8s-manifests.git 

git clone https://github.com/sofi-gomez/static-website.git

2. Iniciamos minikube
   
minikube start --driver=docker

3. Montamos el contenido en Minikube en una terminal aparte y dejamos abierta durante todo el despliegue (muy importante). Utilizamos el comando:
   
minikube mount "<ruta-local-static-website>:/mnt/data"

Por ejemplo: minikube mount "C:\Users\pepito\Documentos\static-website:/mnt/data"

4. configuramos los manifestos en un editor.
5. Aplicamos los manifiestos desde el directorio k8s-manifests:
   
kubectl apply -f volumes\web-pv.yaml 

kubectl apply -f volumes\web-pvc.yaml 

kubectl apply -f deployments\web-deployment.yaml 

kubectl apply -f services\web-service.yaml


7. Por último, acceder a la aplicacion con el comando:
   
minikube service static-website-service

Esto abre el navegador directamente con la URL local donde está corriendo el sitio.

